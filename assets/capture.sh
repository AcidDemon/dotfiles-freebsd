#!/bin/sh
# Regenerate the README screenshots from a live niri session.
#
#   ./capture.sh list              names and numbers
#   ./capture.sh prep              once, before any scene
#   ./capture.sh 6 fetch overview  any mix of numbers and names
#   ./capture.sh all               every scene in order
#   ./capture.sh pack              PNG -> webp into this directory
#   ./capture.sh restore           put the session back
#
# prep/restore are a pair. prep freezes the wallpaper rotator, stops the
# daemons that would otherwise walk into a frame, and snapshots the window
# list; restore undoes all of it and closes only the windows this script
# opened. Running a scene without prep works but you get the current
# wallpaper and hypridle may lock the screen mid-capture.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
PNGDIR="${PNGDIR:-${TMPDIR:-/tmp}/capture-png}"
STATE="${TMPDIR:-/tmp}/capture-state"
WP=/home/acid/.local/share/wallpapers
MUSIC=/home/acid/Music
WORK_URL="${WORK_URL:-https://github.com/YaLTeR/niri}"

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-$(id -un)}"
NIRI_SOCKET="${NIRI_SOCKET:-$(ls -1t "$XDG_RUNTIME_DIR"/niri.wayland-*.sock 2>/dev/null | head -1)}"
export NIRI_SOCKET
# swaync-client and notify-send block forever without this.
DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$(ls -1t /tmp/dbus-* 2>/dev/null | head -1)}"
export DBUS_SESSION_BUS_ADDRESS

mkdir -p "$PNGDIR" "$STATE"
OUTPUT=$(niri msg -j outputs | jq -r 'keys[0]')

# ── helpers ────────────────────────────────────────────────────────────────

a()     { niri msg action "$@" >/dev/null 2>&1 || true; }
width() { a set-column-width -- "$1"; sleep 1.2; }
wp()    { awww img -o "$OUTPUT" -t none "$WP/$1" >/dev/null 2>&1; sleep 1; }

# kitty ignores its trailing command when --hold is present on this build and
# falls through to the login shell, so long-running TUIs are launched bare and
# one-shot commands are typed in with kitty_type instead.
term()  { a spawn-sh -- "kitty $*"; sleep "${SETTLE:-3}"; }

# wtype drops characters into kitty at the default rate: it uploads its own
# keymap and kitty re-reads it mid-string. 200ms/char is the slowest thing
# that has never lost a character here. rofi is fine at 60.
kitty_type() { wtype -d 200 "$1"; sleep 0.5; wtype -k Return; }

# grim, not `niri msg action screenshot-*`: the niri actions always copy to the
# clipboard too, and two `wl-paste --watch cliphist store` watchers are running.
shot()  { sleep "${2:-1.5}"; grim -o "$OUTPUT" "$PNGDIR/$1.png"; echo "  -> $1.png"; }

# Anywhere on the bar leaves a tooltip hanging in the frame. 0,0 is worse: no
# `gestures { hot-corners { off } }` block exists, so it opens the Overview.
park()  { wlrctl pointer move 5000 5000; sleep 0.3
          wlrctl pointer move -1779 -69; sleep 0.5; }

# wlrctl only does relative motion, so travel is measured from the bottom-right
# corner, where niri clamps.
goto()  { wlrctl pointer move 5000 5000; sleep 0.3
          wlrctl pointer move $(( $1 - 1919 )) $(( $2 - 1079 )); sleep "${3:-1.5}"; }

ws()    { a focus-workspace "$1"; sleep 1; }

# Only ever closes windows that appeared after prep.
clean() {
    [ -f "$STATE/before" ] || return 0
    niri msg -j windows | jq -r '.[].id' | sort -n > "$STATE/now"
    comm -13 "$STATE/before" "$STATE/now" | while read -r id; do
        pid=$(niri msg -j windows | jq -r --argjson i "$id" '.[]|select(.id==$i)|.pid')
        [ -n "$pid" ] && [ "$pid" != "null" ] && kill "$pid" 2>/dev/null || true
    done
    sleep 2.5
}

