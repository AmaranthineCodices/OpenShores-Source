#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 release|debug|relwithdebinfo" >&2
    exit 2
fi

config=$1
case "$config" in
    release|debug|relwithdebinfo) ;;
    *) echo "error: unsupported build configuration: $config" >&2; exit 2 ;;
esac

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
output="$repo_root/build/linux-$config"
stage="$output/package-stage"
packages="$repo_root/build/packages"
game_name=soh-linux-x64
launcher_name=soh-launcher-linux-x64
game="$stage/$game_name"
launcher="$stage/$launcher_name"

require_file() {
    if [[ ! -f "$1" ]]; then
        echo "error: required package input is missing: $1" >&2
        exit 1
    fi
}

for file in AuSceneClient AuChatClient AuMailClient AuLauncher GD sfx.har; do
    require_file "$output/bin/$file"
done
for directory in tex Blueprints/Buildings Blueprints/Spacecraft; do
    if [[ ! -d "$output/bin/$directory" ]]; then
        echo "error: required client runtime directory is missing: $output/bin/$directory" >&2
        exit 1
    fi
done

rm -rf "$stage"
mkdir -p "$game/bin" "$game/lib" "$launcher/bin" "$launcher/lib" "$packages"

install -m 755 "$output/bin/AuSceneClient" "$game/bin/ShoresOfHazeron"
install -m 755 "$output/bin/AuChatClient" "$game/bin/HazeronCommander"
install -m 755 "$output/bin/AuMailClient" "$game/bin/HazeronMail"
install -m 644 "$output/bin/GD" "$game/bin/GD"
install -m 644 "$output/bin/sfx.har" "$game/bin/sfx.har"
cp -a "$output/bin/tex" "$game/bin/tex"

cp -a "$output/bin/Blueprints" "$game/bin/Blueprints"

# Package only project libraries imported by the clients. System Qt, SDL,
# OpenAL, and OpenGL libraries remain distribution-provided dependencies.
mapfile -t project_libraries < <(
    for executable in AuSceneClient AuChatClient AuMailClient; do
        readelf -d "$output/bin/$executable"
    done \
        | sed -n 's/.*Shared library: \[\(libAu[^]]*\)\].*/\1/p' \
        | sort -u
)
for library in "${project_libraries[@]}"; do
    require_file "$output/lib/$library"
    cp -L --preserve=mode,timestamps "$output/lib/$library" "$game/lib/$library"
done

install -m 755 "$output/bin/AuLauncher" "$launcher/bin/HazeronLauncher"
printf '%s\n' "$game_name" > "$launcher/bin/data.bin"

write_manifest() {
    local root=$1
    (
        cd "$root"
        find . -type f ! -name md5sums -print0 \
            | sort -z \
            | xargs -0 md5sum > md5sums
    )
}
write_manifest "$game"
write_manifest "$launcher"

rm -f "$packages/$game_name.tar.gz" "$packages/$launcher_name.tar.gz"
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    -C "$stage" -czf "$packages/$game_name.tar.gz" "$game_name"
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    -C "$stage" -czf "$packages/$launcher_name.tar.gz" "$launcher_name"
(
    cd "$packages"
    sha256sum \
        "$game_name.tar.gz" \
        "$launcher_name.tar.gz" \
        > linux-x64.sha256
)

printf 'Linux game package: %s\n' "$packages/$game_name.tar.gz"
printf 'Linux launcher package: %s\n' "$packages/$launcher_name.tar.gz"
