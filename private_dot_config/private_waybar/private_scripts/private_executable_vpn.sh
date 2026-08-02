#!/bin/sh
# Waybar custom module — WireGuard tunnel state.
set -u

C_UP="#f5e0dc"    # rosewater (teal is the battery accent now)
C_DOWN="#6c7086"  # overlay0
ICON="󰖂"

up=""
for i in $(ifconfig -l 2>/dev/null); do
    case "$i" in
        wg*|tun*)
            if ifconfig "$i" 2>/dev/null | grep -q '^[[:space:]]*inet '; then
                up="${up:+$up }$i"
            fi
            ;;
    esac
done

# Span built here, not inline: FreeBSD /bin/sh drops the backslash in `\"`
# inside a single-quoted printf format, emitting quotes that break the JSON.
if [ -n "$up" ]; then
    markup="<span size='130%' color='$C_UP'>$ICON</span>"
    printf '{"text":"%s %s","class":"up","tooltip":"tunnel up: %s"}\n' \
        "$markup" "${up%% *}" "$up"
else
    # Must NOT emit empty text: custom/sep3 sits to the left of this module
    # and would be left dangling if this one hid itself. Dim icon instead.
    markup="<span size='130%' color='$C_DOWN'>$ICON</span>"
    printf '{"text":"%s","class":"down","tooltip":"no tunnel"}\n' "$markup"
fi
