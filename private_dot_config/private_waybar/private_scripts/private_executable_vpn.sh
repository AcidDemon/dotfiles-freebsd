#!/bin/sh
# Waybar custom module — WireGuard / Tailscale tunnel state.
set -u

C_WG="#f5e0dc"    # rosewater
C_TS="#a6e3a1"    # green
C_DOWN="#6c7086"  # overlay0
ICON="󰖂"

wg=""
ts_ip=""
for i in $(ifconfig -l 2>/dev/null); do
    case "$i" in
        wg*|tun*)
            if [ -z "$wg" ] && ifconfig "$i" 2>/dev/null | grep -q '^[[:space:]]*inet '; then
                wg="$i"
            fi
            ;;
        tailscale*)
            [ -n "$ts_ip" ] || ts_ip=$(ifconfig "$i" 2>/dev/null | awk '$1 == "inet" {print $2; exit}')
            ;;
    esac
done

# Span built here, not inline: FreeBSD /bin/sh drops the backslash in `\"`
# inside a single-quoted printf format, emitting quotes that break the JSON.
if [ -n "$wg" ]; then
    markup="<span size='130%' color='$C_WG'>$ICON</span>"
    printf '{"text":"%s %s","class":"up","tooltip":"WireGuard: %s"}\n' \
        "$markup" "$wg" "$wg"
elif [ -n "$ts_ip" ]; then
    markup="<span size='130%' color='$C_TS'>$ICON</span>"
    printf '{"text":"%s TS","class":"up","tooltip":"Tailscale: %s"}\n' \
        "$markup" "$ts_ip"
else
    # Must NOT emit empty text: custom/sep3 sits to the left of this module
    # and would be left dangling if this one hid itself. Dim icon instead.
    markup="<span size='130%' color='$C_DOWN'>$ICON</span>"
    printf '{"text":"%s","class":"down","tooltip":"no tunnel"}\n' "$markup"
fi