# cava is configured method=sndio/source=default with no sndiod running, so it
# falls back to the built-in microphone and sits flat in a quiet room. Feed it
# decoded audio through a FIFO instead: real spectrum, and nothing is audible
# because it never reaches the sound card. The rewrite has to be section-aware
# -- cava has a second `method=` under [output] and clobbering that one makes
# it refuse to start.
cava_feed() {
    [ -p "$STATE/cava.fifo" ] || mkfifo "$STATE/cava.fifo"
    awk -v f="$STATE/cava.fifo" '
        /^\[/ { s=$0 }
        s=="[input]" && /^method=/ { print "method=fifo"; next }
        s=="[input]" && /^source=/ { print "source=" f; next }
        { print }
    ' "$HOME/.config/cava/config" > "$STATE/cava.conf"
    pgrep -f 'capture-feed' >/dev/null 2>&1 && return 0
    # sorted, not raw find order: otherwise the mpris pill shows a different
    # track on every run and the gallery stops matching itself.
    track=$(find "$MUSIC" -type f \( -name '*.mp3' -o -name '*.flac' \) 2>/dev/null | sort | head -1)
    [ -n "$track" ] || return 0
    cat > "$STATE/capture-feed.sh" <<EOF
#!/bin/sh
while :; do
  ffmpeg -hide_banner -loglevel quiet -re -i "$track" -f s16le -ac 2 -ar 44100 - > "\$1" 2>/dev/null
  sleep 0.2
done
EOF
    chmod +x "$STATE/capture-feed.sh"
    nohup sh "$STATE/capture-feed.sh" "$STATE/cava.fifo" >/dev/null 2>&1 &
    sleep 3
}

# Populates the waybar mpris pill, the swaync media widget and hyprlock's now
# playing line at once. volume=0 so nothing is audible.
player() {
    pgrep -x mpv >/dev/null 2>&1 && return 0
    # sorted, not raw find order: otherwise the mpris pill shows a different
    # track on every run and the gallery stops matching itself.
    track=$(find "$MUSIC" -type f \( -name '*.mp3' -o -name '*.flac' \) 2>/dev/null | sort | head -1)
    [ -n "$track" ] || return 0
    nohup mpv --no-video --volume=0 --loop-file=inf --really-quiet "$track" >/dev/null 2>&1 &
    sleep 3
}

# ── prep / restore ─────────────────────────────────────────────────────────

prep() {
    niri msg -j windows | jq -r '.[].id' | sort -n > "$STATE/before"

    # Freeze the rotator BEFORE reading the wallpaper: it fires every 15 min.
    # `awww pause` does not hold -- the flag only gates the draw loop, incoming
    # `awww img` still commits -- and daemon-toggle cannot match it either,
    # because pgrep -x sees `sh`, not `awww-random`.
    rot=$(pgrep -f awww-random | head -1) || true
    if [ -n "${rot:-}" ]; then echo "$rot" > "$STATE/rot"; kill -STOP "$rot"; sleep 1; fi
    awww query | sed 's/.*currently displaying: image: //' > "$STATE/wallpaper"

    # hypridle arms shutdown-timer and hyprlock at 600s idle, and a scripted
    # capture has long stretches with no real input. gammastep tints every
    # frame. ianny pops break reminders on a timer.
    for d in hypridle gammastep; do pkill -x "$d" 2>/dev/null || true; done
    pkill -f ianny 2>/dev/null || true

    player
    cava_feed
    echo "prep done. wallpaper saved: $(cat "$STATE/wallpaper")"
}

restore() {
    clean
    pkill -f capture-feed 2>/dev/null || true
    pkill -x mpv 2>/dev/null || true
    tmux -L shot kill-server 2>/dev/null || true
    rm -f "$STATE/cava.fifo"
    [ -f "$STATE/wallpaper" ] && wp "$(basename "$(cat "$STATE/wallpaper")")"
    [ -f "$STATE/rot" ] && kill -CONT "$(cat "$STATE/rot")" 2>/dev/null || true
    # daemon(8), not setsid: setsid does not exist on FreeBSD.
    for d in hypridle gammastep; do
        pgrep -x "$d" >/dev/null 2>&1 || /usr/sbin/daemon -f "$d" 2>/dev/null || true
    done
    pgrep -f ianny >/dev/null 2>&1 || \
        /usr/sbin/daemon -f "$HOME/.local/share/.cargo/bin/ianny" 2>/dev/null || true
    echo "restored"
}

# ── scenes ─────────────────────────────────────────────────────────────────

scene_empty() {
    wp serenity.jpg; clean; ws files; park
    shot desktop-empty 2
}

scene_rofi() {
    wp serenity.jpg; clean; ws files; park
    # rofi grabs the keyboard, so the capture is armed before it opens.
    ( sleep 1.8; wtype -d 60 'ter'; sleep 1.2; grim -o "$OUTPUT" "$PNGDIR/rofi.png"
      sleep 0.4; wtype -k Escape ) &
    timeout 12 "$HOME/.config/rofi/bin/launcher" >/dev/null 2>&1 || true
    pkill -x rofi 2>/dev/null || true
    echo "  -> rofi.png"
}

scene_swaync() {
    wp serenity.jpg; clean; ws files; park; player
    notify-send -a Syncthing -i folder-sync "Folder 'Documents' up to date" \
                "Scanned 1,284 files in 3.2s" -t 1500; sleep 0.6
    notify-send -a "Zen Browser" -i firefox "Download complete" \
                "niri-26.04.tar.gz  -  18.4 MB" -t 1500; sleep 0.6
    notify-send -a pkg -i system-software-update "12 packages can be upgraded" \
                "run: doas pkg upgrade" -t 1500; sleep 2.5
    swaync-client -op -sw; sleep 1
    shot swaync 0.5
    swaync-client -cp -sw; sleep 0.5; swaync-client -C
}

scene_notification() {
    wp serenity.jpg; clean; ws files; park; player
    swaync-client -C; sleep 0.5
    term; kitty_type 'clear; eza -la --icons --git ~/.dotfiles'; sleep 2
    # -t 0 never expires: the 4s default in swaync/config.json is not enough
    # time to compose a frame.
    notify-send -a "Zen Browser" -i firefox -t 0 "Download complete" \
                "niri-26.04.tar.gz  -  18.4 MB"
    shot notification 1.2
    swaync-client -C
}

scene_work() {
    wp pixel-car.png; clean; ws files; park; player
    # An explicit URL, not the start page: google.com geo-redirects to
    # google.de and the frame ends up in German.
    a spawn-sh -- "zen '$WORK_URL'"
    R="$HOME/Workspace/repos/awww"
    # clean may have just killed the attached client; the old server can still
    # be shutting down, and new-session against a dying server errors out.
    tmux -L shot kill-server 2>/dev/null || true
    while tmux -L shot has-session 2>/dev/null; do sleep 0.3; done
    sleep 1
    tmux -L shot new-session -d -s demo -n edit -x 92 -y 38 -c "$R"
    # tmux.conf has @continuum-restore on; zeroing the interval stops a new
    # server from creating ~/.local/state/tmux/resurrect and saving into it.
    tmux -L shot set -t demo -g @continuum-save-interval 0 2>/dev/null || true
    tmux -L shot new-window -t demo -n repo  -c "$R"
    tmux -L shot new-window -t demo -n build -c "$R"
    # Vertical split, not horizontal: a horizontal one leaves each pane ~53
    # columns and eza truncates every filename.
    tmux -L shot split-window -v -t demo:repo -p 46 -c "$R"
    cat > "$STATE/gitlog.sh" <<EOF
#!/bin/sh
cd "$R" || exit 1
git --no-pager -c color.ui=always log --graph --decorate -12 \
    --pretty=format:'%C(auto)%h %C(reset)%<(40,trunc)%s'
echo
EOF
    tmux -L shot send-keys -t demo:repo.1 "sh $STATE/gitlog.sh" Enter
    tmux -L shot send-keys -t demo:repo.2 'eza -la --icons --git' Enter
    tmux -L shot select-window -t demo:repo
    tmux -L shot select-pane -t demo:repo.1
    sleep 10
    term "tmux -L shot attach -t demo"
    a move-column-left; sleep 1.5
    park
    shot desktop-work 2
}

scene_monitor() {
    wp river-city.jpg; clean; ws files; park; player; cava_feed
    term btop; width 66.667%
    term "cava -p $STATE/cava.conf"; width 33.333%
    term 'cmatrix -abu 2'
    # consume-or-expel-window-left, not consume-window-into-column: the latter
    # pulls whatever is to the RIGHT and grabs the wrong neighbour here.
    a consume-or-expel-window-left; sleep 2
    a focus-column-left; sleep 1.5
    park
    # cava's bar height follows the track, so take a few and keep the fullest.
    best=0; bestf=""
    for i in 1 2 3 4 5 6; do
        grim -o "$OUTPUT" "$PNGDIR/.mon-$i.png"
        sc=$(magick "$PNGDIR/.mon-$i.png" -crop 620x460+1290+60 +repage \
             -colorspace gray -format '%[fx:int(mean*10000)]' info:)
        [ "$sc" -gt "$best" ] && { best=$sc; bestf="$PNGDIR/.mon-$i.png"; }
        sleep 1.1
    done
    mv "$bestf" "$PNGDIR/desktop-monitor.png"; rm -f "$PNGDIR"/.mon-*.png
    echo "  -> desktop-monitor.png"
}

scene_fetch() {
    wp lit-up-sky.png; clean; ws files; park
    # fastfetch is 33 lines plus a kitty-graphics logo and needs the 2/3
    # column; at 1/2 the boxes wrap. Typed in rather than passed to kitty so
    # the output starts at the top of a cleared screen.
    term; width 66.667%
    kitty_type 'clear; fastfetch'; sleep 4
    term peaclock; width 33.333%
    # The binary face is a whole config directory, not a flag.
    term 'peaclock --config-dir=/home/acid/.config/peaclock-binary'
    a consume-or-expel-window-left; sleep 2
    a focus-column-left; sleep 1.5
    park
    shot desktop-fetch 1.5
}

scene_apps() {
    wp sakura-gate.jpg; clean; ws files; park
    a spawn-sh -- "thunar $HOME/Pictures/DCIM/Wallpaper"; sleep 6
    width 66.667%
    a spawn-sh -- "zathura '$HOME/Downloads/FreeBSD Mastery Jails (Michael W. Lucas).pdf'"
    sleep 7; width 33.333%
    id=$(niri msg -j windows | jq -r '.[]|select(.app_id|test("zathura"))|.id' | head -1)
    a focus-window --id "$id"; sleep 1
    # zathurarc sets recolor true, which flattens the cover art to two colours.
    # A text page is where the Mocha remap actually looks like a feature.
    wtype -k Escape; sleep 0.6; wtype -d 200 '24G'; sleep 3
    # Sweep the focus across the row before shooting: the view can still hold a
    # scroll offset from the last resize even when the columns already fit, and
    # that clips the leftmost window.
    a focus-column-first; sleep 1.5; a focus-column-last; sleep 2
    park
    shot desktop-apps 1.5
}

scene_dev() {
    wp rainy-window.jpeg; clean; ws files; park
    term "nvim $HOME/.config/niri/config.kdl"; width 50%
    # copilot.lua fails to start and parks nvim on a "Press ENTER" prompt that
    # otherwise sits across the bottom of the frame.
    sleep 3
    for _ in 1 2 3 4; do wtype -k Return; sleep 0.8; done
    wtype -k Escape; sleep 0.5
    term; sleep 2                            # newly spawned window takes focus
    kitty_type 'cd ~/.local/share/wallpapers'; sleep 1.5
    wtype -M ctrl -k t -m ctrl; sleep 3      # fzf file widget, kitty image preview
    park
    shot desktop-dev 1.5
}

# Each workspace gets a full layout at a width its contents actually fit in.
# One window per workspace, or fastfetch at 1/2, reads as clipped junk.
scene_overview() {
    wp serenity.jpg; clean; player; cava_feed
    ws mail
    term btop; width 50%
    term peaclock; width 50%

    ws files
    term; width 66.667%
    kitty_type 'clear; fastfetch'; sleep 4
    term "cava -p $STATE/cava.conf"; width 33.333%
    term 'cmatrix -abu 2'
    a consume-or-expel-window-left; sleep 2
    a focus-column-left; sleep 1

    ws chat
    a spawn-sh -- "thunar $HOME/Workspace/repos/awww"; sleep 6; width 33.333%
    a spawn-sh -- "zathura '$HOME/Downloads/FreeBSD Mastery Jails (Michael W. Lucas).pdf'"
    sleep 7; width 66.667%
    id=$(niri msg -j windows | jq -r '.[]|select(.app_id|test("zathura"))|.id' | head -1)
    a focus-window --id "$id"; sleep 1
    wtype -k Escape; sleep 0.6; wtype -d 200 '24G'; sleep 3

    park; ws files; sleep 1.5
    a open-overview; sleep 2.8
    shot overview 0.5
    a close-overview; sleep 1
}

scene_quake() {
    wp serenity.jpg; clean; player
    ws 7; park
    sh "$HOME/.config/niri/scripts/quake.sh"; sleep 1.8
    # Launched by name rather than Ctrl+R: Ctrl+R restores whatever the last
    # search string was. prefix mode, not the default fuzzy: fuzzy pulls this
    # script's own commands into the list because they are the most recent.
    kitty_type 'clear; atuin search -i --search-mode prefix git'; sleep 3
    shot quake 1
    wtype -k Escape; sleep 0.6
    sh "$HOME/.config/niri/scripts/quake.sh"; sleep 1
}

# Bar geometry shifts with the workspace count, so the pill centres are
# measured from the frame instead of hardcoded.
scene_bar() {
    wp serenity.jpg; clean; ws files; player
    term btop; width 50%; term peaclock; width 50%
    park; sleep 1.5
    grim -o "$OUTPUT" "$PNGDIR/.bar-rest.png"
    goto 1460 28 1.8; grim -o "$OUTPUT" "$PNGDIR/.bar-wifi.png"
    goto 1600 28 1.8; grim -o "$OUTPUT" "$PNGDIR/.bar-hw.png"
    goto 1853 28 2.2; grim -o "$OUTPUT" "$PNGDIR/waybar-drawers.png"
    cp "$PNGDIR/waybar-drawers.png" "$PNGDIR/.bar-clock.png"
    for s in rest wifi hw clock; do
        magick "$PNGDIR/.bar-$s.png" -crop 1920x56+0+0 +repage -resize 1440x \
               -set label "$s" "$PNGDIR/.bs-$s.miff"
    done
    magick montage "$PNGDIR/.bs-rest.miff" "$PNGDIR/.bs-wifi.miff" \
                   "$PNGDIR/.bs-hw.miff" "$PNGDIR/.bs-clock.miff" \
        -tile 1x4 -geometry +2+2 -background '#11111b' -fill '#cdd6f4' \
        -pointsize 15 "$PNGDIR/bar-states.png"
    rm -f "$PNGDIR"/.bar-*.png "$PNGDIR"/.bs-*.miff
    park
    echo "  -> waybar-drawers.png, bar-states.png"
}

# The OSD lives for about a second, so the capture is armed before the trigger.
# Volume is read and written back exactly: raise+lower does not round-trip.
scene_osd() {
    wp serenity.jpg; clean; ws files; player
    term btop; width 50%
    term peaclock; width 50%
    a focus-column-first; sleep 1.5
    park
    vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1)
    ( sleep 0.35; grim -o "$OUTPUT" "$PNGDIR/swayosd.png" ) &
    swayosd-client --output-volume raise >/dev/null 2>&1
    wait
    [ -n "${vol:-}" ] && pactl set-sink-volume @DEFAULT_SINK@ "$vol" 2>/dev/null || true
    echo "  -> swayosd.png (volume restored to ${vol:-unknown})"
}

