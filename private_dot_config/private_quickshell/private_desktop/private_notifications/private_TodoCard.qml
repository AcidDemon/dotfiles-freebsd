import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.bar
import qs.theme
import "Todo.js" as Todo

ColumnLayout {
    id: root

    readonly property var due: Todo.parseDue(dueField.text, Todos.today)
    readonly property bool canAdd: task.text.trim() !== "" && due !== null
    readonly property var quickDates: [
        { label: "Today", days: 0 },
        { label: "Tomorrow", days: 1 },
        { label: "Next week", days: 7 }
    ]

    signal releaseFocus

    function focusInput() {
        task.focusInput();
    }

    function setDue(iso) {
        dueField.text = iso ? Todo.shortDate(iso) + (iso.slice(0, 4) === Todos.today.slice(0, 4) ? "" : `.${iso.slice(0, 4)}`) : "";
        task.focusInput();
    }

    function add() {
        if (!canAdd) return;
        Todos.add(task.text.trim(), due);
        task.text = "";
        dueField.text = "";
        task.focusInput();
    }

    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        PlasticField {
            id: task

            Layout.fillWidth: true
            Layout.preferredHeight: 36
            placeholder: "New to do"
            maximumLength: 200
            onAccepted: root.add()
            onEscaped: root.releaseFocus()
        }

        PlasticField {
            id: dueField

            Layout.preferredWidth: 92
            Layout.preferredHeight: 36
            placeholder: "Due 24.12"
            invalid: root.due === null
            maximumLength: 10
            onAccepted: root.add()
            onEscaped: root.releaseFocus()
        }

        Keycap {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 36
            depth: 3
            glyph: "\u{F0415}"
            glyphSize: 18
            enabled: root.canAdd
            onClicked: root.add()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 5

        Repeater {
            model: root.quickDates

            delegate: Keycap {
                required property var modelData

                readonly property string iso: Todo.addDays(Todos.today, modelData.days)

                Layout.preferredHeight: 28
                radius: 8
                depth: 2
                label: modelData.label
                labelSize: 12
                active: root.due === iso
                onClicked: root.setDue(active ? "" : iso)
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Keycap {
            visible: Todos.items.some(item => item.done)
            Layout.preferredHeight: 28
            radius: 8
            depth: 2
            label: "Clear done"
            labelSize: 12
            onClicked: Todos.clearDone()
        }
    }

    Plastic {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Theme.crust
        radius: 10
        recessed: true
        depth: 0

        ListView {
            id: list

            anchors {
                fill: parent
                margins: 3
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: Todos.sorted
                objectProp: "id"
            }

            delegate: TodoRow {
                width: ListView.view.width
            }

            displaced: Transition {
                NumberAnimation { property: "y"; duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }
        }

        Txt {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "Nothing to do"
            font.pixelSize: 13
            color: Theme.overlay0
        }
    }
}
