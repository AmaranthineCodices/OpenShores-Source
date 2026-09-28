.PHONY: help

help:
	@if [ -t 1 ] && [ -z "$${NO_COLOR:-}" ]; then \
		heading='\033[1;36m'; reset='\033[0m'; \
	else \
		heading=; reset=; \
	fi; \
	printf '%b\n' \
		"$${heading}Common builds$${reset}" \
		'  make                      Build all Linux programs' \
		'  make client               Build the Linux scene client' \
		'  make client-all           Build all Linux clients' \
		'  make win-client           Build the Windows scene client' \
		'  make win-client-all       Build all Windows clients' \
		'  make servers              Build all Linux servers' \
		'' \
		"$${heading}Release packages$${reset}" \
		'  make linux-package        Build the Linux game and launcher archives' \
		'  make win-package          Build the Windows game and launcher archives' \
		'  make release-package      Build every release archive' \
		'' \
		"$${heading}Linux target groups$${reset}" \
		'  make clients              Alias for client-all' \
		'  make cgi                  Build account and status programs' \
		'  make tools                Build admin and content tools' \
		'' \
		"$${heading}Individual servers$${reset}" \
		'  make auloginserver        Build AuLoginServer' \
		'  make aumailserver         Build AuMailServer' \
		'  make ausceneserver        Build AuSceneServer' \
		'' \
		"$${heading}Native Linux builds$${reset}" \
		'  make native-client        Build the scene client' \
		'  make native-client-all    Build all clients' \
		'  make native-clients       Alias for native-client-all' \
		'  make native-servers       Build all servers' \
		'  make native-cgi           Build account and status programs' \
		'  make native-tools         Build admin and content tools' \
		'  make native-build         Build every configured target' \
		'' \
		"$${heading}Local multiplayer servers$${reset}" \
		'  make server-up            Build and start the local stack' \
		'  make server-down          Stop it without deleting data' \
		'  make server-logs          Follow all server logs' \
		'  make server-status        Show container and health status' \
		'  make server-reset         Delete local data and restart' \
		'  make server-prod-up       Build and start production' \
		'  make server-prod-down     Stop production, preserving data' \
		'  make server-prod-logs     Follow production logs' \
		'  make server-prod-status   Show production status' \
		'' \
		"$${heading}Toolchains and maintenance$${reset}" \
		'  make run-client           Build and run the Linux client' \
		'  make linux-image          Build the Linux toolchain image' \
		'  make windows-toolchain    Build the Windows toolchain image' \
		'  make clean                Remove artifacts and build caches' \
		'  make rebuild              Clean and rebuild Linux programs' \
		'' \
		"$${heading}Content assets$${reset}" \
		'  make audio-assets         Rebuild the runtime sound archive' \
		'  make shader-assets        Rebuild the embedded shader archive' \
		'  make story-assets         Validate and rebuild story archives' \
		'  make assets               Rebuild all content archives' \
		'' \
		"$${heading}Aliases$${reset}" \
		'  make all | build                 Build all Linux programs' \
		'  make clients                     Same as client-all' \
		'  make windows-client              Same as win-client' \
		'  make windows-client-all          Same as win-client-all' \
		'  make windows-clients             Same as win-client-all' \
		'  make ausceneclient               Same as client' \
		'  make native-ausceneclient        Same as native-client' \
		'  make native-auloginserver        Build AuLoginServer natively' \
		'  make native-aumailserver         Build AuMailServer natively' \
		'  make native-ausceneserver        Build AuSceneServer natively' \
		'' \
		"$${heading}Options$${reset}" \
		'  CONFIG=release|debug|relwithdebinfo  (default: release)' \
		'  PARALLEL=N                           (native builds only)' \
		'  LINUX_IMAGE=name                     (default: hazeron-linux-qt5)' \
		'  WINDOWS_IMAGE=name                   (default: hazeron-mingw-qt5)' \
		'  LINUX_CACHE_VOLUME=name              (default depends on CONFIG)' \
		'  WINDOWS_CACHE_VOLUME=name            (default depends on CONFIG)' \
		'  ASSETS_CACHE_VOLUME=name             (default: hazeron-assets-cache)' \
		'  SERVER_CONFIG=debug|release|relwithdebinfo' \
		'  SCENE_WORKERS=N                       (default: 1)' \
		'  SERVICE=name                          (filter log targets)' \
		'  SERVER_PRODUCTION_ENV=path' \
		'' \
		"$${heading}Examples$${reset}" \
		'  make CONFIG=debug client' \
		'  make CONFIG=relwithdebinfo windows-client' \
		'  make server-up SCENE_WORKERS=3' \
		'  make server-logs SERVICE=scene-worker-1'
