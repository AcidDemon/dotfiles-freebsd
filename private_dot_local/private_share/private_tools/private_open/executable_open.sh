#!/usr/bin/env bash
# Open a URL or the hosting page of the current git repo.

set -euo pipefail

exists() { command -v -- "$1" >/dev/null 2>&1; }

open_url() {
  if exists wslview && grep -qi microsoft /proc/version 2>/dev/null; then
    if wslview "$@"; then return 0; fi
  fi
  if exists xdg-open; then
    if xdg-open "$@"; then return 0; fi
  fi
  if exists gio; then
    if gio open "$@"; then return 0; fi
  fi
  if exists w3m; then
    if w3m "$@"; then return 0; fi
  fi
  if exists lynx; then
    if lynx "$@"; then return 0; fi
  fi
  if exists links; then
    if links "$@"; then return 0; fi
  fi
  printf 'Open this URL manually:\n%s\n' "$*" >&2
  return 127
}

to_https_url() {
  local u=$1 host path
  u=${u%.git}

  case "$u" in
  http://* | https://*)
    printf '%s\n' "$u"
    ;;
  git://*)
    printf '%s\n' "${u/git:\/\//https://}"
    ;;
  ssh://*)
    u=${u#ssh://}
    u=${u#*@}
    host=${u%%/*}
    host=${host%%:*} # an ssh port has no place in a browser URL
    path=${u#*/}
    printf 'https://%s/%s\n' "$host" "$path"
    ;;
  *@*:*)
    host=${u%%:*}
    host=${host#*@}
    path=${u#*:}
    printf 'https://%s/%s\n' "$host" "$path"
    ;;
  *)
    printf '%s\n' "$u"
    ;;
  esac
}

pick_remote() {
  local r
  for r in origin upstream; do
    if git remote get-url "$r" >/dev/null 2>&1; then
      printf '%s\n' "$r"
      return 0
    fi
  done
  git remote 2>/dev/null | head -n1
}

repo_homepage_url() {
  local remote url
  remote=$(pick_remote) || return 1
  [[ -n $remote ]] || return 1
  url=$(git remote get-url "$remote" 2>/dev/null) || return 1
  to_https_url "$url"
}

in_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

main() {
  if (($# > 0)); then
    open_url "$@"
    return
  fi

  if in_git_repo; then
    local url
    url=$(repo_homepage_url) || {
      printf 'Could not determine repo remote URL.\n' >&2
      exit 1
    }
    open_url "$url"
    return
  fi

  printf 'No arguments and not inside a git repository.\n' >&2
  exit 2
}

main "$@"
