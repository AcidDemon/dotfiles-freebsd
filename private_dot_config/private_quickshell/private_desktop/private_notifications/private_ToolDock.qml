import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.theme

Plastic {
    id: root

    property string page: ShellTimer.phase === "idle" ? "calendar" : "timer"

    signal releaseFocus

    onPageChanged: {
        if (page === "todo") todoCard.focusInput();
        else root.releaseFocus();
    }

    implicitHeight: 252
    color: Base16.base01
    radius: 14
    depth: 3

    RowLayout {
        anchors {
            fill: parent
            margins: 10
            bottomMargin: 8
        }
        spacing: 10

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 6

            Keycap {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                glyph: "\u{F00ED}"
                active: root.page === "calendar"
                onClicked: root.page = "calendar"
            }

            Keycap {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                glyph: "\u{F13AB}"
                active: root.page === "timer"
                onClicked: root.page = "timer"
            }

            Keycap {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                glyph: "\u{F0756}"
                active: root.page === "todo"
                onClicked: root.page = "todo"
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MonthCard {
                anchors.fill: parent
                visible: opacity > 0
                opacity: root.page === "calendar" ? 1 : 0
                onDayClicked: iso => {
                    root.page = "todo";
                    todoCard.setDue(iso);
                }

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast }
                }
            }

            TimerCard {
                anchors.fill: parent
                visible: opacity > 0
                opacity: root.page === "timer" ? 1 : 0
                onReleaseFocus: root.releaseFocus()

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast }
                }
            }

            TodoCard {
                id: todoCard

                anchors.fill: parent
                visible: opacity > 0
                opacity: root.page === "todo" ? 1 : 0
                onReleaseFocus: root.releaseFocus()

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast }
                }
            }
        }
    }
}
