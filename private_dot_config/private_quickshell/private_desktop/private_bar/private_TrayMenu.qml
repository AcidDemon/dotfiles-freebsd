import QtQuick
import Quickshell
import qs.theme

PopupWindow {
    id: root

    required property var trayItem
    required property Item anchorItem
    property bool opened: false

    signal dismissed

    anchor {
        item: anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
    }
    grabFocus: true
    color: "transparent"
    visible: true
    implicitWidth: list.implicitWidth + 10
    implicitHeight: list.implicitHeight + 16

    onVisibleChanged: if (!visible) dismissed()
    Component.onCompleted: opened = true

    Rectangle {
        y: root.opened ? 6 : 0
        width: parent.width
        height: parent.height - 6
        opacity: root.opened ? 1 : 0
        color: Theme.menuBg
        radius: 12
        border {
            width: 1
            color: Theme.cardBorder
        }

        Behavior on y {
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast }
        }

        TrayMenuList {
            id: list

            x: 5
            y: 5
            width: parent.width - 10
            menu: root.trayItem.menu
            onActivated: root.visible = false
        }
    }
}
