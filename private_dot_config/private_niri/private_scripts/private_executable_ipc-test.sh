#!/bin/sh
# Probe niri IPC health. Run inside the session (Mod+Return), not over SSH.
LOG=~/.local/share/sddm/wayland-session.log

echo "niri pid:    $(pgrep -x niri)"
echo "NIRI_SOCKET: ${NIRI_SOCKET:-<unset>}"
[ -z "$NIRI_SOCKET" ] && { echo "not inside niri, aborting"; exit 1; }
before=$(grep -c "error making IPC stream async" "$LOG" 2>/dev/null || echo 0)

probe() {
    ok=0; fail=0
    i=0
    while [ "$i" -lt "$1" ]; do
        if niri msg -j workspaces >/dev/null 2>&1; then ok=$((ok+1)); else fail=$((fail+1)); fi
        [ "$2" -gt 0 ] && sleep "$2"
        i=$((i+1))
    done
    echo "$3: ok=$ok fail=$fail"
}

probe 20 0 "burst      "
probe 12 5 "spaced 5s  "

after=$(grep -c "error making IPC stream async" "$LOG" 2>/dev/null || echo 0)
echo "new 'error making IPC stream async' log lines: $((after - before))"
echo
echo "one failure verbatim (empty = all succeeded):"
niri msg -j workspaces >/dev/null 2>/tmp/niri-ipc-err && : >/tmp/niri-ipc-err
cat /tmp/niri-ipc-err
