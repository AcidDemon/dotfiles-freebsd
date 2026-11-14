import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root

    default property alias content: row.data
    property bool open: false

    clip: true
    implicitHeight: Theme.pillHeight
    implicitWidth: open ? row.implicitWidth : 0

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animDrawer; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: row

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: 0
        opacity: root.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animDrawer }
        }
    }
}
