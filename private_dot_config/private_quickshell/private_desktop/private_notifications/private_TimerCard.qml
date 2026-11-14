import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.theme
import "Duration.js" as Duration

ColumnLayout {
    id: root

    readonly property var presets: [1, 2, 5, 10, 15, 30]
    readonly property bool idle: ShellTimer.phase === "idle"

    signal releaseFocus

    spacing: 8

    Plastic {
        Layout.fillWidth: true
        Layout.preferredHeight: 66
        color: Theme.crust
        radius: 12
        recessed: true
        depth: 0

        Txt {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -3
            }
            text: Duration.formatClock(ShellTimer.remainingMs)
            font.pixelSize: 34
            font.weight: Font.DemiBold
            color: ShellTimer.phase === "running" ? Theme.accClock
                : ShellTimer.phase === "paused" ? Theme.stWarning
                : ShellTimer.remainingMs > 0 ? Theme.fg
                : Theme.overlay0
        }

        Rectangle {
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: 12
                bottomMargin: 6
            }
            visible: !root.idle
            width: (parent.width - 24) * (ShellTimer.durationMs > 0 ? ShellTimer.remainingMs / ShellTimer.durationMs : 0)
            height: 3
            radius: 1.5
            color: Theme.accClock
        }
    }

    Grid {
        id: presetRow

        readonly property real keyWidth: (parent.width - 5 * columnSpacing) / 6

        columns: 6
        columnSpacing: 5

        Repeater {
            model: root.presets

            delegate: Keycap {
                required property int modelData

                width: presetRow.keyWidth
                height: 34
                radius: 8
                depth: 3
                label: `${modelData} min`
                labelSize: 12
                enabled: root.idle
                active: ShellTimer.durationMs === modelData * 60000
                onClicked: {
                    custom.text = "";
                    ShellTimer.select(modelData * 60000);
                    root.releaseFocus();
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        PlasticField {
            id: custom

            Layout.fillWidth: true
            Layout.preferredHeight: 38
            enabled: root.idle
            placeholder: "Custom: 45 or 1:30"
            validator: RegularExpressionValidator {
                regularExpression: /[0-9:]*/
            }
            onEdited: ShellTimer.select(Duration.parseDuration(text))
            onAccepted: {
                ShellTimer.start();
                root.releaseFocus();
            }
            onEscaped: root.releaseFocus()
        }

        Keycap {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 38
            depth: 3
            glyph: "\u{F040A}"
            glyphSize: 18
            enabled: ShellTimer.phase !== "running" && ShellTimer.remainingMs > 0
            onClicked: ShellTimer.start()
        }

        Keycap {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 38
            depth: 3
            glyph: "\u{F03E4}"
            glyphSize: 18
            enabled: ShellTimer.phase === "running"
            onClicked: ShellTimer.pause()
        }

        Keycap {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 38
            depth: 3
            glyph: "\u{F04DB}"
            glyphSize: 18
            enabled: !root.idle
            onClicked: ShellTimer.stop()
        }
    }
}
