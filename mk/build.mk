DEFAULT_CACHE_VOLUMES := \
	hazeron-linux-debug-cache \
	hazeron-linux-release-cache \
	hazeron-linux-relwithdebinfo-cache \
	hazeron-windows-debug-cache \
	hazeron-windows-release-cache \
	hazeron-windows-relwithdebinfo-cache \
	hazeron-assets-cache

.PHONY: all build client clients client-all servers cgi tools \
        ausceneclient auloginserver aumailserver ausceneserver \
        linux-image run-client clean rebuild

define run_linux_build
HAZERON_LINUX_IMAGE="$(LINUX_IMAGE)" \
HAZERON_LINUX_CACHE_VOLUME="$(LINUX_CACHE_VOLUME)" \
HAZERON_BUILD_CONFIG="$(CONFIG)" \
	bash docker/linux/build.sh $(1)
endef

all:
	$(call run_linux_build,programs)

build: all

linux-image:
	docker build --tag "$(LINUX_IMAGE)" \
		--target toolchain \
		--file docker/linux/Dockerfile docker/linux

client:
	$(call run_linux_build,client)

clients:
	$(call run_linux_build,clients)

client-all:
	$(call run_linux_build,client-all)

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

run-client: client
	cd "build/linux-$(CONFIG)/bin" && ./AuSceneClient

clean:
	$(CMAKE) -E remove_directory build
	@for volume in $(sort $(DEFAULT_CACHE_VOLUMES) $(LINUX_CACHE_VOLUME) $(WINDOWS_CACHE_VOLUME) $(ASSETS_CACHE_VOLUME)); do \
		docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	done

rebuild: clean all
