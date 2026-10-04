#!/bin/sh
# Waybar custom module — WiFi signal strength, SSID in the tooltip.
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
NOISE_FLOOR=-96   # dBm

# Mocha
C_OK="#74c7ec"    # sapphire
C_DOWN="#6c7086"  # overlay0

I4="󰤨"; I3="󰤥"; I2="󰤢"; I1="󰤟"; IOFF="󰤭"

emit() { printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$1" "$2" "$3"; }
esc()  { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/&/\&amp;/g' -e 's/</\&lt;/g'; }

down() {
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

# waybar's network module: 100% at -45 dBm, 0% at 45 dB either side.
d=$(( dbm + 45 ))
[ "$d" -lt 0 ] && d=$(( -d ))
pct=$(( (4500 - d * 100) / 45 ))
[ "$pct" -lt 0 ] && pct=0

if   [ "$pct" -ge 75 ]; then icon=$I4
elif [ "$pct" -ge 50 ]; then icon=$I3
elif [ "$pct" -ge 25 ]; then icon=$I2
else                         icon=$I1
fi

ssid_esc=$(printf '%s' "${ssid:-unknown}" | esc)
tip=$(printf 'SSID  %s\\nBSSID %s\\nSignal %s dBm (raw %s)\\nIP    %s\\nIface %s' \
      "$ssid_esc" "${bssid:-?}" "$dbm" "${raw:-?}" "${addr:-none}" "$IFACE")

emit "<span size='130%' color='$C_OK'>$icon</span> $pct%" wifi "$tip"
