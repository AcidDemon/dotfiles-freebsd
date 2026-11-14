import QtQuick
import Quickshell
import qs.theme

Pill {
    id: root

    property int calendarMode: 0
    property int calendarOffset: 0
    readonly property var deLocale: Qt.locale("de_DE")

    fill: Theme.accClock
    hoverFill: Base16.base07
    animated: false

    onHoveredChanged: if (!hovered) calendarOffset = 0

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Drawer {
        open: root.hovered

        Cell {
            hoverable: false

            Txt {
                text: root.deLocale.toString(clock.date, "ddd dd.MM").replace(".", "")
                color: Theme.onAccent
                font.weight: Font.DemiBold
            }
        }
    }

    Cell {
        hoverable: false
        panel: calendar
        onClicked: button => {
            if (button === Qt.RightButton) {
                root.calendarMode = 1 - root.calendarMode;
                root.calendarOffset = 0;
            }
        }
        onScrolled: steps => root.calendarOffset += steps

        Glyph {
            text: "󰥔"
            color: Theme.onAccent
        }

        Txt {
            fade: true
            text: Qt.formatTime(clock.date, "HH:mm")
            color: Theme.onAccent
            font.weight: Font.DemiBold
        }
    }

    Component {
        id: calendar

        Calendar {
            mode: root.calendarMode
            offset: root.calendarOffset
            today: clock.date
        }
    }
}
