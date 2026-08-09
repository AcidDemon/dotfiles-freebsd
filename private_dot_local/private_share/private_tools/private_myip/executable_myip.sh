#!/usr/bin/env bash
set -euo pipefail

resolver=${MYIP_RESOLVER:-resolver1.opendns.com}
name=myip.opendns.com

usage() { echo "Usage: myip [-4|--ipv4] [-6|--ipv6]"; }

# dig on NixOS, drill in the FreeBSD base system
if command -v dig >/dev/null 2>&1; then
  DNS=dig
elif command -v drill >/dev/null 2>&1; then
  DNS=drill
else
  echo "myip: need dig or drill" >&2
  exit 1
fi

query() {
  case $DNS in
  dig) dig "$1" +short +time=2 +tries=1 "$2" "$3" @"$4" ;;
  drill) drill "$1" -Q "$2" "$3" @"$4" ;;
  esac
}

# an empty answer still exits 0, so test the output rather than the status
lookup() {
  local family=$1 type=$2 out
  out=$(query "$family" "$type" "$name" "$resolver") || out=""
  if [[ -z $out ]]; then
    out=$(query "$family" TXT o-o.myaddr.l.google.com ns1.google.com | tr -d '"') || out=""
  fi
  if [[ -z $out ]]; then
    echo "myip: no answer" >&2
    return 1
  fi
  printf '%s\n' "$out"
}

case "${1-}" in
-6 | --ipv6) lookup -6 AAAA ;;
-4 | --ipv4 | "") lookup -4 A ;;
-h | --help)
  usage
  exit 0
  ;;
*)
  usage >&2
  exit 2
  ;;
esac
