.PHONY: linux-package win-package release-package

linux-package: client-all
	bash docker/linux/package.sh "$(CONFIG)"

win-package: win-client-all
	HAZERON_MINGW_IMAGE="$(WINDOWS_IMAGE)" \
		bash docker/windows/package.sh "$(CONFIG)"

release-package: linux-package win-package
