#!/bin/sh
# Waybar custom module — microphone state.
#
# pactl, NOT wpctl. There is no PipeWire on this machine: audio is
# PulseAudio (pid from `pgrep pulseaudio`) using module-oss on top of
# FreeBSD OSS. wpctl is a PipeWire tool, so it failed with "Could not
# connect to PipeWire" and the module showed an error instead of a level.
# pactl talks to the same server waybar's own `pulseaudio` module uses,
# so the two always agree.
#
# NB: niri binds XF86AudioMicMute to `mixer rec.mute=^`, which toggles the
# OSS mixer underneath PulseAudio rather than the PulseAudio source. That
# will not move the value shown here. Point the keybind at
# `~/.config/waybar/scripts/mic.sh toggle` to keep them in sync.
set -u

C_ON="#f5c2e7"; C_OFF="#f38ba8"
SIG=5        # must match "signal" for custom/mic in config.jsonc
RTMIN=65     # FreeBSD SIGRTMIN. pkill here rejects -RTMIN+N, numbers only.
SRC="@DEFAULT_SOURCE@"

if [ "${1:-}" = "toggle" ]; then
    pactl set-source-mute "$SRC" toggle >/dev/null 2>&1
    pkill -$((RTMIN + SIG)) waybar
    exit 0
fi

# "Volume: front-left: 24248 /  37% / -25.91 dB, front-right: ..."
vol=$(pactl get-source-volume "$SRC" 2>/dev/null \
      | awk 'NR==1 {for (i=1; i<=NF; i++) if ($i ~ /%$/) { sub(/%/,"",$i); print $i; exit }}')
mute=$(pactl get-source-mute "$SRC" 2>/dev/null | awk '{print $2}')

# Report the failure rather than exiting silently — a module that emits
# nothing is hidden by waybar, leaving nothing to diagnose.
if [ -z "${vol:-}" ]; then
    markup="<span size='130%' color='$C_OFF'>󰍮</span>"
    printf '{"text":"%s","class":"unavailable","tooltip":"no audio source (is pulseaudio running?)"}\n' \
        "$markup"
    exit 0
fi

if [ "${mute:-no}" = "yes" ]; then
    markup="<span size='130%' color='$C_OFF'>󰍭</span>"
    printf '{"text":"%s off","class":"muted","tooltip":"mic muted · input level %s%%"}\n' \
        "$markup" "$vol"
else
    markup="<span size='130%' color='$C_ON'>󰍬</span>"
    printf '{"text":"%s %s%%","class":"live","tooltip":"mic live · input level %s%%"}\n' \
        "$markup" "$vol" "$vol"
fi
