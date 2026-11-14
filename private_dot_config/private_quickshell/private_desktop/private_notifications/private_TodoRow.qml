import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.theme
import "Todo.js" as Todo

Item {
    id: root

    required property var modelData
    readonly property bool overdue: !modelData.done && !!modelData.due && modelData.due < Todos.today

    height: 30

    NumberAnimation on opacity {
        from: 0
        to: 1
        duration: Theme.animNormal
    }

    HoverHandler {
        id: hover
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 6
            rightMargin: 6
        }
        spacing: 8

        Plastic {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            color: root.modelData.done ? Theme.accClock : Base16.base02
            radius: 6
            depth: 2

            Glyph {
                anchors.centerIn: parent
                visible: root.modelData.done
                text: "\u{F012C}"
                size: 13
                color: Theme.crust
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Todos.toggle(root.modelData.id)
            }
        }

        Txt {
            Layout.fillWidth: true
            text: root.modelData.text
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: 14
            font.strikeout: root.modelData.done
            color: root.modelData.done ? Theme.overlay0 : Theme.fg
        }

        Txt {
            visible: !!root.modelData.due
            text: Todo.dueLabel(root.modelData.due, Todos.today)
            font.pixelSize: 12
            color: root.overdue ? Theme.matchOnDark : root.modelData.done ? Theme.overlay0 : Theme.accClock
        }

        Keycap {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            opacity: hover.hovered ? 1 : 0
            radius: 6
            depth: 2
            glyph: "\u{F0156}"
            glyphSize: 12
            onClicked: Todos.remove(root.modelData.id)
        }
    }
}
