# Docker server deployment

The deployment runs every server process in its own container. The login, mail, and scene roles share a game-server base image; the scene master adds its INI in a small derived image. PostgreSQL and Apache each use their own image and container.

This deployment targets one Docker host. Scene workers scale across containers on that host. Multi-host scheduling is not included.

## Topology

```text
web (Apache + mod_cgid)
postgres
login-master
login-worker
mail-master
mail-worker
scene-master
scene-manager
scene-worker-1 ... scene-worker-N
```

Containers use Docker service names for private traffic. Native clients use the configured public host and published ports. PostgreSQL is never published.

Server compilation reuses the repository's existing named Docker volumes (`hazeron-linux-<config>-cache`). The build exports `build/linux-<config>/bin` and `lib`; the deployment then packages those artifacts into the runtime image. There is no second CMake cache inside the image build.

The `server-deployment` build target compiles the game servers and the five web
tools (including `AuEmpireReport`) together. Deployment containers use no bind mounts: executables, web files,
and INI configuration are copied into images. Only database data and generated
reports use named Docker volumes. The release archive includes every local input
needed to assemble those images, with paths relative to the extracted archive.

The image build uses a unique temporary context under `build/server/` and removes it when the script exits, including on failure. Set `HAZERON_KEEP_STAGING=1` to retain the context for inspection; its path is printed when the script exits.

## Local development

Start one Debug scene worker:

```bash
make server-up
```

Common commands:

```bash
make server-status
make server-logs
make server-logs SERVICE=scene-worker-1
make server-down
```

`server-down` preserves the PostgreSQL and web report volumes. Delete and recreate the local universe and web reports only when intended:

```bash
make server-reset
# Non-interactive: make server-reset CONFIRM=yes
```

Scale the scene-worker pool:

```bash
make server-up SCENE_WORKERS=3
```

Local defaults are in `environments/local.env.example`. Copy it to the ignored `environments/local.env` only when overrides are needed:

```bash
cp deploy/server/environments/local.env.example \
   deploy/server/environments/local.env
```

The local database creates this development account:

```text
account:  local
password: local
```

Change the credentials in `local.env` before the first initialization, or run `make server-reset` after changing them.

### Apache web service

The `web` service installs Apache 2 with the `event` MPM and `mod_cgid` in a
separate Ubuntu image. Its PHP homepage executes `AuServerStatus` with `-l`,
`-m`, and `-g` on each page load and embeds the resulting HTML fragments.
The scene status uses the management channel, which recognizes the database states.
The tool connects to the masters by service name on the private Docker network.
Apache runs PHP through `mod_actions` and `mod_cgid`, keeping the `event` MPM;
`AuServerStatus` remains a command-line program. `/register` serves the static
`register.html` form, which submits to `/cgi-bin/AuAcctNew`. The CGI handler
creates an account through the deployment's `login-worker` and returns its
existing success or error page. Apache passes `AU_LOGIN_SERVER`,
`AU_ACCOUNT_REGISTRATION=1`, and `AU_WEBMASTER_PASSWORD` (from
`SERVER_LOGIN_PASSWORD`) to this handler. The password must match the Webmaster
account in the login database, as initialized by the PostgreSQL setup script.
Outside Docker, the tool also accepts `AU_LOGIN_PORT` (default 16757);
registration uses `AuAcctNew.ini` unless `AU_ACCOUNT_REGISTRATION` is supplied.

`/reset` currently displays an unavailable notice. `AuAcctSendPassword` is the
forgotten-password tool; `AuAcctPassword` changes a password using the current
password. The reset tool is deliberately not exposed yet: the login server
changes the password before invoking `mail`, and email delivery is not configured
in the server image.

`/emailchange` and `/passchange` serve static forms that POST to `AuAcctEmail`
and `AuAcctPassword`, respectively. Both verify the account's current password
against the deployment's `login-worker`; they do not need Webmaster credentials
or email delivery. The handlers return their existing result pages. The legacy
change protocol does not acknowledge database updates, so verify changes by
logging in with the new password or inspecting the account record.

