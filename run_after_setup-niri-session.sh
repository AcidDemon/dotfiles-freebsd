#!/bin/sh
# Set up niri as an sddm session on FreeBSD.
#
# Running niri under sddm on FreeBSD needs three fixes sddm does not provide;
# they live in ~/bin/niri-session, which explains each one. This script installs
# that wrapper system-wide, points sddm's session entry at it, and makes sure the
# packages and services it depends on are present.
#
# This is run_after_ rather than run_once_after_ on purpose: `pkg upgrade niri`
# overwrites the packaged niri.desktop and silently reverts Exec=, which breaks
# the session with no obvious cause. Re-checking on every apply self-heals that.
# Every step below is a no-op when already correct, so a routine `chezmoi apply`
# triggers no doas prompt.

set -e

[ "$(uname -s)" = "FreeBSD" ] || {
    echo "niri-session: not FreeBSD, skipping (elsewhere logind makes the wrapper unnecessary)."
    exit 0
}

WRAPPER_SRC="${HOME}/bin/niri-session"
WRAPPER_DST="/usr/local/bin/niri-session"
DESKTOP="/usr/local/share/wayland-sessions/niri.desktop"

# cage is sddm's wayland greeter compositor; python3 is what the wrapper uses for
# TIOCNOTTY and signal handling, neither of which POSIX sh can do.
# xwayland-satellite gives X11 apps a rootless Xwayland under niri -- without it
# niri logs "error spawning xwayland-satellite ... disabling integration".
# adwaita-icon-theme provides the xcursor theme the niri config points at; niri's
# built-in default theme name does not exist on FreeBSD.
# hyprlock/hypridle are standalone -- they pull in hyprutils/hyprlang, not
# hyprland -- and speak ext-session-lock-v1 / ext-idle-notify-v1, both of which
# niri implements.
# grim/slurp are for scripted captures -- the screenshot keybinds run ~/bin/shot,
# which uses niri's built-in actions and satty. swaync backs the notification binds,
# cliphist the clipboard history one (via ~/bin/cliphist-rofi, which also needs
# wl-clipboard).
PKGS="niri seatd sddm dbus cage waybar python3 xwayland-satellite adwaita-icon-theme
      hyprlock hypridle grim slurp satty swaync cliphist wl-clipboard rofi kitty thunar
      wf-recorder"

missing=""
for p in $PKGS; do
    pkg info -e "$p" >/dev/null 2>&1 || missing="$missing $p"
done
if [ -n "$missing" ]; then
    echo "niri-session: installing missing packages:$missing"
    doas pkg install -y $missing
fi

for svc in dbus seatd sddm; do
    cur=$(sysrc -n "${svc}_enable" 2>/dev/null || echo "")
    case "$cur" in
        [Yy][Ee][Ss]) ;;
        *)
            echo "niri-session: enabling ${svc}"
            doas sysrc "${svc}_enable=YES" >/dev/null
            ;;
    esac
done

if [ ! -f "$WRAPPER_SRC" ]; then
    echo "niri-session: $WRAPPER_SRC is missing" >&2
    exit 1
fi
if ! cmp -s "$WRAPPER_SRC" "$WRAPPER_DST" 2>/dev/null; then
    echo "niri-session: installing $WRAPPER_DST"
    doas install -m 755 -o root -g wheel "$WRAPPER_SRC" "$WRAPPER_DST"
fi

if [ -f "$DESKTOP" ]; then
    if [ "$(grep '^Exec=' "$DESKTOP" 2>/dev/null)" != "Exec=niri-session" ]; then
        echo "niri-session: pointing $DESKTOP at niri-session"
        doas sed -i '' 's|^Exec=.*|Exec=niri-session|' "$DESKTOP"
    fi
else
    echo "niri-session: $DESKTOP not found -- niri package layout changed?" >&2
fi

# niri 26.04 unwraps insert_source() in register_deadline_timer, and on FreeBSD that
# call returns AlreadyExists now and then -- SIGABRT, session gone. The patch makes it
# a logged warning. Only used when building from ports; pkg upgrade brings back the
# stock binary, hence the check below.
PATCH_SRC="${HOME}/.config/niri/patches/patch-src_utils_transaction.rs"
PATCH_DST="/usr/ports/x11-wm/niri/files/patch-src_utils_transaction.rs"

if [ -f "$PATCH_SRC" ] && [ -d "$(dirname "$PATCH_DST")" ]; then
    if ! cmp -s "$PATCH_SRC" "$PATCH_DST" 2>/dev/null; then
        echo "niri-session: installing $PATCH_DST"
        doas install -m 644 -o root -g wheel "$PATCH_SRC" "$PATCH_DST"
    fi
fi

if ! grep -qa 'error registering deadline' /usr/local/bin/niri 2>/dev/null; then
    echo "niri-session: WARNING installed niri is unpatched, it will abort the session"
    echo "niri-session:          on a screenshot sooner or later. Rebuild:"
    echo "niri-session:            cd /usr/ports/x11-wm/niri && doas make deinstall reinstall clean"
fi

# seatd refuses device access without this, so niri simply will not start.
# Getting it wrong has no downside beyond the group membership itself.
if ! id -nG "$(id -un)" | tr ' ' '\n' | grep -qx video; then
    echo "niri-session: adding $(id -un) to the video group (seatd needs it)"
    doas pw groupmod video -m "$(id -un)"
    echo "niri-session: log out and back in for the new group to take effect"
fi

# A DRM driver is equally required. Detect it from the PCI vendor rather than
# hardcoding this machine's amdgpu, so the repo works on other hardware.
if ! kldstat 2>/dev/null | grep -qE 'amdgpu|i915kms|radeonkms|nvidia'; then
    gpu=$(pciconf -lv 2>/dev/null | grep -A3 'class=0x0300' | grep -i "vendor  *=" | head -1)
    case "$gpu" in
        *AMD*|*ATI*) drm=amdgpu ;;
        *Intel*)     drm=i915kms ;;
        *NVIDIA*)    drm=nvidia-modeset ;;
        *)           drm="" ;;
    esac
    if [ -n "$drm" ]; then
        echo "niri-session: loading DRM driver $drm and adding it to kld_list"
        doas sysrc kld_list+="$drm" >/dev/null
        doas kldload "$drm" 2>/dev/null || true
    else
        echo "niri-session: WARNING could not identify the GPU; set kld_list yourself:" >&2
        echo "niri-session:          doas sysrc kld_list+=amdgpu   # or i915kms, radeonkms" >&2
    fi
fi

# Deliberately NOT applied: these grant passwordless root for specific commands,
# which is a decision for a person, not for a dotfiles apply.
if ! doas -n ifconfig wlan0 up >/dev/null 2>&1; then
    echo "niri-session: optional -- for the airplane key (~/bin/airplane-toggle), add to"
    echo "niri-session:   /usr/local/etc/doas.conf, AFTER any general permit line:"
    echo "niri-session:     permit nopass $(id -un) as root cmd /sbin/ifconfig args wlan0 up"
    echo "niri-session:     permit nopass $(id -un) as root cmd /sbin/ifconfig args wlan0 down"
fi
if ! id -nG "$(id -un)" | tr ' ' '\n' | grep -qx operator; then
    echo "niri-session: optional -- for ~/bin/shutdown-timer to power off unattended:"
    echo "niri-session:     doas pw groupmod operator -m $(id -un)"
    echo "niri-session:   (/sbin/shutdown is setuid root, group operator -- no doas rule needed)"
fi

echo "niri-session: ready."
