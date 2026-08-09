#!/usr/bin/env bash
# Paste stdin or files to a paste service and print/copy the URL.
# Usage:
#   px.sh                     # read stdin
#   px.sh file1 [file2 ...]   # upload concatenated files
#   px.sh -s ixio < file      # force service
#   px.sh -g ID               # fetch ix.io paste by ID and print

set -Eeuo pipefail

SERVICE="" # auto by default: ixio, then 0x0, then termbin
TIMEOUT=20
CLIP=1

exists() { command -v -- "$1" >/dev/null 2>&1; }

copy_clip() {
  local text=$1
  if ((CLIP == 0)); then return 0; fi
  if exists yank; then printf %s "$text" | yank && return 0; fi
  if exists wl-copy; then printf %s "$text" | wl-copy && return 0; fi
  if exists xclip; then printf %s "$text" | xclip -selection clipboard && return 0; fi
  if exists xsel; then printf %s "$text" | xsel --clipboard --input && return 0; fi
  if exists pbcopy; then printf %s "$text" | pbcopy && return 0; fi
  if exists clip.exe; then printf %s "$text" | clip.exe && return 0; fi
  if exists termux-clipboard-set; then printf %s "$text" | termux-clipboard-set && return 0; fi
  return 1
}

post_ixio() {
  curl -fsS --max-time "$TIMEOUT" -F 'f:1=<-' https://ix.io
}
get_ixio() {
  curl -fsS --max-time "$TIMEOUT" "https://ix.io/$1"
}

post_0x0() {
  local name=${1:-stdin.txt}
  curl -fsS --max-time "$TIMEOUT" -F "file=@-;filename=${name}" https://0x0.st
}

post_termbin() {
  nc termbin.com 9999
}

usage() {
  cat <<EOF
Usage: ${0##*/} [options] [file ...]
  -s, --service  ixio|0x0|termbin   Force service (default: auto)
  -g, --get ID                       Get ix.io paste by ID
  -t, --timeout SECONDS              Curl/net timeout (default: $TIMEOUT)
      --no-clip                      Do not copy URL to clipboard
  -h, --help                         Show this help
EOF
}

needs_value() {
  if (($1 < 2)); then
    echo "px: $2 needs a value" >&2
    usage >&2
    exit 2
  fi
}

GET_ID=""
FILES=()
while (($#)); do
  case "$1" in
  -s | --service)
    needs_value $# "$1"
    SERVICE=$2
    shift 2
    ;;
  -g | --get)
    needs_value $# "$1"
    GET_ID=$2
    shift 2
    ;;
  -t | --timeout)
    needs_value $# "$1"
    TIMEOUT=$2
    shift 2
    ;;
  --no-clip)
    CLIP=0
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --)
    shift
    FILES+=("$@")
    break
    ;;
  -*)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
  *)
    FILES+=("$1")
    shift
    ;;
  esac
done

if [[ -n "$GET_ID" ]]; then
  get_ixio "$GET_ID"
  exit $?
fi

tmp=$(mktemp)
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

if ((${#FILES[@]})); then
  cat -- "${FILES[@]}" >"$tmp"
elif [[ ! -t 0 ]]; then
  cat >"$tmp"
else
  usage >&2
  exit 2
fi

name="paste.txt"
[[ ${#FILES[@]} -gt 0 ]] && name="${FILES[0]##*/}"

upload_auto() {
  post_ixio <"$tmp" && return 0
  post_0x0 "$name" <"$tmp" && return 0
  if exists nc; then post_termbin <"$tmp" && return 0; fi
  return 1
}

case "$SERVICE" in
"") url=$(upload_auto) || {
  echo "Upload failed on all services." >&2
  exit 1
} ;;
ixio) url=$(post_ixio <"$tmp") || {
  echo "ix.io upload failed." >&2
  exit 1
} ;;
0x0) url=$(post_0x0 "$name" <"$tmp") || {
  echo "0x0.st upload failed." >&2
  exit 1
} ;;
termbin)
  exists nc || {
    echo "termbin requires 'nc'." >&2
    exit 1
  }
  url=$(post_termbin <"$tmp") || {
    echo "termbin upload failed." >&2
    exit 1
  }
  ;;
*)
  echo "Unknown service: $SERVICE" >&2
  exit 2
  ;;
esac

printf '%s\n' "$url"
copy_clip "$url" >/dev/null 2>&1 || true
