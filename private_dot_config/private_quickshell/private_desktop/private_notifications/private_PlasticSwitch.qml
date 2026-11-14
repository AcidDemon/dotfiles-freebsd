import QtQuick
import qs.theme

Item {
    id: root

    property bool checked: false

    signal toggled

    implicitWidth: 56
    implicitHeight: 28

    Plastic {
        anchors.fill: parent
        color: root.checked ? Qt.darker(Theme.accClock, 1.6) : Theme.crust
        radius: height / 2
        recessed: true
        depth: 0
    }

    Plastic {
        x: root.checked ? parent.width - width - 3 : 3
        y: 3
        width: parent.height - 6
        height: parent.height - 6
        color: root.checked ? Theme.accClock : Base16.base04
        radius: width / 2
        depth: 2

        Behavior on x {
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutBack }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggled()
    }
}