# --test-mode makes login() inert, so this never touches the real session.
# The theme background is a looping video, so a still lands on an arbitrary
# frame; several are taken and the largest (busiest) one kept.
scene_sddm() {
    clean; ws files
    theme=$(awk -F= '/^Current=/{print $2}' /usr/local/etc/sddm.conf)
    a spawn-sh -- "env -u QT_QPA_PLATFORMTHEME -u QT_STYLE_OVERRIDE \
        QT_QPA_PLATFORM=wayland QT_MEDIA_BACKEND=ffmpeg XKB_DEFAULT_LAYOUT=de \
        LANG=en_US.UTF-8 /usr/local/bin/sddm-greeter-qt6 --test-mode \
        --theme /usr/local/share/sddm/themes/$theme"
    sleep 8
    id=$(niri msg -j windows | jq -r '.[]|select(.app_id|test("sddm";"i"))|.id' | head -1)
    [ -n "$id" ] || { echo "  greeter did not appear"; return 1; }
    a focus-window --id "$id"; sleep 1
    a fullscreen-window; sleep 2
    # The first call can toggle an already-fullscreen surface back off.
    got=$(niri msg -j windows | jq -r --argjson i "$id" '.[]|select(.id==$i)|.layout.window_size[0]')
    [ "$got" -lt 1900 ] && { a fullscreen-window; sleep 2; }
    for i in 1 2 3 4 5 6; do
        a screenshot-window --id "$id" --path "$PNGDIR/.sddm-$i.png"; sleep 1
    done
    best=$(ls -S "$PNGDIR"/.sddm-*.png 2>/dev/null | head -1)
    [ -n "$best" ] && mv "$best" "$PNGDIR/sddm.png"
    rm -f "$PNGDIR"/.sddm-*.png
    pkill -x sddm-greeter-qt6 2>/dev/null || true
    echo "  -> sddm.png"
}

