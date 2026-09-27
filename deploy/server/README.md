# Docker server deployment

The deployment runs every server process in its own container. The login, mail, and scene roles reuse one game-server image; PostgreSQL uses its own image and container.

This deployment targets one Docker host. Scene workers scale across containers on that host. Multi-host scheduling is not included.

## Topology

```text
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

`server-down` preserves the PostgreSQL volume. Delete and recreate the local universe only when intended:

```bash
make server-reset
# Non-interactive: make server-reset CONFIRM=yes
```

Scale the scene-worker pool:

```bash
make server-up SCENE_WORKERS=3
```

Local defaults are in `local.env.example`. Copy it to the ignored `local.env` only when overrides are needed:

```bash
cp deploy/server/local.env.example deploy/server/local.env
```

The local database creates this development account:

```text
account:  local
password: local
```

Change the credentials in `local.env` before the first initialization, or run `make server-reset` after changing them.

### Connect a local client

Linux:

```bash
build/linux-debug/bin/AuSceneClient -alocalhost -log
```

Windows:

```powershell
.\build\windows-debug\bin\AuSceneClient.exe -alocalhost -log
```

`-a` points the login, mail, and scene masters at `localhost`. Their fixed ports are `16757`, `16758`, and `16759`. Redirected workers advertise `127.0.0.1` and their configured published ports.

VS Code includes local Debug client launches for Linux and Windows. Launch targets do not start or restart the stack; run `make server-up` first. The Linux-only `Linux Server: Attach scene-worker-1` launch attaches GDB to the first scene worker. The local Debug worker receives ptrace permissions; production workers do not.

## Single-host production

Copy the production template and set the public host and every secret:

```bash
cp deploy/server/production.env.example deploy/server/production.env
$EDITOR deploy/server/production.env
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

- TCP `16757`, `16758`, and `16759` for the masters;
- the configured login-worker, mail-worker, and scene-manager TCP ports;
- each scene worker's TCP/UDP scene port and TCP chat port.

All public roles currently advertise the same `PUBLIC_HOST` with unique ports. `server-prod-down` preserves the production PostgreSQL volume. There is deliberately no production reset target.

The original protocol does not provide modern transport security. Public deployment still requires host hardening, firewall policy, monitoring, backups, and an explicit assessment of the legacy authentication protocol.

## Configuration model

Important settings:

| Setting | Purpose |
| --- | --- |
| `SERVER_BUILD_CONFIG` | `debug`, `release`, or `relwithdebinfo` |
| `SCENE_WORKERS` | Number of generated scene-worker containers |
| `ATOM_MANAGERS` | Atom-manager bundles per scene worker |
| `BIND_ADDRESS` | Host interface used for published ports |
| `PUBLIC_HOST` | Host/IP placed in client redirect packets |
| `*_PORT` | Published role and worker ports |
| `POSTGRES_VOLUME` | Persistent database volume name |
| `AU_DB_PASSWORD` | Runtime database-user password |
| `SERVER_LOGIN_PASSWORD` | Password used by scene server accounts |

Generated Compose environment and worker services live under `build/server/local/` or `build/server/production/`.

Application defaults remain compatible with the original deployment. Docker supplies private login, mail, and database endpoints through environment variables; workers separately report the configured public host and port to clients.

## Logs and data

`make server-logs` and `make server-prod-logs` use Docker Compose logs. Each service uses bounded Docker local logs: three files of up to 20 MiB.

PostgreSQL state lives in the named volume selected by `POSTGRES_VOLUME`. Back up that volume before upgrades or production topology changes.
