#!/usr/bin/env bash
set -euo pipefail

if (($# == 0)); then
    echo "usage: health-port PORT [PORT ...]" >&2
    exit 2
fi

for port in "$@"; do
    if ! [[ "$port" =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
        echo "invalid port: $port" >&2
        exit 2
    fi

    hex_port=$(printf '%04X' "$port")
    if ! grep -Eqs ":${hex_port}[[:space:]].*[[:space:]]0A[[:space:]]" \
        /proc/net/tcp /proc/net/tcp6; then
        exit 1
    fi
done
