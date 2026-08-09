#!/usr/bin/env bash
set -euo pipefail

rawurlencode() {
    local s=${1-} out="" c hex
    local LC_ALL=C

    # -d '' keeps newlines in $c; the default delimiter would strip them to ""
    # and encode every one as %00.
    while IFS= read -r -d '' -n1 c; do
        case $c in
        [a-zA-Z0-9.~_-]) out+=$c ;;
        *)
            printf -v hex '%%%02X' "'$c"
            out+=$hex
            ;;
        esac
    done < <(printf %s "$s")

    printf '%s\n' "$out"
}

if (($#)); then
    rawurlencode "$*"
    exit 0
fi

while IFS= read -r line || [[ -n ${line-} ]]; do
    rawurlencode "$line"
done
