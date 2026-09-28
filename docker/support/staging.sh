#!/usr/bin/env bash
# Source this helper in a script that owns one temporary staging directory.

create_staging_directory() {
    local parent=$1
    local prefix=$2
    mkdir -p -- "$parent"
    staging_dir=$(mktemp -d "$parent/$prefix.XXXXXX")
    trap cleanup_staging_directory EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
}

cleanup_staging_directory() {
    local status=$?
    if [[ ${HAZERON_KEEP_STAGING:-0} == 1 ]]; then
        printf 'Retained staging directory: %s\n' "$staging_dir" >&2
    else
        rm -rf -- "$staging_dir"
    fi
    return "$status"
}
