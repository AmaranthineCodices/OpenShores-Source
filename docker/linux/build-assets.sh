#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
daemon_repo_root=$(bash "$repo_root/docker/support/resolve-project-mount.sh" "$repo_root")
image=${HAZERON_LINUX_IMAGE:-hazeron-linux-qt5}
cache_volume=${HAZERON_ASSETS_CACHE_VOLUME:-hazeron-assets-cache}
assets_dir="$repo_root/build/assets"
daemon_assets_dir="$daemon_repo_root/build/assets"
archive="$assets_dir/sfx.har"
stamp="$assets_dir/sfx.inputs.sha256"

mkdir -p "$assets_dir"

input_digest=$(
    cd "$repo_root"
    {
        find resources/audio/source -maxdepth 1 -type f -name '*.wav' -print0 \
            | sort -z \
            | xargs -0 sha256sum
        sha256sum \
            src/tools/hashpack/main.cpp \
            src/tools/hashpack/hashpack.h \
            src/lib/util/hashpack.h \
            CMakeLists.txt \
            cmake/AuTargets.cmake \
            docker/linux/Dockerfile
    } | sha256sum | awk '{print $1}'
)

if [[ -s "$archive" && -f "$stamp" ]] \
        && [[ $(<"$stamp") == "$input_digest" ]]; then
    printf 'Client assets are up to date: %s\n' "$archive"
    exit 0
fi

if ! docker image inspect "$image" >/dev/null 2>&1; then
    docker build \
        --tag "$image" \
        --target toolchain \
        --file "$repo_root/docker/linux/Dockerfile" \
        "$repo_root/docker/linux"
fi

docker volume create "$cache_volume" >/dev/null
docker run --rm \
    --mount "type=volume,source=$cache_volume,target=/build" \
    "$image" chown "$(id -u):$(id -g)" /build

docker run --rm \
    --user "$(id -u):$(id -g)" \
    --env HOME=/tmp \
    --env QT_HASH_SEED=0 \
    --mount "type=bind,source=$daemon_repo_root,target=/src,readonly" \
    --mount "type=bind,source=$daemon_assets_dir,target=/assets" \
    --mount "type=volume,source=$cache_volume,target=/build" \
    "$image" \
    /bin/bash -ec '
        cmake \
            -S /src \
            -B /build \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DAU_OUTPUT_ROOT=/build/output
        cmake --build /build --target hashpack --parallel "$(nproc)"
        cd /src/resources/audio/source
        rm -f /assets/sfx.har.tmp
        /build/output/bin/hashpack -c /assets/sfx.har.tmp "*.wav"
        test -s /assets/sfx.har.tmp
        mv /assets/sfx.har.tmp /assets/sfx.har
    '

printf '%s\n' "$input_digest" > "$stamp"
printf 'Generated client sound archive: %s\n' "$archive"
