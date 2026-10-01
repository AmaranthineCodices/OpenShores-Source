#!/bin/sh
# Runs one standings refresh from the web image.
set -eu

reports=/var/lib/openshores/reports
mkdir -p "$reports/standings"
# Serialize manual refreshes as well as startup generation.
exec 9>"$reports/.standings.lock"
flock -n 9 || { echo 'Standings generation is already running.' >&2; exit 1; }

staging=$(mktemp -d "$reports/.standings.XXXXXX")
trap 'rm -rf -- "$staging"' EXIT
trap 'exit 1' HUP INT TERM
cd "$staging"

timeout --foreground --kill-after=5s 300s /opt/openshores/bin/AuEmpireReport -standings > index.html
test -s index.html
# Publish images first, then atomically replace the page. A failed generation
# leaves the previous published report available.
for flag in ./*.png; do
    [ -f "$flag" ] || continue
    chmod 0644 "$flag"
    mv -f "$flag" "$reports/standings/"
done
chmod 0644 index.html
mv -f index.html "$reports/standings/index.html"
echo 'Empire standings published.'
