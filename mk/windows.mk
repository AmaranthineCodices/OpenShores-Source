.PHONY: windows-toolchain windows-client windows-client-all windows-clients \
        win-client win-client-all

windows-toolchain:
	docker build --tag "$(WINDOWS_IMAGE)" \
		--target toolchain \
		--file docker/windows/Dockerfile docker/windows

windows-client win-client:
	HAZERON_MINGW_IMAGE="$(WINDOWS_IMAGE)" \
	HAZERON_WINDOWS_CACHE_VOLUME="$(WINDOWS_CACHE_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
	AU_TARGET=client \
		bash docker/windows/build-client.sh

windows-client-all windows-clients win-client-all:
	HAZERON_MINGW_IMAGE="$(WINDOWS_IMAGE)" \
	HAZERON_WINDOWS_CACHE_VOLUME="$(WINDOWS_CACHE_VOLUME)" \
	HAZERON_BUILD_CONFIG="$(CONFIG)" \
	AU_TARGET=client-all \
		bash docker/windows/build-client.sh
