#!/bin/sh
# owns the whole user crontab; crontab -e edits are lost on the next change here
# adblock: writes to the running browser's IPC socket, never starts an instance;
# a headless one deletes the _autosave crash session. Protocol is qutebrowser's ipc.py v1.
set -e

crontab - <<'CRON'
@hourly S=/tmp/xdg-$(id -un)/qutebrowser/ipc-$(/sbin/md5 -qs "$(id -un)"); [ -S "$S" ] && [ -z "$(find ~/.local/share/qutebrowser/adblock-cache.dat -mtime -7 2>/dev/null)" ] && printf '{"args":[":adblock-update"],"target_arg":null,"protocol_version":1}\n' | /usr/bin/nc -NU -w 10 "$S" >/dev/null 2>&1
CRON
