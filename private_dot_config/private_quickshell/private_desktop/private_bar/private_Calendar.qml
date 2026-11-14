import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.theme

Item {
    id: root

    property int mode: 0
    property int offset: 0
    required property date today

    readonly property var deLocale: Qt.locale("de_DE")
    readonly property int cellWidth: 28
    readonly property int cellHeight: 22
    readonly property int monthIndex: today.getFullYear() * 12 + today.getMonth() + offset
    readonly property int shownYear: mode === 1 ? today.getFullYear() + offset : Math.floor(monthIndex / 12)

    component Label: Txt {
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
    }

    component MonthBlock: ColumnLayout {
        id: block

        required property int year
        required property int month
        property bool withYear: false
        readonly property int weeks: Math.ceil((((new Date(year, month, 1).getDay() + 6) % 7) + new Date(year, month + 1, 0).getDate()) / 7)

        spacing: 2

        Label {
            Layout.fillWidth: true
            text: root.deLocale.monthName(block.month) + (block.withYear ? ` ${block.year}` : "")
            color: Base16.muted ? Theme.accClock : Base16.base07
            font.bold: true
        }

        RowLayout {
            spacing: 8

            ColumnLayout {
                spacing: 0

                DayOfWeekRow {
                    Layout.preferredWidth: 7 * root.cellWidth
                    Layout.preferredHeight: root.cellHeight
                    locale: root.deLocale
                    spacing: 0
                    padding: 0

                    delegate: Label {
                        required property var model

                        text: model.shortName.replace(".", "")
                        color: Theme.light || Base16.muted ? Theme.fgDim : Base16.base0A
                        font.bold: true
                    }
                }

                MonthGrid {
                    id: grid

                    Layout.preferredWidth: 7 * root.cellWidth
                    Layout.preferredHeight: 6 * root.cellHeight
                    month: block.month
                    year: block.year
                    locale: root.deLocale
                    spacing: 0
                    padding: 0

                    delegate: Label {
                        required property var model

                        readonly property bool isToday: model.year === root.today.getFullYear()
                            && model.month === root.today.getMonth()
                            && model.day === root.today.getDate()

                        opacity: model.month === grid.month ? 1 : 0
                        text: model.day
                        color: isToday ? Base16.base0D : Theme.fg
                        font.bold: isToday
                        font.underline: isToday
                    }
                }
            }

            WeekNumberColumn {
                Layout.alignment: Qt.AlignBottom
                Layout.preferredWidth: 44
                Layout.preferredHeight: 6 * root.cellHeight
                month: block.month
                year: block.year
                locale: root.deLocale
                spacing: 0
                padding: 0

                delegate: Label {
                    required property var model
                    required property int index

                    opacity: index < block.weeks ? 1 : 0
                    text: "KW" + model.weekNumber
                    color: Theme.light || Base16.muted ? Theme.fgDim : Base16.base0C
                    font.bold: true
                }
            }
        }
    }

    implicitWidth: (mode === 1 ? yearView.implicitWidth : monthView.implicitWidth) + 20
    implicitHeight: (mode === 1 ? yearView.implicitHeight : monthView.implicitHeight) + 16

    MonthBlock {
        id: monthView

        x: 10
        y: 8
        visible: root.mode === 0
        year: Math.floor(root.monthIndex / 12)
        month: ((root.monthIndex % 12) + 12) % 12
        withYear: true
    }

    ColumnLayout {
        id: yearView

        x: 10
        y: 8
        visible: root.mode === 1
        spacing: 6

        Label {
            Layout.fillWidth: true
            text: root.shownYear
            color: Base16.muted ? Theme.accClock : Base16.base07
            font.bold: true
        }

        GridLayout {
            columns: 3
            columnSpacing: 16
            rowSpacing: 8

            Repeater {
                model: root.mode === 1 ? 12 : 0

                delegate: MonthBlock {
                    required property int index

                    year: root.shownYear
                    month: index
                }
            }
        }
    }
}
