#!/bin/sh
# Waybar custom module — CPU temperature.
#
# PREFERRED: amdtemp gives the Zen die temperature (Tctl) directly.
#     kldload amdtemp && sysctl dev.amdtemp
#   persist with:  amdtemp_load="YES"  in /boot/loader.conf
#
# FALLBACK: an ACPI thermal zone, used only if amdtemp is absent.
# tz0 is the CPU zone on this machine — confirmed against amdtemp
# (tz0 87.1C vs amdtemp 88.7C at the same moment). The others are
# other components; tz5 reads -273.1C (0 K = unpopulated sentinel)
# and is rejected by the range check below.
#
# THRESHOLDS: Zen 3 mobile boosts to its thermal ceiling by design.
# Tjmax is ~105C, so high-80s under load is normal, not a fault.
# Warning/critical are set accordingly — thresholds low enough to
# trip during ordinary boost would make the colour meaningless.
set -u

C_OK="#fab387"; C_WARN="#f9e2af"; C_CRIT="#f38ba8"
ICON="󰔏"

SENSORS="dev.amdtemp.0.core0.sensor0
dev.amdtemp.0.ccd0
dev.cpu.0.temperature
hw.acpi.thermal.tz0.temperature"

t=""
for k in $SENSORS; do
    raw=$(sysctl -n "$k" 2>/dev/null) || continue
    [ -n "$raw" ] || continue
    v=${raw%C}; v=${v%%.*}
    case "$v" in ''|*[!0-9-]*) continue ;; esac
    # Reject sentinels: -273.1C is 0 K (unpopulated), >150C is nonsense
    [ "$v" -lt 0 ]   && continue
    [ "$v" -gt 150 ] && continue
    t=$v; src=$k; break
done
[ -n "$t" ] || exit 0

if   [ "$t" -ge 97 ]; then cls=critical; col=$C_CRIT
elif [ "$t" -ge 88 ]; then cls=warning;  col=$C_WARN
else                       cls=good;     col=$C_OK
fi

# ── tooltip: every sensor worth reading ──────────────────────────────
#
# ACPI exposes no friendly name for a thermal zone — `sysctl -d` returns
# the same generic string for all of them — so anything beyond "zone N"
# would be invented. Only tz0 is labelled, because it was actually
# verified against amdtemp (see the header). The rest are listed with
# their reading and left unnamed on purpose.

tip="CPU die (Tctl)   ${t}°C"

# Per-core sysctls all mirror the same die sensor on Zen, so report the
# spread rather than 12 identical lines.
cores=$(sysctl -n dev.cpu.0.temperature 2>/dev/null | tr -d 'C')
[ -n "${cores:-}" ] && tip=$(printf '%s\\ndev.cpu.*        %s°C' "$tip" "$cores")

tip=$(printf '%s\\n\\nACPI thermal zones' "$tip")
for i in 0 1 2 3 4 5 6 7; do
    raw=$(sysctl -n "hw.acpi.thermal.tz$i.temperature" 2>/dev/null) || continue
    [ -n "$raw" ] || continue
    v=${raw%C}; whole=${v%%.*}
    case "$whole" in ''|*[!0-9-]*) continue ;; esac
    # -273.1C is 0 K, the sentinel for an unpopulated zone
    [ "$whole" -lt 0 ] && continue

    psv=$(sysctl -n "hw.acpi.thermal.tz$i._PSV" 2>/dev/null)
    case "$psv" in -1|'') trip="" ;; *) trip=$(printf '   passive at %s' "$psv") ;; esac

    case "$i" in
        0) label="zone 0 (tracks CPU)" ;;
        *) label="zone $i" ;;
    esac
    tip=$(printf '%s\\n  %-20s %6s%s' "$tip" "$label" "$v" "$trip")
done

tip=$(printf '%s\\n\\nreading from %s\\nwarn at 88°C, critical at 97°C (Tjmax ~105°C)' "$tip" "$src")

# Span built here, not inline: FreeBSD /bin/sh drops the backslash in `\"`
# inside a single-quoted printf format, emitting quotes that break the JSON.
markup="<span size='130%' color='$col'>$ICON</span>"

printf '{"text":"%s %s°","class":"%s","tooltip":"%s"}\n' \
    "$markup" "$t" "$cls" "$tip"
