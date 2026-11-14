import QtQuick
import qs.theme

// The bar, and while peeking the launcher and notification panel, drawn small in a theme's colours.
Item {
    id: root

    required property var colors
    required property string name
    property bool peek: false

    readonly property real unit: height / 100
    readonly property color glass: Qt.alpha(colors.base00, 0.9)

    component Pill: Rectangle {
        height: root.unit * 4.2
        radius: height / 2
        color: root.colors.base02
    }

    component Line: Rectangle {
        height: root.unit * 1.4
        radius: height / 2
        color: Qt.alpha(root.colors.overlay1, 0.7)
    }

    Rectangle {
        id: rail

        x: root.unit * 1.2
        y: root.unit * 1.2
        width: root.width - 2 * x
        height: root.unit * 6.2
        radius: height / 2
        color: Qt.alpha(root.colors.crust, 0.78)
        border.width: 1
        border.color: Qt.alpha(root.colors.base02, 0.9)

        Row {
            anchors {
                left: parent.left
                leftMargin: root.unit
                verticalCenter: parent.verticalCenter
            }
            spacing: root.unit * 0.8

            Pill { width: height; color: root.colors.base0E }
            Pill { width: root.unit * 5; color: root.colors.base0D }
            Pill { width: root.unit * 4 }
            Pill { width: root.unit * 4 }
            Pill { width: root.unit * 4 }
        }

        Rectangle {
            anchors.centerIn: parent
            width: islandText.implicitWidth + root.unit * 6
            height: root.unit * 4.4
            radius: height / 2
            color: Qt.darker(root.colors.crust, 1.5)
            border.width: 1
            border.color: Qt.alpha("white", 0.08)

            Text {
                id: islandText

                anchors.centerIn: parent
                text: root.name
                color: root.colors.base05
                font.family: Theme.fontFamily
                font.pixelSize: root.unit * 2.4
                font.weight: Font.DemiBold
            }
        }

        Row {
            anchors {
                right: parent.right
                rightMargin: root.unit
                verticalCenter: parent.verticalCenter
            }
            spacing: root.unit * 0.8

            Pill { width: root.unit * 9 }
            Pill { width: root.unit * 6 }
            Pill { width: root.unit * 7 }
            Pill { width: root.unit * 10; color: root.colors.base0D }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.peek ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
        }

        // launcher
        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
            }
            width: Math.min(root.width * 0.34, root.unit * 90)
            height: root.unit * 46
            topLeftRadius: root.unit * 3
            topRightRadius: root.unit * 3
            color: root.glass
            border.width: 1
            border.color: Qt.alpha(root.colors.base03, 0.8)

            Column {
                anchors {
                    fill: parent
                    margins: root.unit * 2.4
                }
                spacing: root.unit * 1.6

                Rectangle {
                    width: parent.width
                    height: root.unit * 6
                    radius: height / 2
                    color: root.colors.base02

                    Line {
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.unit * 2
                        width: parent.width * 0.3
                        color: root.colors.base05
                    }
                }

                Rectangle {
                    width: parent.width
                    height: root.unit * 5
                    radius: root.unit * 1.2
                    color: root.colors.base0D
                }

                Repeater {
                    model: [0.62, 0.48, 0.55, 0.4]

                    Line {
                        required property real modelData

                        width: parent.width * modelData
                    }
                }
            }
        }

        // notification panel
        Rectangle {
            anchors {
                right: parent.right
                rightMargin: root.unit * 1.2
                top: parent.top
                topMargin: rail.y + rail.height + root.unit * 1.2
                bottom: parent.bottom
                bottomMargin: root.unit * 1.2
            }
            width: Math.min(root.width * 0.2, root.unit * 56)
            radius: root.unit * 2.4
            color: root.glass
            border.width: 1
            border.color: Qt.alpha(root.colors.base03, 0.8)

            Column {
                anchors {
                    fill: parent
                    margins: root.unit * 1.8
                }
                spacing: root.unit * 1.4

                Grid {
                    columns: 3
                    spacing: root.unit * 1
                    width: parent.width

                    Repeater {
                        model: [true, true, false, true, false, false]

                        Rectangle {
                            required property bool modelData

                            width: (parent.width - 2 * parent.spacing) / 3
                            height: root.unit * 6
                            radius: root.unit * 1.4
                            color: modelData ? root.colors.base0D : root.colors.base02
                        }
                    }
                }

                Repeater {
                    model: [0.7, 0.45]

                    Rectangle {
                        required property real modelData

                        width: parent.width
                        height: root.unit * 1.6
                        radius: height / 2
                        color: root.colors.base02

                        Rectangle {
                            width: parent.width * parent.modelData
                            height: parent.height
                            radius: height / 2
                            color: root.colors.base0E
                        }
                    }
                }

                Repeater {
                    model: 3

                    Rectangle {
                        width: parent.width
                        height: root.unit * 9
                        radius: root.unit * 1.6
                        color: Qt.alpha(root.colors.base02, 0.8)
                    }
                }
            }
        }
    }
}
