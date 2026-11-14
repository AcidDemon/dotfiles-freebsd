import QtQuick
import qs.theme
import "Parse.js" as Parse

Pill {
    id: root

    readonly property var bat: Sys.battery
    readonly property bool charging: bat?.status === "Charging"
    readonly property color tint: charging ? Theme.stCharging
        : (bat?.capacity ?? 100) <= 15 ? Theme.stCritical
        : (bat?.capacity ?? 100) <= 30 ? Theme.stWarning
        : Theme.accBattery

    shown: bat !== null

    Cell {
        tip: `${root.bat?.capacity ?? 0}%  ·  ${root.bat?.timeTo ?? ""}`

        Glyph {
            text: root.charging ? "󰂄" : Parse.iconFor(root.bat?.capacity ?? 0, ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"])
            color: root.tint
            pulsing: !root.charging && (root.bat?.capacity ?? 100) <= 15
        }
        NumberText { value: root.bat?.capacity ?? 0; color: root.tint }
    }
}
