#!/bin/sh
# Icon and cursor themes named by managed configs but too large to track.
#
# gtk-3.0/settings.ini, gtk-4.0/settings.ini, qt5ct.conf, qt6ct.conf and
# xsettingsd.conf all name Colloid-Catppuccin-Dark and WhiteSur-cursors. The
# icon set alone is ~583M across 94k files, so it is built here instead of
# committed. The GTK widget theme is NOT here: it came off the old NixOS box
# and no FreeBSD-runnable installer reproduces its name, so it is tracked in
# the repo alongside the Kvantum theme.
#
# run_once_ rather than run_after_: two git clones and a large file copy.
# Delete the matching entry in `chezmoi state dump` to force a re-run.

set -e

ICONDIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"

[ "$(uname -s)" = "FreeBSD" ] || {
    echo "themes: not FreeBSD -- install Colloid and WhiteSur-cursors however your distro prefers."
    exit 0
}

# Both upstream installers are bash, not sh.
command -v bash >/dev/null 2>&1 || {
    echo "themes: installing bash (upstream install.sh needs it)"
    doas pkg install -y bash
}
command -v git >/dev/null 2>&1 || doas pkg install -y git

# $1 repo url, $2 checkout dir, $3 install args...
clone_and_install() {
    url="$1"; dir="$2"; shift 2
    if [ -d "$dir/.git" ]; then
        git -C "$dir" pull --ff-only
    else
        git clone --depth 1 "$url" "$dir"
    fi
    ( cd "$dir" && bash ./install.sh "$@" )
}

if [ -d "$ICONDIR/Colloid-Catppuccin-Dark" ]; then
    echo "themes: Colloid-Catppuccin already present, skipping."
else
    echo "themes: building Colloid icons (large, takes a while)"
    clone_and_install https://github.com/vinceliuice/Colloid-icon-theme \
        "$CACHE/Colloid-icon-theme" -d "$ICONDIR" -s catppuccin
fi

if [ -d "$ICONDIR/WhiteSur-cursors" ]; then
    echo "themes: WhiteSur-cursors already present, skipping."
else
    echo "themes: installing WhiteSur-cursors"
    clone_and_install https://github.com/vinceliuice/WhiteSur-cursors \
        "$CACHE/WhiteSur-cursors"
fi

# The whole point is that the managed configs resolve. Say so if they do not,
# rather than leaving a silently wrong theme.
rc=0
for t in Colloid-Catppuccin-Dark Colloid-Catppuccin-Light WhiteSur-cursors; do
    [ -d "$ICONDIR/$t" ] || { echo "themes: MISSING $ICONDIR/$t -- upstream naming changed, check install.sh flags"; rc=1; }
done

# ianny (idle-break reminder) has managed config but no port; it is a cargo install.
if ! command -v ianny >/dev/null 2>&1; then
    echo "themes: installing ianny (config in .config/io.github.zefr0x.ianny is managed)"
    command -v cargo >/dev/null 2>&1 || doas pkg install -y rust
    cargo install ianny || echo "themes: ianny build failed -- not fatal, retry by hand"
fi

exit $rc
