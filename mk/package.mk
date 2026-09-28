.PHONY: linux-package win-package release-package

# Packages consume Docker output, even when NATIVE=1 selects native compilation
# for Linux build targets in the same invocation.
linux-package: _linux-docker-clients
	bash docker/linux/package.sh "$(CONFIG)"

win-package: win
	HAZERON_MINGW_IMAGE="$(WINDOWS_IMAGE)" \
		bash docker/windows/package.sh "$(CONFIG)"

release-package: linux-package win-package
