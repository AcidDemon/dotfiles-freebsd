import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.bar
import qs.theme

ColumnLayout {
    id: root

    required property string groupKey
    property bool expanded: false
    readonly property var group: Notifs.groups.find(g => g.key === groupKey) ?? null
    readonly property var items: group?.items ?? []
    readonly property bool many: items.length > 1

    spacing: 6

    onManyChanged: if (!many) expanded = false

    RowLayout {
        Layout.fillWidth: true
        visible: root.many
        spacing: 8

        Txt {
            Layout.fillWidth: true
            text: `${root.group?.name ?? ""}  ·  ${root.items.length}`
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: 13
            color: Theme.fgDim
        }

        Keycap {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 8
            depth: 2
            glyph: root.expanded ? "\u{F0143}" : "\u{F0140}"
            glyphSize: 14
            onClicked: root.expanded = !root.expanded
        }

        Keycap {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 8
            depth: 2
            glyph: "\u{F0156}"
            glyphSize: 14
            onClicked: {
                for (const n of root.items.slice()) n.dismiss();
            }
        }
    }

    Repeater {
        model: ScriptModel {
            values: root.expanded ? root.items : root.items.slice(0, 1)
        }

        delegate: NotificationSlot {
            required property var modelData

            Layout.fillWidth: true
            notification: modelData
            onActivated: action => {
                if (root.many && !root.expanded && !action) root.expanded = true;
                else Notifs.activate(modelData, action);
            }
        }
    }

    Item {
        visible: root.many && !root.expanded
        Layout.fillWidth: true
        Layout.preferredHeight: 8
        Layout.topMargin: -6

        Plastic {
            x: 8
            width: parent.width - 16
            height: 8
            color: Base16.base00
            radius: 8
            depth: 2
        }
    }
}
