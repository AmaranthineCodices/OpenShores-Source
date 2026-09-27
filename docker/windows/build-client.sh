#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
daemon_repo_root=$(bash "$repo_root/docker/resolve-project-mount.sh" "$repo_root")
image=${HAZERON_MINGW_IMAGE:-hazeron-mingw-qt5}
cache_volume=${HAZERON_WINDOWS_CACHE_VOLUME:-hazeron-windows-release-cache}
local_output_dir="$repo_root/build/windows-release"
daemon_output_dir="$daemon_repo_root/build/windows-release"
mkdir -p "$local_output_dir"

cd "$repo_root"

if ! docker image inspect "$image" >/dev/null 2>&1; then
    docker build \
        --tag "$image" \
        --file docker/windows/Dockerfile \
        docker/windows
fi

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
    /bin/bash -ec '
        package_dir=/output/bin
        qt_plugins="/opt/mxe/usr/${MXE_TARGET}/qt5/plugins"
        target_prefix="/opt/mxe/usr/${MXE_TARGET}"

        "${MXE_TARGET}-cmake" \
            -S /src \
            -B /build \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DAU_OUTPUT_ROOT=/output
        cmake --build /build \
            --target client \
            --parallel "$(nproc)"

        find "$package_dir" -maxdepth 1 -type f \
            -iname "*.dll" ! -iname "libAu*.dll" -delete
        rm -rf \
            "$package_dir/platforms" \
            "$package_dir/imageformats" \
            "$package_dir/styles" \
            "$package_dir/bearer"
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

printf 'Windows artifacts: %s/build/windows-release\n' "$repo_root"
printf 'Windows cache volume: %s\n' "$cache_volume"
