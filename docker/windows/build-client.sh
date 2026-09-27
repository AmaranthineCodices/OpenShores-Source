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

if ! docker image inspect "$image" >/dev/null 2>&1; then
    docker build \
        --tag "$image" \
        --file docker/windows/Dockerfile \
        docker/windows
fi

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

docker exec "$container_id" /bin/bash -ec '
    "${MXE_TARGET}-cmake" \
        -S /src \
        -B /build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build /build \
        --target client \
        --parallel "$(nproc)"

    package_dir=/artifacts/bin
    qt_plugins="/opt/mxe/usr/${MXE_TARGET}/qt5/plugins"
    target_prefix="/opt/mxe/usr/${MXE_TARGET}"

    rm -rf /artifacts
    mkdir -p "$package_dir" /artifacts/lib
    cp -a /build/bin/. "$package_dir/"
    cp -a /build/lib/. /artifacts/lib/

    mkdir -p \
        "$package_dir/platforms" \
        "$package_dir/imageformats" \
        "$package_dir/styles" \
        "$package_dir/bearer"
    cp "$qt_plugins/platforms/qwindows.dll" "$package_dir/platforms/"
    cp "$qt_plugins/imageformats/"*.dll "$package_dir/imageformats/"
    cp "$qt_plugins/styles/"*.dll "$package_dir/styles/"
    cp "$qt_plugins/bearer/"*.dll "$package_dir/bearer/"

    python3 /opt/mxe/tools/copydlldeps.py \
        "$package_dir" \
        -C "$package_dir" \
           "$package_dir/platforms" \
           "$package_dir/imageformats" \
           "$package_dir/styles" \
           "$package_dir/bearer" \
        -L "$target_prefix/bin" \
           "$target_prefix/qt5/bin"
'

docker cp "$container_id:/artifacts/." "$temporary_dir"
rm -rf "$artifact_dir"
mkdir -p "$artifact_dir"
cp -a "$temporary_dir/." "$artifact_dir/"

printf 'Windows artifacts: %s\n' "$artifact_dir"
printf 'Windows build cache volume: %s\n' "$build_volume"