To compile the web tools, rebuild the Apache image and start it without
rebuilding or restarting the game servers:

```bash
make server-web-up
make server-logs SERVICE=web
```

Open `http://localhost/`. `/index.html` redirects to the PHP homepage.
The page refreshes its results when reloaded; it does not poll in the background.
Each status command has a 12-second timeout, after which the page shows an error
for that service. Command failures also go to the Apache error log.

The Apache image copies `AuServerStatus`, `AuAcctNew`, `AuAcctEmail`,
`AuAcctPassword`, and `AuEmpireReport` from the `bin/` directory inside its own
build context, along with reporting libraries from `lib/`. After
compilation, `deploy/server/web/stage.sh` assembles the web files, executables, and libraries
into `build/server/web-context-<config>/` for development. The generated Compose
settings select that context. The web-up targets compile `web-tools` and stage
the context before rebuilding the image. The container has no executable mounts.

The normal `make server-up` compiles and packages both the servers and web tools.
For production, use `make server-prod-web-up` or the full `make server-prod-up`.
The production archive includes this complete context as `deploy/server/web/`,
with the five Release executables in `deploy/server/web/bin/` and their shared
libraries in `deploy/server/web/lib/`. Its Compose
settings use `WEB_BUILD_CONTEXT=./web`, relative to `deploy/server/compose.yaml`.
The archive needs no `build/` directory, source checkout, or C++ compiler.
Running `./start.sh` builds Apache from that packaged context alongside
PostgreSQL and the scene-master configuration image.

The avatar count links to `/playerson.php`, which runs `AuServerStatus -p` to
query the scene master for a fresh JSON list. PHP renders the avatar names and
AFK markers; failures display an unavailable message rather than an empty list.
`/playerson.html` redirects to this page. No player report file or history is
written, and the homepage no longer makes the additional player-list query.

`/galactic` displays recent public galactic chat and system broadcasts. It runs
`AuServerStatus -c`, which uses the existing scene-master management status query
and outputs the chat as JSON. PHP renders escaped message text, sender names,
galaxies, and UTC timestamps in chronological order. Reload the page to refresh.
`/galactic.html` redirects to this page; `/galactic.php` also works directly.
Failures display an unavailable message, separately from an empty chat result.

The scene master retains approximately five minutes of recent chat. This page
is read-only and does not archive older messages. Neither the chat query nor the
homepage writes the old `Galactic.msgs` or `galactic.html` report files. No extra
volume is required. The status output retains its legacy timezone labels;
the persistent reports volume is not yet connected to these pages.

`WEB_PORT` defaults to `80`. `WEB_BIND_ADDRESS` defaults to `127.0.0.1` locally
and `0.0.0.0` in production, independently of the game's `BIND_ADDRESS`.
For example, a host already running a reverse proxy can set:

```dotenv
WEB_BIND_ADDRESS=127.0.0.1
WEB_PORT=8080
```

Set these in the environment's `.env` file, then rerun its web-up target.
For simultaneous local and production stacks on the same host, assign distinct
web ports or bind addresses. Apache currently serves HTTP; a host reverse proxy
can provide HTTPS.

Docker checks health by requesting `/cgi-bin/health.cgi` from inside the
container and checking its response. This verifies CGI execution as well as
HTTP availability. The health endpoint accepts only container-local requests;
the homepage remains accessible through the published web port.

Apache configuration, static site files, and CGI executables live in the image.
Generated reports have their own named volume,
`${COMPOSE_PROJECT_NAME}-web-reports`, mounted at
`/var/lib/openshores/reports` and served under `/reports/`. Apache mounts it
read-only; the `empire-standings` and `avatar-reports` services mount the same
volume read-write, publishing into separate subdirectories.
New volumes are initialized with owner UID/GID `1000:1000`, matching the web
image's `openshores` user. Directory listings and script execution are disabled
for reports, and PHP/script files are denied. Standings-only output is static HTML;
the legacy combined report still needs adaptation before it can be published.

