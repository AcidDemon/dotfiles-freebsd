#!/bin/sh
# Install the dynamic MOTD. SSH logins only.
#
# run_after_ rather than run_once_after_: the installed copy silently drifts
# whenever ~/bin/generate-motd.sh changes, and run_once_ never notices. Every
# step below is a no-op when already correct, so a routine apply asks for no
# doas password.
set -e

GEN=/usr/local/bin/generate-motd.sh
HOOK=/usr/local/etc/profile.d/motd.sh
SRC="$HOME/bin/generate-motd.sh"

if cmp -s "$SRC" "$GEN" && [ -x "$HOOK" ] && [ ! -s /etc/motd ]; then
    exit 0
fi

if [ ! -f /etc/motd.orig ] && [ -s /etc/motd ]; then
    echo "motd: backing up /etc/motd to /etc/motd.orig"
    doas cp /etc/motd /etc/motd.orig
fi

if [ -s /etc/motd ]; then
    echo "motd: silencing static /etc/motd"
    doas truncate -s 0 /etc/motd
fi

if ! cmp -s "$SRC" "$GEN"; then
    echo "motd: installing $GEN"
    doas mkdir -p /usr/local/bin
    doas install -m 755 -o root -g wheel "$SRC" "$GEN"
fi

# the hourly cron job predates the login hook
if [ -f /etc/crontab ] && grep -q "generate-motd.sh" /etc/crontab; then
    echo "motd: removing hourly cron job"
    doas sed -i '' '/generate-motd.sh/d' /etc/crontab
fi

if [ ! -x "$HOOK" ]; then
    echo "motd: installing sh/bash profile hook"
    doas mkdir -p /usr/local/etc/profile.d
    doas tee "$HOOK" >/dev/null <<'EOF'
if [ -n "$SSH_CONNECTION" ] && [ -x /usr/local/bin/generate-motd.sh ]; then
    /usr/local/bin/generate-motd.sh
fi
EOF
    doas chmod 755 "$HOOK"
fi

for zf in /etc/zprofile /usr/local/etc/zprofile; do
    if [ ! -f "$zf" ] || ! grep -q "profile.d/motd.sh" "$zf"; then
        echo "motd: hooking $zf"
        doas tee -a "$zf" >/dev/null <<'EOF'

if [ -f /usr/local/etc/profile.d/motd.sh ]; then
    . /usr/local/etc/profile.d/motd.sh
fi
EOF
    fi
done

if [ -f /etc/csh.login ] && ! grep -q "generate-motd.sh" /etc/csh.login; then
    echo "motd: hooking /etc/csh.login"
    doas tee -a /etc/csh.login >/dev/null <<'EOF'

if ( $?SSH_CONNECTION && -x /usr/local/bin/generate-motd.sh ) then
    /usr/local/bin/generate-motd.sh
endif
EOF
fi

echo "motd: ready."
