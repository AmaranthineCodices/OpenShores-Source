# syntax=docker/dockerfile:1.7

FROM ubuntu:22.04 AS toolchain

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libopenal-dev \
        libqt5opengl5-dev \
        libqt5sql5-psql \
        libsdl2-dev \
        ninja-build \
        python3 \
        qtbase5-dev \
        qtbase5-dev-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
CMD ["/bin/bash"]

FROM toolchain AS server-build

ARG SERVER_BUILD_TYPE=Debug

COPY . /src
RUN --mount=type=cache,id=openshores-server-build-${SERVER_BUILD_TYPE},target=/build \
    cmake \
        -S /src \
        -B /build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE="$SERVER_BUILD_TYPE" \
        -DAU_OUTPUT_ROOT=/server \
    && cmake --build /build --target servers --parallel "$(nproc)"

FROM ubuntu:22.04 AS server-runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libgl1 \
        libglu1-mesa \
        libopenal1 \
        libqt5network5 \
        libqt5opengl5 \
        libqt5sql5-psql \
        libsdl2-2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 --shell /bin/bash openshores \
    && install -d -o openshores -g openshores /opt/openshores/bin /opt/openshores/lib /var/lib/openshores

COPY --from=server-build /server/bin/AuLoginServer /server/bin/AuMailServer /server/bin/AuSceneServer /opt/openshores/bin/
COPY --from=server-build /server/lib/*.so* /opt/openshores/lib/
COPY motds /var/lib/openshores/motds
COPY deploy/server/image/health-port.sh /opt/openshores/bin/health-port
RUN chmod 0755 /opt/openshores/bin/health-port

ENV QT_QPA_PLATFORM=offscreen
WORKDIR /var/lib/openshores
USER openshores

FROM server-runtime AS server-debug

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends gdb procps \
    && rm -rf /var/lib/apt/lists/*
USER openshores
