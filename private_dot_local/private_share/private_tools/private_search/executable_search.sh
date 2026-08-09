#!/usr/bin/env bash
set -euo pipefail

engine="startpage"
searxng=${SEARCH_SEARXNG_URL:-https://search.inviziblenet.work/search?q=}

while (($#)); do
    case "$1" in
    -d | --duck)
        engine="duck"
        shift
        ;;
    -g | --google)
        engine="google"
        shift
        ;;
    -s | --startpage)
        engine="startpage"
        shift
        ;;
    -b | --bing)
        engine="bing"
        shift
        ;;
    -q | --qwant)
        engine="qwant"
        shift
        ;;
    -x | --searxng)
        engine="searxng"
        shift
        ;;
    -h | --help)
        cat <<EOF
Usage: ${0##*/} [-d|-g|-s|-b|-q|-x] <search terms...>
  -d, --duck        Search with DuckDuckGo
  -g, --google      Search with Google
  -s, --startpage   Search with Startpage (default)
  -b, --bing        Search with Bing
  -q, --qwant       Search with Qwant
  -x, --searxng     Search with SearXNG (\$SEARCH_SEARXNG_URL to override)
EOF
        exit 0
        ;;
    *) break ;;
    esac
done

if (($# == 0)); then
    echo "Error: no search terms provided." >&2
    exit 2
fi

query=$(urlencode "$*")

case "$engine" in
duck) url="https://duckduckgo.com/?q=$query" ;;
google) url="https://www.google.com/search?q=$query" ;;
startpage) url="https://www.startpage.com/do/search?q=$query" ;;
bing) url="https://www.bing.com/search?q=$query" ;;
qwant) url="https://www.qwant.com/?q=$query" ;;
searxng) url="${searxng}${query}" ;;
esac

open "$url"
