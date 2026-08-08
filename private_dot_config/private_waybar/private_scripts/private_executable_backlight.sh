#!/bin/sh
# Waybar custom module — panel brightness via backlight(8).
# Called with up/down from on-scroll; refreshes the bar by signal.
set -u

C="#f9e2af"
STEP=5
SIG=4        # must match "signal" for custom/backlight in config.jsonc
RTMIN=65     # FreeBSD SIGRTMIN. pkill here rejects -RTMIN+N, numbers only.

# swayosd-client --brightness is Linux-only, so the level is pushed in as a
# generic progress bar instead.
osd() {
    c=$(backlight 2>/dev/null | awk '/[Bb]rightness/ {print $NF}' | tr -dc '0-9')
    [ -n "${c:-}" ] || return 0
    swayosd-client --custom-icon weather-clear-symbolic \
        --custom-progress "$(awk -v c="$c" 'BEGIN { printf "%.2f", c / 100 }')" \
        --custom-progress-text "$c%"
}

# Via ~/bin/brightness, not backlight(8) directly: `decr` walks the panel to 0.
case "${1:-}" in
    up)   "$HOME/bin/brightness" up   "$STEP" >/dev/null 2>&1; osd; pkill -$((RTMIN + SIG)) waybar; exit 0 ;;
    down) "$HOME/bin/brightness" down "$STEP" >/dev/null 2>&1; osd; pkill -$((RTMIN + SIG)) waybar; exit 0 ;;
esac

cur=$(backlight 2>/dev/null | awk '/[Bb]rightness/ {print $NF}' | tr -dc '0-9')
[ -n "${cur:-}" ] || exit 0

if   [ "$cur" -ge 67 ]; then icon="󰃠"
elif [ "$cur" -ge 34 ]; then icon="󰃟"
else                         icon="󰃞"
fi

# Span built here, not inline: FreeBSD /bin/sh drops the backslash in `\"`
# inside a single-quoted printf format, emitting quotes that break the JSON.
markup="<span size='130%' color='$C'>$icon</span>"

printf '{"text":"%s %s%%","class":"backlight","tooltip":"brightness %s%%"}\n' \
    "$markup" "$cur" "$cur"
