import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.bar
import qs.theme

Plastic {
    id: root

    readonly property var player: Sys.player

    implicitHeight: 92
    color: Base16.base02
    radius: 16
    depth: 0

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 8
        }
        spacing: 12

        ClippingRectangle {
            Layout.preferredWidth: 68
            Layout.preferredHeight: 68
            radius: 12
            color: Theme.crust

            Glyph {
                anchors.centerIn: parent
                text: "󰝚"
                size: 28
                color: Theme.fgDim
            }

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Marquee {
                Layout.fillWidth: true
                text: root.player?.trackTitle ?? ""
                fade: true
                pixelSize: 16
                weight: Font.DemiBold
            }

            Marquee {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                fade: true
                pixelSize: 13
                color: Theme.subtext1
            }
        }

        Cell {
            onClicked: root.player?.previous()

            Glyph { text: "󰒮"; size: 18 }
        }

        Cell {
            onClicked: root.player?.togglePlaying()

            Glyph { text: root.player?.isPlaying ? "󰏤" : "󰐊"; size: 20 }
        }

        Cell {
            onClicked: root.player?.next()

            Glyph { text: "󰒭"; size: 18 }
        }
    }
}
