import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.theme

ColumnLayout {
    id: root

    required property var modelData
    property bool expanded: false

    signal activated

    spacing: 1

    Rectangle {
        visible: root.modelData.isSeparator
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.margins: 3
        color: Theme.cardBorder
    }

    Rectangle {
        visible: !root.modelData.isSeparator
        Layout.fillWidth: true
        implicitWidth: row.implicitWidth + 16
        implicitHeight: row.implicitHeight + 8
        radius: 8
        color: hover.hovered && root.modelData.enabled ? Theme.pillHover : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        RowLayout {
            id: row

            x: 8
            width: parent.width - 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Glyph {
                visible: root.modelData.buttonType !== QsMenuButtonType.None
                size: 14
                text: root.modelData.checkState === Qt.Checked ? "󰄲" : "󰄱"
            }

            IconImage {
                visible: root.modelData.icon !== ""
                implicitSize: 16
                source: root.modelData.icon
            }

            Txt {
                Layout.fillWidth: true
                text: root.modelData.text.replace(/_(?=\S)/, "")
                textFormat: Text.PlainText
                font.pixelSize: 14
                color: root.modelData.enabled ? Theme.fg : Theme.fgDim
            }

            Glyph {
                visible: root.modelData.hasChildren
                size: 14
                text: root.expanded ? "󰅀" : "󰅂"
            }
        }

        HoverHandler {
            id: hover
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.modelData.enabled
            onClicked: {
                if (root.modelData.hasChildren) {
                    root.expanded = !root.expanded;
                } else {
                    root.modelData.triggered();
                    root.activated();
                }
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        active: root.expanded
        source: "TrayMenuList.qml"
        onLoaded: {
            item.menu = root.modelData;
            item.activated.connect(root.activated);
        }
    }
}
