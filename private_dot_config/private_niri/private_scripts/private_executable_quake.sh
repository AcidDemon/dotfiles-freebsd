#!/bin/sh
# Drop-down kitty. Kill and respawn, not hide: niri has no scratchpad and
# niri msg is dead on this box. tmux keeps the shell alive between toggles.
pid=$(pgrep -nf 'class=quake') || exec kitty --class=quake -e tmux new -A -s quake
kill "$pid"
