# Docker builds are the default. Native builds are opt-in.
#
# Examples:
#   make client
#   make servers
#   make windows-client
#   make native-client
#   make CONFIG=debug native-client
#   make clean

CONFIG ?= release
CMAKE ?= cmake
GENERATOR ?= Ninja
PARALLEL ?= $(shell nproc 2>/dev/null || echo 4)

LINUX_IMAGE ?= hazeron-linux-qt5
WINDOWS_IMAGE ?= hazeron-mingw-qt5
LINUX_CACHE_VOLUME ?= hazeron-linux-$(CONFIG)-cache
WINDOWS_CACHE_VOLUME ?= hazeron-windows-$(CONFIG)-cache
NATIVE_BUILD_DIR ?= build/native-linux-$(CONFIG)
SERVER_CONFIG ?=
SCENE_WORKERS ?=
SERVER_LOG_TAIL ?= 200
SERVER_PRODUCTION_ENV ?= deploy/server/production.env

LOCAL_SERVER_DIR := build/server/local
LOCAL_SERVER_ENV := $(LOCAL_SERVER_DIR)/compose.env
LOCAL_SERVER_WORKERS := $(LOCAL_SERVER_DIR)/workers.compose.json
PRODUCTION_SERVER_DIR := build/server/production
PRODUCTION_SERVER_ENV := $(PRODUCTION_SERVER_DIR)/compose.env
PRODUCTION_SERVER_WORKERS := $(PRODUCTION_SERVER_DIR)/workers.compose.json
LOCAL_COMPOSE = BUILDX_NO_DEFAULT_ATTESTATIONS=1 docker compose \
	--env-file "$(LOCAL_SERVER_ENV)" \
	-f deploy/server/compose.yaml -f "$(LOCAL_SERVER_WORKERS)"
PRODUCTION_COMPOSE = BUILDX_NO_DEFAULT_ATTESTATIONS=1 docker compose \
	--env-file "$(PRODUCTION_SERVER_ENV)" \
	-f deploy/server/compose.yaml -f "$(PRODUCTION_SERVER_WORKERS)"

DEFAULT_CACHE_VOLUMES := \
	hazeron-linux-debug-cache \
	hazeron-linux-release-cache \
	hazeron-linux-relwithdebinfo-cache \
	hazeron-windows-debug-cache \
	hazeron-windows-release-cache \
	hazeron-windows-relwithdebinfo-cache

ifeq ($(CONFIG),debug)
CMAKE_BUILD_TYPE := Debug
else ifeq ($(CONFIG),release)
CMAKE_BUILD_TYPE := Release
else ifeq ($(CONFIG),relwithdebinfo)
CMAKE_BUILD_TYPE := RelWithDebInfo
else
$(error CONFIG must be debug, release, or relwithdebinfo)
endif

.PHONY: all build client clients servers cgi tools \
        ausceneclient auloginserver aumailserver ausceneserver \
        linux-image windows-toolchain windows-client \
        native-configure native-build native-client native-clients \
        native-servers native-cgi native-tools \
        native-ausceneclient native-auloginserver \
        native-aumailserver native-ausceneserver \
        server-config server-ensure-config server-up server-down \
        server-logs server-status server-reset \
        server-prod-config server-prod-ensure-config server-prod-up \
        server-prod-down server-prod-logs server-prod-status \
        run-client clean rebuild help

define run_linux_build
HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
HAZERON_LINUX_CACHE_VOLUME="$(LINUX_CACHE_VOLUME)" \
HAZERON_BUILD_CONFIG="$(CONFIG)" \
	bash docker/linux/build.sh $(1)
endef

all:
	$(call run_linux_build,programs)

build: all

# Dockerized Linux builds.
linux-image:
	docker build --tag "$(LINUX_IMAGE)" \
		--target toolchain \
		--file docker/linux/Dockerfile docker/linux

client:
	$(call run_linux_build,client)

clients:
	$(call run_linux_build,clients)

servers:
	$(call run_linux_build,servers)

cgi:
	$(call run_linux_build,cgi)

tools:
	$(call run_linux_build,tools)

ausceneclient: client

auloginserver:
	$(call run_linux_build,AuLoginServer)

aumailserver:
	$(call run_linux_build,AuMailServer)

ausceneserver:
	$(call run_linux_build,AuSceneServer)

# Dockerized MinGW/Qt 5 cross-build.
windows-toolchain:
	docker build --tag "$(WINDOWS_IMAGE)" \
		--target toolchain \
		--file docker/windows/Dockerfile docker/windows

windows-client:
	HAZERON_MINGW_IMAGE="$(WINDOWS_IMAGE)" \
	HAZERON_WINDOWS_CACHE_VOLUME="$(WINDOWS_CACHE_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/windows/build-client.sh

# Opt-in native Linux build for faster local iteration.
native-configure:
	$(CMAKE) -S . -B "$(NATIVE_BUILD_DIR)" -G "$(GENERATOR)" \
		-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE)

native-build: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" \
		--parallel "$(PARALLEL)"

native-client native-ausceneclient: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" --target client \
		--parallel "$(PARALLEL)"

native-clients: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" --target clients \
		--parallel "$(PARALLEL)"

native-servers: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" --target servers \
		--parallel "$(PARALLEL)"

