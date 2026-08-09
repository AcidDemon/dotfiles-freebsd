#!/usr/bin/env bash
set -euo pipefail

copy() {
  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  elif command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  else
    echo "error: no clipboard tool found (install wl-clipboard, xclip, or pbcopy)" >&2
    exit 1
  fi
}

usage() { echo "usage: ${0##*/} [-f FILE | text ...]   with no arguments, reads stdin" >&2; }

if (($# == 0)); then
  if [[ -t 0 ]]; then
    usage
    exit 2
  fi
  copy
  exit 0
fi

case $1 in
-h | --help)
  usage
  exit 0
  ;;
-f | --file)
  if [[ -z ${2-} ]]; then
    usage
    exit 2
  fi
  copy <"$2"
  ;;
*)
  printf '%s' "$*" | copy
  ;;
esac
