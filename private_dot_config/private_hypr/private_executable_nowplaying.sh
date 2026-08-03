#!/bin/sh
# Current MPRIS track for the hyprlock label, prefixed with a Spotify glyph
# (nf-fa-spotify, U+F1BC) coloured with pango markup. Prints a zero-width space
# when nothing is playing, since an empty string makes hyprlock fall back to its
# default "Sample Text". The playerctl format braces cannot live in
# hyprlock.conf itself, hyprlang reads them as block delimiters.
TRACK=$(playerctl -f '{{title}} - {{artist}}' metadata 2>/dev/null)
if [ -n "$TRACK" ]; then
  printf '<span color="#a6e3a1">\357\206\274</span>  %s' "$TRACK"
else
  printf '\342\200\213'
fi
