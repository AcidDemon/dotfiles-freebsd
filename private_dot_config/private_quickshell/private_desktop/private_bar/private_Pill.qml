import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root

    default property alias content: row.data
    property real pad: 4
    property real leftInset: 4
    property real rightInset: 4
    property bool shown: true
    property bool animated: true
    property color fill: Theme.pillBg
    property color hoverFill: fill
    readonly property bool hovered: hover.hovered

    implicitHeight: Theme.pillHeight
    implicitWidth: shown ? row.implicitWidth + 2 * pad + leftInset + rightInset : 0
    opacity: shown ? 1 : 0

    Behavior on implicitWidth {
        enabled: root.animated
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
        NumberAnimation { duration: Theme.animNormal }
    }

    HoverHandler {
        id: hover
    }

    // raised like a keycap: darker wall underneath, light bevel on top
    Plastic {
        anchors {
            fill: parent
            leftMargin: root.leftInset
            rightMargin: root.rightInset
        }
        radius: height / 2
        depth: 3
        color: root.hovered ? root.hoverFill : root.fill
        clip: true

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        RowLayout {
            id: row

            x: root.pad - 1
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
        }
    }
}
