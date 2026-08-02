#!/bin/sh
# Build awww (wallpaper daemon) from source.
#
# awww is not in the FreeBSD ports tree under any name, and upstream moved off
# GitHub to Codeberg. It builds cleanly on FreeBSD with no patches -- its deps
# are rustix/libc, nothing Linux-only -- so building from source is the only
# option until someone ports it.
#
# run_once_ rather than run_after_: this compiles a Rust workspace (~3 minutes)
# and pulls in the rust toolchain, which is far too expensive for every apply.
# Delete the corresponding entry in `chezmoi state dump` to force a rebuild, or
# just rebuild by hand in the source directory.

set -e

if command -v awww-daemon >/dev/null 2>&1; then
    echo "awww: already installed, skipping build."
    exit 0
fi

[ "$(uname -s)" = "FreeBSD" ] || {
    echo "awww: not FreeBSD -- check your package manager first, this only builds from source."
    exit 0
}

# Prefer an existing checkout under the usual repos dir; fall back to the cache
# so a fresh machine does not need one.
if [ -d "$HOME/Workspace/repos/awww/.git" ]; then
    SRC="$HOME/Workspace/repos/awww"
else
    SRC="${XDG_CACHE_HOME:-$HOME/.cache}/awww"
fi
BINDIR="$HOME/.local/bin"
COMPDIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
REPO="https://codeberg.org/LGFae/awww"

for p in rust git; do
    pkg info -e "$p" >/dev/null 2>&1 || {
        echo "awww: installing $p (needed to build)"
        doas pkg install -y "$p"
    }
done

if [ -d "$SRC/.git" ]; then
    echo "awww: updating $SRC"
    git -C "$SRC" pull --ff-only
else
    echo "awww: cloning $REPO"
    git clone --depth 1 "$REPO" "$SRC"
fi

echo "awww: building (this takes a few minutes)"
( cd "$SRC" && cargo build --release )

mkdir -p "$BINDIR"
install -m 755 "$SRC/target/release/awww" "$SRC/target/release/awww-daemon" "$BINDIR/"
echo "awww: installed awww and awww-daemon into $BINDIR"

# The zsh completion is only emitted by the build script, with no runtime flag to
# regenerate it -- so capture it now or it is lost with the source tree.
if [ -f "$SRC/completions/_awww" ]; then
    mkdir -p "$COMPDIR"
    install -m 644 "$SRC/completions/_awww" "$COMPDIR/_awww"
    echo "awww: installed zsh completion into $COMPDIR"
fi

echo "awww: set a wallpaper with: awww img /path/to/image"
