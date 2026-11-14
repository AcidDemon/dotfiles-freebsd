import QtQuick
import Quickshell.Services.Mpris
import qs.theme

Pill {
    id: root

    readonly property var player: Sys.player
    readonly property string playerName: player?.desktopEntry || (player?.identity ?? "").toLowerCase()
    readonly property string status: {
        if (player?.isPlaying) return "playing";
        return player?.playbackState === MprisPlaybackState.Paused ? "paused" : "stopped";
    }

    leftInset: 12
    pad: 0
    shown: player !== null

    // the track itself shows in the island in the middle of the bar
    Cell {
        padLeft: 12
        padRight: 6
        tip: `${root.playerName} · ${root.status}\n${root.player?.trackArtist ?? ""} — ${root.player?.trackTitle ?? ""}`
        onScrolled: steps => steps > 0 ? root.player.next() : root.player.previous()

        Glyph {
            text: root.playerName === "spotify" ? "󰓇" : "󰝚"
            size: 17
            color: root.status === "playing" ? Theme.accMedia : Theme.fgDim
        }
    }

    Cell {
        padLeft: 5
        padRight: 5
        onClicked: root.player.previous()

        Glyph { text: "󰒮"; size: 17; color: Theme.accMedia }
    }

    Cell {
        padLeft: 5
        padRight: 5
        onClicked: root.player.togglePlaying()

        Glyph { text: root.player?.isPlaying ? "󰏤" : "󰐊"; size: 17; color: Theme.accMedia }
    }

    Cell {
        padLeft: 5
        padRight: 12
        onClicked: root.player.next()

        Glyph { text: "󰒭"; size: 17; color: Theme.accMedia }
    }
}
