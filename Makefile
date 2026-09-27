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
LINUX_BUILD_VOLUME ?= hazeron-linux-$(CONFIG)-build
WINDOWS_BUILD_VOLUME ?= hazeron-windows-release-build
NATIVE_BUILD_DIR ?= build/native-linux-$(CONFIG)

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
        run-client clean clean-cache rebuild help

all:
	HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
	HAZERON_LINUX_BUILD_VOLUME="$(LINUX_BUILD_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/linux/build.sh programs

build: all

# Dockerized Linux builds.
linux-image:
	docker build --tag "$(LINUX_IMAGE)" \
		--target toolchain \
		--file docker/linux/Dockerfile docker/linux

client:
	HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
	HAZERON_LINUX_BUILD_VOLUME="$(LINUX_BUILD_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/linux/build.sh client

clients:
	HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
	HAZERON_LINUX_BUILD_VOLUME="$(LINUX_BUILD_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/linux/build.sh clients

servers:
	HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
	HAZERON_LINUX_BUILD_VOLUME="$(LINUX_BUILD_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/linux/build.sh servers

cgi:
	HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
	HAZERON_LINUX_BUILD_VOLUME="$(LINUX_BUILD_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/linux/build.sh cgi

tools:
	HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
	HAZERON_LINUX_BUILD_VOLUME="$(LINUX_BUILD_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/linux/build.sh tools

ausceneclient: client

auloginserver:
	HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
	HAZERON_LINUX_BUILD_VOLUME="$(LINUX_BUILD_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/linux/build.sh AuLoginServer

aumailserver:
	HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
	HAZERON_LINUX_BUILD_VOLUME="$(LINUX_BUILD_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/linux/build.sh AuMailServer

ausceneserver:
	HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
	HAZERON_LINUX_BUILD_VOLUME="$(LINUX_BUILD_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
		bash docker/linux/build.sh AuSceneServer

# Dockerized MinGW/Qt 5 cross-build.
windows-toolchain:
	docker build --tag "$(WINDOWS_IMAGE)" \
		--target toolchain \
		--file docker/windows/Dockerfile docker/windows

windows-client:
	HAZERON_MINGW_IMAGE="$(WINDOWS_IMAGE)" \
	HAZERON_WINDOWS_BUILD_VOLUME="$(WINDOWS_BUILD_VOLUME)" \
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

# Exported build directories are disposable. Named volumes retain compiler output.
clean:
	$(CMAKE) -E remove_directory build

# Explicitly discard the persistent Docker compiler caches.
clean-cache:
	-docker volume rm "$(LINUX_BUILD_VOLUME)"
	-docker volume rm "$(WINDOWS_BUILD_VOLUME)"

rebuild: clean clean-cache all

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
		'make clean                  Remove exported artifacts under build/' \
		'make clean-cache            Remove persistent Docker compiler caches' \
		'make rebuild                Delete artifacts/caches and rebuild all' \
		'' \
		'Variables:' \
		'  CONFIG=release|debug|relwithdebinfo  (default: release)' \
		'  PARALLEL=N                           (native builds only)' \
		'  LINUX_IMAGE=name                     (default: hazeron-linux-qt5)' \
		'  WINDOWS_IMAGE=name                   (default: hazeron-mingw-qt5)' \
		'  LINUX_BUILD_VOLUME=name              (persistent CMake/Ninja cache)' \
		'  WINDOWS_BUILD_VOLUME=name            (persistent MinGW cache)'
