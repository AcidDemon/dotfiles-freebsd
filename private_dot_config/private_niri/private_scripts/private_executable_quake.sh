#!/bin/sh
# Drop-down kitty, quake style.
#
# niri clamps floating windows to the output -- a 510px window stops at y=-387 --
# so it cannot be parked off-screen. Hiding moves it to the "scratch" workspace
# instead, which keeps the shell and the window position alive. The slide is
# niri's own window-movement animation.
#
# On the scratch workspace the parked window is partly visible, so "is it
# hidden" cannot be decided by workspace alone there. The y position decides:
# negative means slid up, i.e. parked.
CLASS=quake
PARK_WS=scratch
REST_Y=255      # working-area relative; centers a half-height window on 1080p
PARK_Y=-2000    # niri clamps this to the top edge
SLIDE=0.25      # park mid-slide: the tail of the ease-out just looks like lag

win=$(niri msg -j windows | jq -c --arg c "$CLASS" 'first(.[] | select(.app_id == $c))')

if [ -z "$win" ]; then
    # First spawn. The window rule opens it already parked at the top edge,
    # so this only has to wait for the window and slide it down -- that is
    # what gives the first F12 the same animation as every later one.
    kitty --class=$CLASS &
    id=
    n=0
    while [ "$n" -lt 100 ]; do
        id=$(niri msg -j windows | jq -r --arg c "$CLASS" \
            'first(.[] | select(.app_id == $c) | .id) // empty')
        [ -n "$id" ] && break
        n=$((n + 1))
        sleep 0.05
    done
    [ -z "$id" ] && exit 1
    niri msg action move-floating-window --id "$id" -y "$REST_Y"
    exit 0
fi

id=$(printf '%s' "$win" | jq -r .id)
ws=$(printf '%s' "$win" | jq -r .workspace_id)
y=$(printf '%s' "$win" | jq -r '.layout.tile_pos_in_workspace_view[1]')
set -- $(niri msg -j workspaces | jq -r \
    'first(.[] | select(.is_focused) | "\(.id) \(.idx) \(.name // "-")")')

if [ "$ws" != "$1" ] || [ "${y%%.*}" -lt 0 ] 2>/dev/null; then
    # show: sit it at the top edge, pull it onto this workspace, slide down
    niri msg action move-floating-window --id "$id" -y "$PARK_Y"
    niri msg action move-window-to-workspace --window-id "$id" --focus true "$2"
    niri msg action focus-window --id "$id"
    niri msg action move-floating-window --id "$id" -y "$REST_Y"
else
    # hide: slide up, then park on the scratch workspace. Already on scratch
    # means there is nowhere to park it, and sliding up is the whole hide.
    niri msg action move-floating-window --id "$id" -y "$PARK_Y"
    if [ "$3" != "$PARK_WS" ]; then
        sleep "$SLIDE"
        niri msg action move-window-to-workspace --window-id "$id" --focus false "$PARK_WS"
    fi
fi
