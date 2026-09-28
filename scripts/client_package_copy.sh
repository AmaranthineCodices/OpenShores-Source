#!/usr/bin/env bash
set -euo pipefail

# Script to easily copy a Windows client build from WSL over to the Windows host

source_dir="$PWD/../build/packages"

if [[ ! -d "$source_dir" ]]; then
    echo "Error: $source_dir does not exist." >&2
    exit 1
fi

if [[ ! -f "$source_dir/soh-win64.zip" ]]; then
    echo "Error: $source_dir/soh-win64.zip does not exist." >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required to extract the client package." >&2
    exit 1
fi

read -r -p "(WSL ONLY!) Destination under /mnt/c/ (e.g. Users/Username/Desktop/HazeronClient): " destination

if [[ -z "$destination" ]]; then
    echo "Cancelled."
    exit 0
fi

# Accept either a full /mnt/c/ path or a path relative to it.
if [[ "$destination" != /* ]]; then
    destination="/mnt/c/$destination"
fi

destination=$(realpath -m -- "$destination")
source_dir=$(realpath -- "$source_dir")

case "$destination" in
    /mnt/c/*) ;;
    *)
        echo "Error: destination must be inside /mnt/c/." >&2
        exit 1
        ;;
esac

if [[ "$destination" == "$source_dir" || "$destination" == "$source_dir/"* ]]; then
    echo "Error: destination cannot be the source or inside it." >&2
    exit 1
fi

for folder in soh-win64 OpenShores; do
    if [[ -e "$destination/$folder" || -L "$destination/$folder" ]]; then
        echo "Error: $destination/$folder already exists." >&2
        exit 1
    fi
done

mkdir -p -- "$destination"
cp -a -- "$source_dir/." "$destination"

printf 'Copied packages to: %s\n' "$destination"

python3 -m zipfile -e "$destination/soh-win64.zip" "$destination"
mv -T -- "$destination/soh-win64" "$destination/OpenShores"

printf 'Extracted client to: %s\n' "$destination/OpenShores"