# ── recording ──────────────────────────────────────────────────────────────
#
# Two takes cut together. Everything in act 1 is a niri IPC call or a wtype
# keystroke, so a retake reproduces the same beats. Timings assume the
# `slowdown 1.8` in config.kdl; at 60fps a 270ms window-open is ~16 frames,
# which reads as motion. Do not speed it up.

REC_OPTS="-D -r 60 -c libx264 -p crf=18 -p preset=veryfast -x yuv420p"

rec_start() { wf-recorder -o "$OUTPUT" $REC_OPTS -f "$PNGDIR/$1.mkv" \
                  >"$STATE/wfr.log" 2>&1 & echo $! > "$STATE/wfr.pid"; sleep 2.5; }
rec_stop()  { kill -INT "$(cat "$STATE/wfr.pid")" 2>/dev/null || true
              wait "$(cat "$STATE/wfr.pid")" 2>/dev/null || true; rm -f "$STATE/wfr.pid"; }

rec1() {
    wp serenity.jpg; clean; player; cava_feed
    park; ws files; sleep 1
    rec_start act1
    b() { sleep "$1"; }

    b 2.0
    a spawn-sh -- 'kitty btop';           b 3.0
    a spawn-sh -- 'kitty peaclock';       b 2.6
    a spawn-sh -- 'kitty cmatrix -abu 2'; b 2.6

    for _ in 1 2 3; do a switch-preset-column-width; b 1.3; done
    a switch-preset-column-width;          b 1.6
    a expand-column-to-available-width;    b 1.6

    a focus-column-left-or-last;   b 1.2
    a focus-column-left-or-last;   b 1.2
    a focus-column-right-or-first; b 1.2
    a focus-column-right-or-first; b 1.4
    a move-column-left;            b 1.4
    a move-column-right;           b 1.4

    # focus-column-last then consume-left is deterministic: the rightmost
    # window always has a column to its left, whatever the scroll position.
    a focus-column-last;            b 1.1
    a consume-or-expel-window-left; b 1.9
    a focus-window-up;              b 1.1
    a focus-window-down;            b 1.1
    a toggle-column-tabbed-display; b 2.0
    a focus-window-up;              b 1.3
    a focus-window-down;            b 1.3
    a toggle-column-tabbed-display; b 1.6
    a expel-window-from-column;     b 1.6

    # Always by name: niri renumbers idx as workspaces come and go.
    a move-column-to-workspace chat; b 2.0
    a focus-workspace files; b 1.6
    a focus-workspace chat;  b 1.6
    a focus-workspace files; b 1.6

    a open-overview;  b 2.6
    a close-overview; b 1.8

    "$HOME/.config/rofi/bin/launcher" >/dev/null 2>&1 &
    b 1.8; wtype -d 90 'kit'; b 1.4; wtype -k Return; b 3.0

    notify-send -a "Zen Browser" -i firefox "Download complete" \
                "niri-26.04.tar.gz  -  18.4 MB" -t 4000; b 3.0
    swaync-client -op -sw; b 2.4
    swaync-client -cp -sw; b 1.4
    swaync-client -C;      b 0.6

    sh "$HOME/.config/niri/scripts/quake.sh"; b 2.6
    sh "$HOME/.config/niri/scripts/quake.sh"; b 2.0
    b 1.2
    rec_stop
    echo "  -> act1.mkv"
}

