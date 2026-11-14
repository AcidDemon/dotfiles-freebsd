import QtQuick
import qs.theme

// Molded surface built from stacked rectangles: side wall, bevel rim, body.
Item {
    id: root

    default property alias content: body.data
    property color color: Base16.base02
    property real radius: 12
    property real depth: 3
    property bool recessed: false
    property bool pressed: false
    property bool squareBottom: false
    property bool squareRight: false
    readonly property real topRight: squareRight ? 0 : radius
    readonly property real bottomRight: squareRight || squareBottom ? 0 : radius
    readonly property real bottomLeft: squareBottom ? 0 : radius

    Rectangle {
        anchors {
            fill: parent
            topMargin: root.depth
        }
        visible: root.depth > 0
        color: Qt.darker(root.color, 2)
        topLeftRadius: root.radius
        topRightRadius: root.topRight
        bottomLeftRadius: root.bottomLeft
        bottomRightRadius: root.bottomRight
    }

    Rectangle {
        y: root.pressed ? root.depth : 0
        width: parent.width
        height: parent.height - root.depth
        topLeftRadius: root.radius
        topRightRadius: root.topRight
        bottomLeftRadius: root.bottomLeft
        bottomRightRadius: root.bottomRight
        gradient: Gradient {
            GradientStop { position: 0; color: root.recessed ? Qt.darker(root.color, 1.8) : Qt.lighter(root.color, 1.7) }
            GradientStop { position: 1; color: root.recessed ? Qt.lighter(Base16.base02, 1.15) : Qt.darker(root.color, 1.3) }
        }

        Behavior on y {
            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: body

            anchors {
                fill: parent
                margins: 1
                bottomMargin: root.squareBottom ? 0 : 1
                rightMargin: root.squareRight ? 0 : 1
            }
            topLeftRadius: Math.max(0, root.radius - 1)
            topRightRadius: Math.max(0, root.topRight - 1)
            bottomLeftRadius: Math.max(0, root.bottomLeft - 1)
            bottomRightRadius: Math.max(0, root.bottomRight - 1)
            gradient: Gradient {
                GradientStop { position: 0; color: root.recessed ? Qt.darker(root.color, 1.5) : Qt.lighter(root.color, 1.16) }
                GradientStop { position: root.recessed ? 0.12 : 0.5; color: root.color }
                GradientStop { position: 1; color: root.recessed ? root.color : Qt.darker(root.color, 1.14) }
            }
        }
    }
}
