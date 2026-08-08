#!/bin/sh
set -eu

playerctl status >/dev/null 2>&1 || exit 0

case "${1:-}" in
    prev)   printf '󰒮' ;;
    next)   printf '󰒭' ;;
    toggle)
        if [ "$(playerctl status 2>/dev/null)" = "Playing" ]; then
            printf '󰏤'
        else
            printf '󰐊'
        fi
        ;;
    *) exit 1 ;;
esac