rec2() {
    wp serenity.jpg; clean; player
    ws files
    term btop; width 50%; term peaclock; width 50%
    park; sleep 1.5
    rec_start act2
    goto 900 640 1.4
    goto 1460 28 2.0       # wifi drawer
    goto 1600 28 2.2       # brightness + mic drawer
    goto 1853 28 3.0       # date drawer + calendar tooltip
    goto 1560 300 0.4
    goto 900 640 1.6
    rec_stop
    echo "  -> act2.mkv"
}

video() {
    cd "$PNGDIR" || return 1
    ffmpeg -hide_banner -loglevel error -ss 2.0 -to 73.0 -i act1.mkv -c copy -y a1.mkv
    ffmpeg -hide_banner -loglevel error -ss 1.5 -to 14.5 -i act2.mkv -c copy -y a2.mkv
    ffmpeg -hide_banner -loglevel error -i a1.mkv -i a2.mkv \
        -filter_complex '[0:v][1:v]concat=n=2:v=1[v]' -map '[v]' \
        -c:v libx264 -crf 20 -preset slow -pix_fmt yuv420p -movflags +faststart \
        -an -y demo.mp4
    # Only the loop is tracked; the mp4 goes on a release, same reasoning as
    # the wallpapers in .chezmoiignore.
    ffmpeg -hide_banner -loglevel error -ss 44 -t 15 -i demo.mp4 \
        -vf 'fps=20,scale=960:-2:flags=lanczos' \
        -c:v libwebp_anim -lossless 0 -q:v 68 -loop 0 -an -y "$HERE/demo.webp"
    rm -f a1.mkv a2.mkv
    echo "  -> demo.mp4 ($(du -h demo.mp4 | cut -f1)) and demo.webp ($(du -h "$HERE/demo.webp" | cut -f1))"
}

