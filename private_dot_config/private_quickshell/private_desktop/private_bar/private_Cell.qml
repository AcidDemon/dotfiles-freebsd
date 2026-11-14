import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme

Item {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property string tip: ""
    property Component panel: null
    property real padLeft: 7
    property real padRight: 7
    property bool hoverable: true
    readonly property bool hovered: hover.hovered

    signal pressed(int button)
    signal clicked(int button)
    signal scrolled(int steps)

    implicitWidth: row.implicitWidth + padLeft + padRight
    implicitHeight: Theme.pillHeight

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.pillHover
        opacity: root.hoverable && root.hovered ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast }
        }
    }

    RowLayout {
        id: row

        x: root.padLeft
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.gap
    }

    HoverHandler {
        id: hover

        onHoveredChanged: {
            const card = root.QsWindow.window?.card;
            if (!card) return;
            if (hovered) card.enter(root);
            else card.leave(root);
        }
    }

    MouseArea {
        property int wheelRest: 0

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onPressed: event => root.pressed(event.button)
        onClicked: event => root.clicked(event.button)
        onWheel: event => {
            wheelRest += event.angleDelta.y;
            const steps = Math.trunc(wheelRest / 120);
            if (steps !== 0) {
                wheelRest -= steps * 120;
                root.scrolled(steps);
            }
        }
    }
}