The web image includes `/opt/openshores/bin/AuEmpireReport` and the report
runners. The `empire-standings` container uses this same image with the report
scheduler as its entrypoint and user `1000:1000`; it does not start Apache. The
Apache container keeps its read-only report mount, while this container writes
to the existing named volume. Reporting executables are not packaged in the
game-server image.

The executable's `-standings`
option generates only empire standings on stdout and flag images in the current
working directory; `-report` retains the legacy combined standings, avatar pages,
and blueprint exchange output. Database connections use `AU_UNIVERSE_DB_HOST`
and `AU_LOGIN_DB_HOST` (both default to `postgres`), with user `audog` and
`AU_DB_PASSWORD` (default `Gold`), matching the game servers' deployment settings.
The legacy `-huey` and `-u0` flags override the universe database host when supplied.
The `empire-standings` service generates a report immediately after PostgreSQL
is healthy, then refreshes it periodically. Apache can start while reports are
being generated; on first deployment, report pages are available after the first
successful refresh. It publishes
`/reports/standings/index.html`, linked from the homepage as `/standings`.
Generation has a five-minute timeout and a lock to prevent overlapping refreshes;
the published page is replaced only after the generator succeeds and produces
nonempty output. The generator's existing layout is retained, but standings-only
output omits the old PHP header include and unavailable avatar links.

Both report services default to waiting **20 minutes after each run finishes**
before starting the next run. Change the shared interval in
`deploy/server/environments/local.env` or `deploy/server/environments/production.env`:

```dotenv
REPORT_INTERVAL_MINUTES=20
```

The value must be a whole number from 1 to 525600. After changing it, run
`make server-reports-up` or `make server-prod-reports-up` with the stack already
running. These targets regenerate configuration and restart only the report
schedulers; they do not build or restart the game servers or Apache. An interval
change takes effect when the report containers are recreated. Existing configs
that omit the setting default to 20 minutes.

For a packaged release, edit `REPORT_INTERVAL_MINUTES` in the extracted
`compose.env`, then apply it without rebuilding:

```sh
docker compose --env-file compose.env -f deploy/server/compose.yaml \
  -f workers.compose.json up --detach --no-deps --force-recreate empire-standings avatar-reports
```

Each service retries after its configured interval if generation fails, logging
the failure and continuing to serve the previous published report. Runs do not
overlap; the existing locks also guard against simultaneous manual refreshes.
Stopping a report container interrupts its current job or wait.

With the stack running and the updated web image installed, refresh manually
(these commands run once and do not build):

```sh
make server-standings
# Production:
make server-prod-standings
```

From an extracted release directory, the equivalent is:

```sh
docker compose --env-file compose.env -f deploy/server/compose.yaml \
  -f workers.compose.json run --rm --no-deps empire-standings --once
```

To rebuild reporting changes and publish fresh standings without restarting game
servers, use `make server-web-up` (production: `make server-prod-web-up
SERVER_CONFIG=release`). The web-up target rebuilds the shared image and recreates
Apache and both report schedulers, which begin an immediate refresh. Full-stack
`server-up` targets also build the web image and start the report services.
On a newly initialized universe, refresh again after the scene server has created
the galaxy and players have established empires.

The homepage's `/avatars` link opens a static avatar directory with views by
name and empire. Each avatar links to its profile, including its selfie when
present. `AuEmpireReport -avatars` generates these pages and their flag images
independently of standings or blueprint exchange. The current legacy profile
layout is retained; deleted avatars and pirate-empire avatars are excluded, and
the old synthetic Silverwill entry is not added.

The `avatar-reports` service uses the same web image and begins on stack
startup after PostgreSQL is healthy, then uses the same configurable interval.
It publishes under `/reports/avatars/`, with a five-minute timeout and a separate
lock. A failed generation leaves the previous published pages in place. After a
successful generation, obsolete profiles and images are removed from this
subdirectory.

To build and publish avatar changes while the stack is running:

