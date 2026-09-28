.PHONY: native-configure native-build native-client native-clients \
        native-client-all native-servers native-cgi native-tools \
        native-ausceneclient native-auloginserver \
        native-aumailserver native-ausceneserver

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

native-client-all: native-configure
	$(CMAKE) --build "$(NATIVE_BUILD_DIR)" --target client-all \
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
