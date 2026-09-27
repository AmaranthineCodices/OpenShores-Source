#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
image=${HAZERON_MINGW_IMAGE:-hazeron-mingw-qt5}
build_volume=${HAZERON_WINDOWS_BUILD_VOLUME:-hazeron-windows-release-build}
artifact_dir="$repo_root/build/docker-windows-release"
temporary_dir=$(mktemp -d)
container_id=
cleanup() {
    if [[ -n "$container_id" ]]; then
        docker rm -f "$container_id" >/dev/null 2>&1 || true
    fi
    rm -rf "$temporary_dir"
}
trap cleanup EXIT

cd "$repo_root"

docker build \
    --tag "$image" \
    --file docker/windows/Dockerfile \
    docker/windows

container_id=$(docker create \
    --mount "type=volume,source=$build_volume,target=/build" \
    "$image" sleep infinity)
docker start "$container_id" >/dev/null

tar \
    --exclude=.git \
    --exclude=build \
    --exclude=debug \
    --exclude=release \
    --exclude=old-editor \
    --exclude=docs \
    --exclude='*/.d' \
    --exclude='*/.r' \
    --exclude='*/.qmake.stash' \
    --exclude='*/Makefile' \
    --exclude='*/*.pro' \
    -cf - . | docker exec -i "$container_id" tar -xf - -C /src

docker exec "$container_id" /bin/bash -lc '
    "${MXE_TARGET}-cmake" \
        -S /src \
        -B /build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build /build \
        --target client \
        --parallel "$(nproc)"
    rm -rf /artifacts
    mkdir -p /artifacts
    cp -a /build/bin /artifacts/bin
    cp -a /build/lib /artifacts/lib
'

docker cp "$container_id:/artifacts/." "$temporary_dir"
mkdir -p "$artifact_dir"
cp -a "$temporary_dir/." "$artifact_dir/"

printf 'Windows artifacts: %s\n' "$artifact_dir"
printf 'Windows build cache volume: %s\n' "$build_volume"