```sh
make server-web-up
# Production:
make server-prod-web-up SERVER_CONFIG=release
```

For an additional immediate refresh, `make server-avatars` and
`make server-prod-avatars` run once without building. From an extracted release directory:

```sh
docker compose --env-file compose.env -f deploy/server/compose.yaml \
  -f workers.compose.json run --rm --no-deps avatar-reports --once
```

The report volume survives image rebuilds, container replacement, and normal
`server-down`/`server-prod-down`. `server-reset` and Compose `down --volumes`
delete it along with the database. Back up reports separately from PostgreSQL.
Apache access/error logs go to Docker's bounded logs rather than this volume.

### Connect a local client

Linux:

```bash
(cd build/linux-debug/bin && ./AuSceneClient -alocalhost -log)
```

Windows:

```powershell
Push-Location .\build\windows-debug\bin
.\AuSceneClient.exe -alocalhost -log
Pop-Location
```

`-a` points the login, mail, and scene masters at `localhost`. Their fixed ports are `16757`, `16758`, and `16759`. Redirected workers advertise `127.0.0.1` and their configured published ports.

VS Code includes local Debug client launches for Linux and Windows. Launch targets do not start or restart the stack; run `make server-up` first. The Linux-only `Linux Server: Attach scene-worker-1` launch attaches GDB to the first scene worker. The local Debug worker receives ptrace permissions; production workers do not.

### Windows clients with Docker Engine inside WSL 2

When Docker Engine runs directly inside WSL 2 in NAT mode, Windows `localhost`
forwarding handles TCP but does not forward the game's UDP controls. Login and
scene loading can work while attacking and switching held items fail. Movement
can still appear to work because the client also processes it locally.

Check the networking mode with `wslinfo --networking-mode`. For NAT mode, run
`hostname -I` inside the WSL distribution hosting Docker and note its WSL IPv4
address (usually the first address, not a Docker bridge address). Set both values
in `deploy/server/environments/local.env` to that address, preserving any other
overrides. For example:

```dotenv
BIND_ADDRESS=172.18.91.213
PUBLIC_HOST=172.18.91.213
```

Run `make server-up` to apply the settings, then reconnect the Windows client
using that address in the connection target field or with `-a172.18.91.213`.
Use the actual WSL address in place of the example. Set the same address in the
VS Code launch arguments when debugging. WSL's address can change after a WSL
restart; update both settings and restart the stack when it does.

This publishes the ports on the WSL interface and advertises an address Windows
can reach over both TCP and UDP. Changing only the client connection target is
insufficient because the servers redirect the client to `PUBLIC_HOST`.

See Microsoft's [WSL localhost implementation notes](https://github.com/microsoft/WSL/blob/master/doc/docs/technical-documentation/localhost.md)
for the TCP forwarding behavior in NAT mode.

## Single-host production

### Host configuration

Copy the production template and set the public host and every secret:

```bash
cp deploy/server/environments/production.env.example \
   deploy/server/environments/production.env
$EDITOR deploy/server/environments/production.env
```

The renderer rejects template hostnames and unset secrets. Validate without starting services:

```bash
make server-prod-config
```

Start and operate production:

```bash
make server-prod-up
make server-prod-status
make server-prod-logs
make server-prod-down
```

Scale during deployment:

```bash
make server-prod-up SCENE_WORKERS=8
```

The public firewall must permit:

- the configured web TCP port (`80` by default) when serving HTTP directly;
- TCP `16757`, `16758`, and `16759` for the masters;
- the configured login-worker, mail-worker, and scene-manager TCP ports;
- each scene worker's TCP/UDP scene port and TCP chat port.

All public game roles currently advertise the same `PUBLIC_HOST` with unique ports. `server-prod-down` preserves the production PostgreSQL and web report volumes. There is deliberately no production reset target.

The original protocol does not provide modern transport security. Public deployment still requires host hardening, firewall policy, monitoring, backups, and an explicit assessment of the legacy authentication protocol.

### GitHub Actions image publishing

