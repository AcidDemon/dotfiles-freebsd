#!/usr/bin/env bash
set -euo pipefail

base="https://cht.sh"
ua="curl/cht.sh-helper"

if (($# == 0)); then
  if [[ -t 0 ]]; then
    printf 'cheat: need at least a topic (e.g. "cheat tar" or "cheat go for range")\n' >&2
    exit 2
  fi
  # || true so a final line without a trailing newline still counts
  IFS= read -r line || true
  if [[ -z ${line-} ]]; then
    printf 'cheat: empty input\n' >&2
    exit 2
  fi
  url="${base}/$(urlencode "$line")"
elif (($# == 1)); then
  url="${base}/$(urlencode "$1")"
else
  topic=$1
  shift
  url="${base}/$(urlencode "$topic")/$(urlencode "$*")"
fi

curl -fsSL --compressed -H "User-Agent: ${ua}" "$url"
