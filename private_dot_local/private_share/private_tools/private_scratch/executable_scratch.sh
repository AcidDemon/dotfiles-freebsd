#!/usr/bin/env bash
set -euo pipefail

: "${NOTES:?NOTES environment variable not set}"
: "${EDITOR:?EDITOR environment variable not set}"

file="${NOTES}/scratchpad/scratchpad.md"
mkdir -p -- "$(dirname -- "$file")"

exec "$EDITOR" "$file"
