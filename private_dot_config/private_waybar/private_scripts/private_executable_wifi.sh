#!/bin/sh
# Waybar custom module — WiFi SSID with signal strength in the icon.
# FreeBSD: parses ifconfig(8); no netlink, no /sys.
#
# RSSI CONVENTION
#   net80211 reports RSSI in dB above the noise floor, so
#   `ifconfig wlanN list sta` prints a POSITIVE number (e.g. 53.0).
#   Some drivers instead report absolute dBm (negative). Both are
#   normalised to dBm below before thresholding, so this works either
#   way. Tune NOISE_FLOOR if your radio's floor differs — you can read
#   the real one from the S:N column of `ifconfig wlanN list scan`.
set -u

IFACE="${1:-wlan0}"
# MODE selects which half of the readout to emit, so the two halves can be
# separate waybar modules and therefore a drawer: the icon is always on
# screen, the SSID slides out on hover. "full" keeps the old behaviour.
MODE="${2:-full}"
NOISE_FLOOR=-96   # dBm

# Mocha
C_OK="#74c7ec"    # sapphire
C_WEAK="#fab387"  # peach
C_DOWN="#6c7086"  # overlay0

I4="󰤨"; I3="󰤥"; I2="󰤢"; I1="󰤟"; IOFF="󰤮"

emit() { printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$1" "$2" "$3"; }
esc()  { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/&/\&amp;/g' -e 's/</\&lt;/g'; }

# In "ssid" mode a down link has no name to show, so emit empty text and
# let waybar hide the module — the icon half already says it is down.
down() {
    [ "$MODE" = "ssid" ] && { emit "" disconnected "$1"; exit 0; }
    emit "<span size='130%' color='$C_DOWN'>$IOFF</span>" disconnected "$1"
    exit 0
}

info=$(ifconfig "$IFACE" 2>/dev/null) || down "$IFACE not present"

case "$info" in
    *"status: associated"*) ;;
    *)  down "not associated" ;;
esac

ssid=$(printf '%s\n' "$info" | sed -n 's/^[[:space:]]*ssid \(.*\) channel .*/\1/p' | head -1)
bssid=$(printf '%s\n' "$info" | sed -n 's/.*bssid \([0-9a-fA-F:]*\).*/\1/p' | head -1)
addr=$(printf '%s\n' "$info" | awk '/^[[:space:]]*inet /{print $2; exit}')

# list sta: row 2 is the associated AP; column 5 is RSSI
raw=$(ifconfig "$IFACE" list sta 2>/dev/null | awk 'NR==2 {print $5; exit}')
rssi=${raw%%.*}
case "${rssi:-}" in
    ''|*[!0-9-]*) rssi="" ;;
esac

if [ -z "$rssi" ]; then
    dbm=-99
elif [ "$rssi" -lt 0 ]; then
    dbm=$rssi                        # already absolute dBm
else
    dbm=$(( NOISE_FLOOR + rssi ))    # dB above noise -> dBm
fi

if   [ "$dbm" -ge -55 ]; then icon=$I4; cls=good;     col=$C_OK
elif [ "$dbm" -ge -65 ]; then icon=$I3; cls=good;     col=$C_OK
elif [ "$dbm" -ge -72 ]; then icon=$I2; cls=warning;  col=$C_WEAK
else                          icon=$I1; cls=degraded; col=$C_WEAK
fi

ssid_esc=$(printf '%s' "${ssid:-unknown}" | esc)
tip=$(printf 'SSID  %s\\nBSSID %s\\nSignal %s dBm (raw %s)\\nIP    %s\\nIface %s' \
      "$ssid_esc" "${bssid:-?}" "$dbm" "${raw:-?}" "${addr:-none}" "$IFACE")

case "$MODE" in
    icon) emit "<span size='130%' color='$col'>$icon</span>" "$cls" "$tip" ;;
    ssid) emit "$ssid_esc" "$cls" "$tip" ;;
    *)    emit "<span size='130%' color='$col'>$icon</span> $ssid_esc" "$cls" "$tip" ;;
esac
