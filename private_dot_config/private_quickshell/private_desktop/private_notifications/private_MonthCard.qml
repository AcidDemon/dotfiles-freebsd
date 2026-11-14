import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.bar
import qs.theme
import "Duration.js" as Duration
import "Todo.js" as Todo

ColumnLayout {
    id: root

    property int offset: 0
    readonly property var deLocale: Qt.locale("de_DE")
    readonly property date today: clock.date
    readonly property int monthIndex: today.getFullYear() * 12 + today.getMonth() + offset
    readonly property int year: Math.floor(monthIndex / 12)
    readonly property int month: ((monthIndex % 12) + 12) % 12
    readonly property var cells: Duration.monthCells(year, month)
    readonly property int weekCount: cells.length / 7
    readonly property var weekdays: [1, 2, 3, 4, 5, 6, 0].map(day => deLocale.dayName(day, Locale.ShortFormat).replace(".", ""))

    signal dayClicked(string iso)

    function isToday(day) {
        return day === today.getDate() && month === today.getMonth() && year === today.getFullYear();
    }

    spacing: 4

    SystemClock {
        id: clock

        precision: SystemClock.Hours
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Keycap {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 30
            radius: 8
            depth: 3
            glyph: "\u{F0141}"
            glyphSize: 18
            onClicked: root.offset -= 1
        }

        Txt {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: `${root.deLocale.monthName(root.month)} ${root.year}`
            font.pixelSize: 15
            font.weight: Font.DemiBold

            MouseArea {
                anchors.fill: parent
                onClicked: root.offset = 0
            }
        }

        Keycap {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 30
            radius: 8
            depth: 3
            glyph: "\u{F0142}"
            glyphSize: 18
            onClicked: root.offset += 1
        }
    }

    Grid {
        id: grid

        readonly property real cellWidth: (parent.width - 44) / 7

        columns: 8
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: root.weekdays

            delegate: Txt {
                required property string modelData

                width: grid.cellWidth
                height: 24
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.accClock
            }
        }

        Item {
            width: 44
            height: 24
        }

        Repeater {
            model: root.weekCount * 8

            delegate: Item {
                id: cell

                required property int index
                readonly property bool isWeek: index % 8 === 7
                readonly property int row: Math.floor(index / 8)
                readonly property var day: isWeek ? null : root.cells[row * 7 + index % 8]
                readonly property var weekDay: root.cells.slice(row * 7, row * 7 + 7).find(d => d !== null)
                readonly property bool today: day !== null && root.isToday(day)
                readonly property string iso: day !== null ? Todo.isoDate(root.year, root.month, day) : ""
                readonly property string mark: Todos.marks[iso] ?? ""

                width: isWeek ? 44 : grid.cellWidth
                height: 26

                Rectangle {
                    anchors.centerIn: parent
                    width: 34
                    height: 25
                    radius: 8
                    color: Base16.base02
                    opacity: dayMouse.containsMouse && cell.day !== null && !cell.today ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
                }

                Plastic {
                    anchors.centerIn: parent
                    visible: cell.today
                    width: 34
                    height: 25
                    color: Theme.accClock
                    radius: 8
                    depth: 2
                }

                Txt {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: cell.isWeek ? `KW${Duration.weekNumber(root.year, root.month, cell.weekDay)}` : (cell.day ?? "")
                    font.pixelSize: cell.isWeek ? 12 : 14
                    font.weight: cell.today ? Font.DemiBold : Font.Medium
                    color: cell.isWeek ? Theme.overlay0 : cell.today ? Theme.onAccent : Theme.fg
                }

                Rectangle {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 2
                    }
                    visible: cell.mark !== ""
                    width: 5
                    height: 5
                    radius: 2.5
                    color: cell.mark === "overdue" ? Theme.matchOnDark : cell.today ? Theme.onAccent : Theme.accClock
                }

                MouseArea {
                    id: dayMouse

                    anchors.fill: parent
                    enabled: cell.day !== null
                    hoverEnabled: true
                    onClicked: root.dayClicked(cell.iso)
                }
            }
        }
    }
}