native-cgi: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" --target cgi \
		--parallel "$(PARALLEL)"

native-tools: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" --target tools \
		--parallel "$(PARALLEL)"

native-auloginserver: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" --target AuLoginServer \
		--parallel "$(PARALLEL)"

native-aumailserver: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" --target AuMailServer \
		--parallel "$(PARALLEL)"

native-ausceneserver: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" --target AuSceneServer \
		--parallel "$(PARALLEL)"

run-client: client
	"build/linux-$(CONFIG)/bin/AuSceneClient"

server-config:
	python3 deploy/server/configure.py --environment local \
		$(if $(strip $(SERVER_CONFIG)),--config "$(SERVER_CONFIG)") \
		$(if $(strip $(SCENE_WORKERS)),--scene-workers "$(SCENE_WORKERS)")

server-ensure-config:
	@if [ ! -f "$(LOCAL_SERVER_ENV)" ] || [ ! -f "$(LOCAL_SERVER_WORKERS)" ]; then \
		python3 deploy/server/configure.py --environment local; \
	fi

server-up: server-config
	$(LOCAL_COMPOSE) up --build --detach --remove-orphans --wait

server-down: server-ensure-config
	$(LOCAL_COMPOSE) down --remove-orphans

server-logs: server-ensure-config
	$(LOCAL_COMPOSE) logs --follow --tail="$(SERVER_LOG_TAIL)" $(SERVICE)

server-status: server-ensure-config
	$(LOCAL_COMPOSE) ps

server-reset: server-ensure-config
	@if [ "$(CONFIRM)" != "yes" ]; then \
		printf 'Delete the local universe database and restart? [y/N] '; \
		read answer; \
		case "$$answer" in y|Y|yes|YES) ;; *) echo 'Cancelled.'; exit 1;; esac; \
	fi
	$(LOCAL_COMPOSE) down --volumes --remove-orphans
	$(LOCAL_COMPOSE) up --build --detach --remove-orphans --wait

server-prod-config:
	python3 deploy/server/configure.py --environment production \
		--env-file "$(SERVER_PRODUCTION_ENV)" \
		$(if $(strip $(SERVER_CONFIG)),--config "$(SERVER_CONFIG)") \
		$(if $(strip $(SCENE_WORKERS)),--scene-workers "$(SCENE_WORKERS)")

server-prod-ensure-config:
	@if [ ! -f "$(PRODUCTION_SERVER_ENV)" ] || [ ! -f "$(PRODUCTION_SERVER_WORKERS)" ]; then \
		python3 deploy/server/configure.py --environment production \
			--env-file "$(SERVER_PRODUCTION_ENV)"; \
	fi

server-prod-up: server-prod-config
	$(PRODUCTION_COMPOSE) up --build --detach --remove-orphans --wait

server-prod-down: server-prod-ensure-config
	$(PRODUCTION_COMPOSE) down --remove-orphans

server-prod-logs: server-prod-ensure-config
	$(PRODUCTION_COMPOSE) logs --follow --tail="$(SERVER_LOG_TAIL)" $(SERVICE)

server-prod-status: server-prod-ensure-config
	$(PRODUCTION_COMPOSE) ps

# Docker caches live in named volumes. build/ contains exported bin/lib files
# and any opt-in native build trees.
clean:
	$(CMAKE) -E remove_directory build
	@for volume in $(sort $(DEFAULT_CACHE_VOLUMES) $(LINUX_CACHE_VOLUME) $(WINDOWS_CACHE_VOLUME)); do \
		docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	done

rebuild: clean all

help:
	@if [ -t 1 ] && [ -z "$${NO_COLOR:-}" ]; then \
		heading='\033[1;36m'; reset='\033[0m'; \
	else \
		heading=; reset=; \
	fi; \
	printf '%b\n' \
		"$${heading}Common builds$${reset}" \
		'  make                      Build all Linux programs' \
		'  make client               Build the Linux client' \
		'  make servers              Build all Linux servers' \
		'  make windows-client       Build the Windows client' \
		'' \
		"$${heading}Linux target groups$${reset}" \
		'  make clients              Build all clients' \
		'  make cgi                  Build account and status programs' \
		'  make tools                Build admin and content tools' \
		'' \
		"$${heading}Individual servers$${reset}" \
		'  make auloginserver        Build AuLoginServer' \
		'  make aumailserver         Build AuMailServer' \
		'  make ausceneserver        Build AuSceneServer' \
		'' \
		"$${heading}Native Linux builds$${reset}" \
		'  make native-client        Build the client' \
		'  make native-clients       Build all clients' \
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
		"$${heading}Aliases$${reset}" \
		'  make all | build                 Build all Linux programs' \
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
		'  SERVER_CONFIG=debug|release|relwithdebinfo' \
		'  SCENE_WORKERS=N                       (default: 1)' \
		'  SERVICE=name                          (filter log targets)' \
		'  SERVER_PRODUCTION_ENV=path            (production settings)' \
		'' \
		"$${heading}Examples$${reset}" \
		'  make CONFIG=debug client' \
		'  make CONFIG=relwithdebinfo windows-client' \
		'  make server-up SCENE_WORKERS=3' \
		'  make server-logs SERVICE=scene-worker-1'
