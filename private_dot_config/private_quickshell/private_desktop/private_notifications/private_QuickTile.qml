import QtQuick
import qs.bar
import qs.theme

// A wide raised toggle: icon, name and current state. Filled with its accent while on.
Plastic {
    id: root

    property string glyph: ""
    property string title: ""
    property string status: ""
    property bool on: false
    property color accent: Theme.accClock
    readonly property color base: on ? accent : Base16.base02

    signal clicked
    signal rightClicked

    implicitHeight: 64
    radius: height / 2
    depth: 4
    pressed: mouse.pressed
    // lighter under the pointer, darker while held, on or off alike
    color: mouse.pressed ? Qt.darker(base, 1.15) : hover.hovered ? Qt.lighter(base, on ? 1.08 : 1.25) : base
    opacity: enabled ? 1 : 0.45

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    Glyph {
        x: 22
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        size: 20
        color: root.on ? Theme.onAccent : Theme.fg
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: 56
            rightMargin: 14
            verticalCenter: parent.verticalCenter
        }
        spacing: 1

        Txt {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: root.on ? Theme.onAccent : Theme.fg
        }

        Txt {
            width: parent.width
            text: root.status
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: 12
            color: root.on ? Qt.alpha(Theme.onAccent, 0.75) : Theme.fgDim
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) root.rightClicked();
            else root.clicked();
        }
    }
}
