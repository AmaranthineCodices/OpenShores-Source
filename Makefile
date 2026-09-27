# Reproducible Docker builds are the default. Native builds are opt-in.
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
WINDOWS_CACHE_VOLUME ?= hazeron-windows-release-cache
NATIVE_BUILD_DIR ?= build/native-linux-$(CONFIG)

DEFAULT_CACHE_VOLUMES := \
	hazeron-linux-debug-cache \
	hazeron-linux-release-cache \
	hazeron-linux-relwithdebinfo-cache \
	hazeron-windows-release-cache

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

# Docker caches live in named volumes; build/ contains exported bin/lib files
# and any opt-in native build trees.
clean:
	$(CMAKE) -E remove_directory build
	@for volume in $(sort $(DEFAULT_CACHE_VOLUMES) $(LINUX_CACHE_VOLUME) $(WINDOWS_CACHE_VOLUME)); do \
		docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	done

rebuild: clean all

help:
	@printf '%s\n' \
		'make [all]                  Docker-build the Linux client and servers' \
		'make client                 Docker-build AuSceneClient' \
		'make clients                Docker-build all client programs' \
		'make servers                Docker-build all multiplayer servers' \
		'make cgi                    Docker-build account/status programs' \
		'make tools                  Docker-build admin/content tools' \
		'make ausceneclient          Alias for client' \
		'make auloginserver          Docker-build AuLoginServer' \
		'make aumailserver           Docker-build AuMailServer' \
		'make ausceneserver          Docker-build AuSceneServer' \
		'make windows-client         Build a runnable Windows x64 client bundle' \
		'make linux-image            Build only the Linux toolchain image' \
		'make windows-toolchain      Build only the MinGW/Qt 5 image' \
		'make native-client          Build the client with host tools' \
		'make native-clients         Build all clients with host tools' \
		'make native-servers         Build the servers with host tools' \
		'make native-cgi             Build account/status programs natively' \
		'make native-tools           Build admin/content tools natively' \
		'make native-build           Build every configured CMake target natively' \
		'make run-client             Build in Linux Docker, then run the client' \
		'make clean                  Remove all build artifacts and caches' \
		'make rebuild                Clean and rebuild all Linux programs' \
		'' \
		'Variables:' \
		'  CONFIG=release|debug|relwithdebinfo  (default: release)' \
		'  PARALLEL=N                           (native builds only)' \
		'  LINUX_IMAGE=name                     (default: hazeron-linux-qt5)' \
		'  WINDOWS_IMAGE=name                   (default: hazeron-mingw-qt5)' \
		'  LINUX_CACHE_VOLUME=name              (default depends on CONFIG)' \
		'  WINDOWS_CACHE_VOLUME=name            (default: hazeron-windows-release-cache)'
