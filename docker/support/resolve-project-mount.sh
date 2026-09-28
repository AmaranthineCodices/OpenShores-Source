#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 PROJECT_DIRECTORY" >&2
    exit 2
fi

project_dir=$(cd "$1" && pwd -P)

# Bind sources belong to the Docker daemon's filesystem. When this script runs
# inside a container, translate the project path through the current
# container's mount table so a sibling build container can mount the same tree.
container_ref=${HOSTNAME:-}
if [[ -z "$container_ref" ]] || ! docker inspect "$container_ref" >/dev/null 2>&1; then
    printf '%s\n' "$project_dir"
    exit 0
fi

best_source=
best_destination=
best_type=
while IFS='|' read -r source destination mount_type; do
    [[ -n "$destination" ]] || continue
    case "$project_dir" in
        "$destination"|"$destination"/*)
            if (( ${#destination} > ${#best_destination} )); then
                best_source=$source
                best_destination=$destination
                best_type=$mount_type
            fi
            ;;
    esac
done < <(docker inspect "$container_ref" \
    --format '{{range .Mounts}}{{printf "%s|%s|%s\n" .Source .Destination .Type}}{{end}}')

if [[ -z "$best_source" ]]; then
    printf '%s\n' "$project_dir"
    exit 0
fi

if [[ "$best_type" != bind ]]; then
    echo "error: project path is backed by a Docker $best_type, not a host bind mount" >&2
    exit 1
fi

printf '%s%s\n' "$best_source" "${project_dir#"$best_destination"}"