pack() {
    n=0
    for f in "$PNGDIR"/*.png; do
        [ -e "$f" ] || continue
        b=$(basename "$f" .png)
        magick "$f" -alpha off -quality 90 "$HERE/$b.webp"
        n=$((n + 1))
    done
    echo "packed $n webp into $HERE"
}

SCENES='empty rofi swaync notification work monitor fetch apps dev overview quake bar osd sddm'

list() {
    i=0
    for s in $SCENES; do i=$((i + 1)); printf '%2d  %s\n' "$i" "$s"; done
}

resolve() {
    case "$1" in
        ''|*[!0-9]*) echo "$1" ;;
        *) i=0; for s in $SCENES; do i=$((i + 1))
               [ "$i" = "$1" ] && { echo "$s"; return; }
           done; echo "$1" ;;
    esac
}

[ $# -gt 0 ] || { echo "usage: $(basename "$0") list|prep|all|rec1|rec2|video|pack|restore|<scene>..." >&2
                  list >&2; exit 1; }

for arg in "$@"; do
    case "$(resolve "$arg")" in
        list)    list ;;
        prep)    prep ;;
        restore) restore ;;
        pack)    pack ;;
        rec1)    echo "== rec1"; rec1 ;;
        rec2)    echo "== rec2"; rec2 ;;
        video)   echo "== video"; video ;;
        all)     for s in $SCENES; do echo "== $s"; "scene_$s"; done ;;
        *)       name=$(resolve "$arg")
                 command -v "scene_$name" >/dev/null 2>&1 \
                     || { echo "unknown scene: $arg" >&2; list >&2; exit 1; }
                 echo "== $name"; "scene_$name" ;;
    esac
done
