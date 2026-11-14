import QtQuick
import qs.theme

Plastic {
    id: root

    property string glyph: ""
    property real glyphSize: 20
    property string label: ""
    property real labelSize: 13
    property bool active: false
    property color baseColor: Base16.base02

    signal clicked

    implicitWidth: label !== "" ? labelText.implicitWidth + 24 : 0
    opacity: enabled ? 1 : 0.45
    color: active ? Theme.accClock : hover.hovered && enabled ? Qt.lighter(baseColor, 1.2) : baseColor
    radius: 10
    depth: 4
    pressed: mouse.pressed

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    Glyph {
        anchors.centerIn: parent
        visible: root.glyph !== ""
        text: root.glyph
        color: root.active ? Theme.onAccent : Theme.fg
        size: root.glyphSize
    }

    Txt {
        id: labelText

        anchors.centerIn: parent
        visible: root.label !== ""
        text: root.label
        textFormat: Text.PlainText
        color: root.active ? Theme.onAccent : Theme.fg
        font.pixelSize: root.labelSize
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        onClicked: root.clicked()
    }
}
