#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
image=${HAZERON_LINUX_IMAGE:-hazeron-linux-qt5}
config=${HAZERON_BUILD_CONFIG:-release}
target=${1:-all}

case "$config" in
    debug)
        cmake_build_type=Debug
        ;;
    release)
        cmake_build_type=Release
        ;;
    relwithdebinfo)
        cmake_build_type=RelWithDebInfo
        ;;
    *)
        echo "error: unsupported build configuration: $config" >&2
        exit 2
        ;;
esac

if [[ ! "$target" =~ ^[A-Za-z0-9_.-]+$ ]]; then
    echo "error: invalid CMake target: $target" >&2
    exit 2
fi

build_volume=${HAZERON_LINUX_BUILD_VOLUME:-hazeron-linux-${config}-build}
artifact_dir="$repo_root/build/linux-${config}"
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
    --file docker/linux/Dockerfile \
    docker/linux

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

docker exec "$container_id" /bin/bash -lc "
    cmake \
        -S /src \
        -B /build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=${cmake_build_type}
    cmake --build /build \
        --target ${target} \
        --parallel \"\$(nproc)\"
    rm -rf /artifacts
    mkdir -p /artifacts
    cp -a /build/bin /artifacts/bin
    cp -a /build/lib /artifacts/lib
"

docker cp "$container_id:/artifacts/." "$temporary_dir"
mkdir -p "$artifact_dir"
cp -a "$temporary_dir/." "$artifact_dir/"

printf 'Linux artifacts: %s\n' "$artifact_dir"
printf 'Linux build cache volume: %s\n' "$build_volume"
