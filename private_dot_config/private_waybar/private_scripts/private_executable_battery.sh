#!/bin/sh
# Waybar custom module — ACPI battery via sysctl.
set -u

# teal, not green: green is the CPU accent. Charging gets its own
# flamingo so it is distinct from every other module too.
C_GOOD="#94e2d5"; C_WARN="#f9e2af"; C_CRIT="#f38ba8"; C_CHRG="#f2cdcd"

life=$(sysctl -n hw.acpi.battery.life 2>/dev/null) || exit 0
[ -n "$life" ] || exit 0
state=$(sysctl -n hw.acpi.battery.state 2>/dev/null || echo 0)
mins=$(sysctl -n hw.acpi.battery.time  2>/dev/null || echo -1)

# state is a bitmask: 1 discharging, 2 charging, 4 critical
charging=0
[ $(( state & 2 )) -ne 0 ] && charging=1

if [ "$charging" -eq 1 ]; then
    icon="󰂄"; cls=charging; col=$C_CHRG
else
    set -- "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"
    idx=$(( life / 10 + 1 ))
    [ "$idx" -gt 11 ] && idx=11
    eval "icon=\${$idx}"

    if   [ "$life" -le 15 ]; then cls=critical; col=$C_CRIT
    elif [ "$life" -le 30 ]; then cls=warning;  col=$C_WARN
    else                          cls=good;     col=$C_GOOD
    fi
fi

# Detail beyond the percentage lives in acpiconf(8), not in sysctl:
# design vs last-full capacity (i.e. wear), cycle count, draw and voltage.
# `hw.acpi.battery.time` reports -1 whenever the rate is 0 or the firmware
# has not settled, which is most of the time while plugged in — so the
# remaining-time line is conditional, not always present.
info=$(acpiconf -i 0 2>/dev/null)
field() { printf '%s\n' "$info" | awk -F':[[:space:]]*' -v k="$1" '$1==k {print $2; exit}'; }

design=$(field 'Design capacity'    | tr -dc '0-9')
lastfull=$(field 'Last full capacity' | tr -dc '0-9')
cycles=$(field 'Cycle Count'        | tr -dc '0-9')
rate=$(field 'Present rate')
volts=$(field 'Present voltage')

if [ "$charging" -eq 1 ]; then
    head="charging"
elif [ "$life" -ge 99 ]; then
    head="full"
else
    head="on battery"
fi

tip=$(printf '%s%%  ·  %s' "$life" "$head")
[ "$mins" -ge 0 ] && \
    tip=$(printf '%s\\n%s' "$tip" \
          "$(printf '%s  %dh %02dm' \
             "$([ "$charging" -eq 1 ] && echo 'until full ' || echo 'remaining  ')" \
             $(( mins / 60 )) $(( mins % 60 )))")

# Health is last-full over design capacity — the number that actually tells
# you whether the pack is worn, which the percentage never does.
if [ -n "${design:-}" ] && [ -n "${lastfull:-}" ] && [ "$design" -gt 0 ]; then
    tip=$(printf '%s\\n\\nhealth     %d%%  (%s / %s mAh)' \
                 "$tip" $(( lastfull * 100 / design )) "$lastfull" "$design")
fi
[ -n "${cycles:-}" ] && tip=$(printf '%s\\ncycles     %s' "$tip" "$cycles")
[ -n "${rate:-}"   ] && tip=$(printf '%s\\ndraw       %s' "$tip" "$rate")
[ -n "${volts:-}"  ] && tip=$(printf '%s\\nvoltage    %s' "$tip" "$volts")

# Span built here, not inline: FreeBSD /bin/sh drops the backslash in `\"`
# inside a single-quoted printf format, emitting quotes that break the JSON.
markup="<span size='130%' color='$col'>$icon</span>"

printf '{"text":"%s %s%%","class":"%s","tooltip":"%s"}\n' \
    "$markup" "$life" "$cls" "$tip"
