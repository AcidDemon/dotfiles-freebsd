import QtQuick
import qs.theme

// Frosted stripes along a theme card's slanted sides: the name on the left, the colours on the right.
Item {
    id: root

    required property Item card
    required property var colors
    required property string name

    readonly property real k: card.shift
    readonly property real h: card.height
    readonly property real thickness: Math.max(20, h * 0.13)
    readonly property real angle: Math.atan2(-h, Math.max(0.001, k)) * 180 / Math.PI

    anchors.fill: parent
    visible: opacity > 0

    component Stripe: Rectangle {
        height: root.thickness
        radius: height / 2
        rotation: root.angle
        color: Qt.alpha(root.colors.crust, 0.72)
        border.width: 1
        border.color: Qt.alpha("white", 0.14)
    }

    Stripe {
        width: nameText.implicitWidth + root.thickness * 1.2
        x: root.k / 2 - width / 2
        y: root.h / 2 - height / 2

        Text {
            id: nameText

            anchors.centerIn: parent
            text: root.name
            color: root.colors.base05
            font.family: Theme.fontFamily
            font.pixelSize: root.thickness * 0.5
            font.weight: Font.DemiBold
        }
    }

    Stripe {
        width: dots.implicitWidth + root.thickness
        x: root.card.width - root.k / 2 - width / 2
        y: root.h / 2 - height / 2

        Row {
            id: dots

            anchors.centerIn: parent
            spacing: root.thickness * 0.22

            Repeater {
                model: ["base0E", "base0D", "base08", "base0A", "base0B"]

                Rectangle {
                    required property string modelData

                    width: root.thickness * 0.42
                    height: width
                    radius: width / 2
                    color: root.colors[modelData]
                }
            }
        }
    }
}