Pushes to `main` publish `ghcr.io/<username>/openshores-server` with `latest` and
commit SHA tags, plus a deployment artifact named `server-production-compose-<commit SHA>`.

Set these repository Actions secrets:

- `GHCR_USERNAME`: registry username.
- `GHCR_TOKEN`: token with permission to publish the image.
- `SERVER_PRODUCTION_ENV`: production `.env` contents; use
  [`production.env.example`](environments/production.env.example) as a template.

Download the artifact from the workflow run. On a host with Docker Engine and
Docker Compose installed, extract its tar into a dedicated directory and start:

```bash
tar -xf server-production-compose.tar
./start.sh
```

For private images, run `docker login ghcr.io` first. Run `./stop.sh` to stop the
stack while preserving the database and web reports. **The artifact contains production credentials.**

## Configuration model

Important settings:

| Setting | Purpose |
| --- | --- |
| `SERVER_BUILD_CONFIG` | `debug`, `release`, or `relwithdebinfo` |
| `SCENE_WORKERS` | Number of generated scene-worker containers |
| `ATOM_MANAGERS` | Atom-manager bundles per scene worker |
| `BIND_ADDRESS` | Host interface used for published game ports |
| `WEB_BIND_ADDRESS` | Host interface used for HTTP; independent of game binding |
| `WEB_PORT` | Published HTTP port, default `80` |
| `PUBLIC_HOST` | Host/IP placed in client redirect packets |
| `*_PORT` | Published role and worker ports |
| `POSTGRES_VOLUME` | Persistent database volume name |
| `AU_DB_PASSWORD` | Runtime database-user password |
| `SERVER_LOGIN_PASSWORD` | Password used by scene server accounts |

Generated Compose environment and worker services live under `build/server/local/` or `build/server/production/`.

Application defaults remain compatible with the original deployment. Docker supplies private login, mail, and database endpoints through environment variables; workers separately report the configured public host and port to clients.

### Scene-master INI file

The scene-master image copies an editable deployment file to
`/etc/openshores/scene-master.ini`. This file does not use a volume or a bind mount:

| Stack | Deployment file | Initial setting |
| --- | --- | --- |
| Local | `deploy/server/environments/local.ini` | `galaxyGen=1galaxy` |
| Production | `deploy/server/environments/production.ini` | `galaxyGen=all` |

For a fresh universe containing only Shores of Hazeron, set:

```ini
[Settings]
galaxyGen=1galaxy
```

Use `galaxyGen=all` to generate every galaxy. Existing galaxies are retained;
changing the setting does not reduce an existing universe to one galaxy.
Managers and workers load the galaxies from the database and do not need this INI.

Compose passes `=/etc/openshores/scene-master` to `AuSceneServer`; the application
appends `.ini`. At launch, Compose builds a small image derived from the game
server image, using `environments/scene-master.Dockerfile` and the selected INI.
The build context is relative to the deployment's Compose file, so it works
from either the repository or an extracted release archive. An INI change
rebuilds this configuration layer and recreates the scene-master container when
you rerun `make server-up`, `make server-prod-up`, or the release's `./start.sh`.
The prebuilt game server executable is reused. A plain container restart keeps
the INI that was copied into its image.

These INI files are maintained directly, not generated by `configure.py`.
Keep deployment credentials and network settings in the existing `.env` files:
INI settings override command-line arguments when both specify the same key.
The production deployment archive includes
`deploy/server/environments/scene-master.Dockerfile` and
`deploy/server/environments/production.ini`, which can be edited after extraction
and before running `./start.sh`.

## Logs and data

`make server-logs` and `make server-prod-logs` use Docker Compose logs. Each service uses bounded Docker local logs: three files of up to 20 MiB.

PostgreSQL state lives in the named volume selected by `POSTGRES_VOLUME`. Back up that volume before upgrades or production topology changes.

Generated web reports live in `${COMPOSE_PROJECT_NAME}-web-reports`. Both data
volumes are preserved by normal shutdown commands.
