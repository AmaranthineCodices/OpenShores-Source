#!/bin/sh
# Runs one avatar refresh from the web image.
set -eu

reports=/var/lib/openshores/reports
mkdir -p "$reports/avatars"
exec 9>"$reports/.avatars.lock"
flock -n 9 || { echo 'Avatar report generation is already running.' >&2; exit 1; }

staging=$(mktemp -d "$reports/.avatars.XXXXXX")
trap 'rm -rf -- "$staging"' EXIT
trap 'exit 1' HUP INT TERM
cd "$staging"

timeout --foreground --kill-after=5s 300s /opt/openshores/bin/AuEmpireReport -avatars
test -s Avatars.html
test -s AvatarsByEmpire.html

# Remove obsolete profiles and pictures only after successful generation.
# This directory is owned exclusively by the avatar report generator.
for previous in "$reports/avatars/"*.html "$reports/avatars/"*.png; do
    [ -f "$previous" ] || continue
    if [ ! -f "./${previous##*/}" ]; then
        rm -f -- "$previous"
    fi
done

# Publish pictures and profiles before replacing the directory pages.
for asset in ./*.png ./p*.html; do
    [ -f "$asset" ] || continue
    chmod 0644 "$asset"
    mv -f "$asset" "$reports/avatars/"
done
chmod 0644 AvatarsByEmpire.html Avatars.html
mv -f AvatarsByEmpire.html "$reports/avatars/AvatarsByEmpire.html"
mv -f Avatars.html "$reports/avatars/Avatars.html"
echo 'Avatar reports published.'
