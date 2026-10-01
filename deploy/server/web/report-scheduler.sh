#!/usr/bin/env bash
# Run one report repeatedly, or once for a manual refresh.
set -euo pipefail

case "${1:-}" in
    standings) generator=/opt/openshores/bin/generate-standings ;;
    avatars) generator=/opt/openshores/bin/generate-avatars ;;
    *) echo 'usage: report-scheduler standings|avatars [--once]' >&2; exit 2 ;;
esac
report=$1
if (($# == 2)) && [[ $2 == --once ]]; then
    exec "$generator"
fi
if (($# != 1)); then
    echo 'usage: report-scheduler standings|avatars [--once]' >&2
    exit 2
fi

minutes=${REPORT_INTERVAL_MINUTES:-20}
if [[ ! $minutes =~ ^[1-9][0-9]{0,5}$ ]] || ((minutes > 525600)); then
    echo 'REPORT_INTERVAL_MINUTES must be an integer between 1 and 525600.' >&2
    exit 2
fi
seconds=$((minutes * 60))
child_pid=

stop() {
    trap '' TERM INT
    if [[ -n $child_pid ]]; then
        # Each job has its own process group, including the report executable.
        kill -TERM -- "-$child_pid" 2>/dev/null || kill -TERM "$child_pid" 2>/dev/null || true
        wait "$child_pid" 2>/dev/null || true
    fi
    exit 0
}
trap stop TERM INT

while true; do
    echo "Generating $report report."
    setsid "$generator" &
    child_pid=$!
    if wait "$child_pid"; then
        echo "$report report refresh succeeded."
    else
        result=$?
        echo "$report report refresh failed (exit $result); retrying after $minutes minutes." >&2
    fi
    child_pid=
    echo "Next $report refresh in $minutes minutes."
    setsid sleep "$seconds" &
    child_pid=$!
    wait "$child_pid"
    child_pid=
done
