import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme

// The dark pill in the middle of the bar: the current track while a player has one,
// a new notification for a few seconds, and nothing at all otherwise.
Item {
    id: root

    // never wider than this, so it stays centred without touching the groups beside it
    property real maxWidth: 600
    property var note: null
    readonly property var player: Sys.player
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string track: [player?.trackArtist, player?.trackTitle].filter(Boolean).join(" — ")
    readonly property string kind: note ? "note" : track !== "" ? "media" : ""
    readonly property bool shown: kind !== "" && maxWidth > 120

    implicitHeight: Theme.pillHeight
    implicitWidth: shown ? Math.min(maxWidth, content.implicitWidth + 28) : 0
    opacity: shown ? 1 : 0

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
        NumberAnimation { duration: Theme.animNormal }
    }

    Connections {
        target: Notifs

        function onPopupsChanged() {
            const newest = Notifs.popups[0] ?? null;
            if (newest && newest !== root.note) {
                root.note = newest;
                noteTimer.restart();
            }
        }
    }

    Timer {
        id: noteTimer

        interval: 4000
        onTriggered: root.note = null
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.islandFill
        border.width: 1
        border.color: Qt.alpha("white", 0.08)
        clip: true

        RowLayout {
            id: content

            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            width: Math.min(implicitWidth, root.maxWidth - 28)
            spacing: 8

            Glyph {
                text: root.kind === "note" ? "󰂞"
                    : root.player?.desktopEntry === "spotify" ? "󰓇" : "󰝚"
                size: 17
                color: root.kind === "note" ? Theme.accWindow
                    : root.playing ? Theme.accMedia : Theme.fgDim
            }

            Marquee {
                Layout.fillWidth: true
                Layout.maximumWidth: implicitWidth
                text: root.kind === "note"
                    ? [root.note?.appName, root.note?.summary].filter(Boolean).join(": ")
                    : root.track
                color: root.kind === "media" && !root.playing ? Theme.fgDim : Theme.fg
            }

            // a small level meter that dances while music plays
            Row {
                visible: root.kind === "media"
                spacing: 2

                Repeater {
                    model: [9, 17, 12, 19, 8, 15]

                    delegate: Rectangle {
                        id: bar

                        required property int modelData
                        required property int index

                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: root.playing ? modelData : 4
                        radius: 1.5
                        color: root.playing ? Theme.accMedia : Theme.fgDim

                        SequentialAnimation on height {
                            running: root.playing && root.kind === "media"
                            loops: Animation.Infinite

                            NumberAnimation { to: 4 + (bar.modelData * 7 % 13); duration: 260 + bar.index * 47; easing.type: Easing.InOutSine }
                            NumberAnimation { to: bar.modelData; duration: 240 + bar.index * 31; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }

        MouseArea {
            property int wheelRest: 0

            anchors.fill: parent
            onClicked: {
                if (root.kind === "note") Notifs.panelOpen = true;
                else root.player?.togglePlaying();
            }
            onWheel: event => {
                if (root.kind !== "media") return;
                wheelRest += event.angleDelta.y;
                const steps = Math.trunc(wheelRest / 120);
                if (steps === 0) return;
                wheelRest -= steps * 120;
                if (steps > 0) root.player.next();
                else root.player.previous();
            }
        }
    }
}
