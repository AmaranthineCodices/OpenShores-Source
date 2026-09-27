#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
daemon_repo_root=$(bash "$repo_root/docker/resolve-project-mount.sh" "$repo_root")
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

cache_volume=${HAZERON_LINUX_CACHE_VOLUME:-hazeron-linux-${config}-cache}
local_output_dir="$repo_root/build/linux-${config}"
daemon_output_dir="$daemon_repo_root/build/linux-${config}"
mkdir -p "$local_output_dir"

cd "$repo_root"

docker build \
    --tag "$image" \
    --file docker/linux/Dockerfile \
    docker/linux

docker volume create "$cache_volume" >/dev/null
docker run --rm \
    --mount "type=volume,source=$cache_volume,target=/build" \
    "$image" chown "$(id -u):$(id -g)" /build

docker run --rm \
    --user "$(id -u):$(id -g)" \
    --env HOME=/tmp \
    --mount "type=bind,source=$daemon_repo_root,target=/src,readonly" \
    --mount "type=volume,source=$cache_volume,target=/build" \
    --mount "type=bind,source=$daemon_output_dir,target=/output" \
    "$image" \
    /bin/bash -ec "
        cmake \
            -S /src \
            -B /build \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=${cmake_build_type} \
            -DAU_OUTPUT_ROOT=/output
        cmake --build /build \
            --target ${target} \
            --parallel \"\$(nproc)\"
    "

printf 'Linux artifacts: %s/build/linux-%s\n' "$repo_root" "$config"
printf 'Linux cache volume: %s\n' "$cache_volume"
