import QtQuick
import qs.theme
import "Parse.js" as Parse

Pill {
    id: root

    readonly property var mem: Sys.mem
    readonly property var temp: Sys.temp
    readonly property color tempText: temp?.cls === "critical" ? Theme.stCritical
        : temp?.cls === "warning" ? Theme.stWarning
        : Theme.fg

    Cell {
        tip: Parse.cpuTooltip(Sys.cpuUsage, Sys.load)

        Glyph { text: "󰻠"; color: Theme.accCpu }
        NumberText { value: Sys.cpu; padTo: 2 }
    }

    Sep {}

    Cell {
        tip: `RAM   ${root.mem.usedG.toFixed(2)} G used   ·   ${root.mem.pct}%\n      ${root.mem.availG.toFixed(2)} G available of ${root.mem.totalG.toFixed(2)} G\n\nSwap  ${root.mem.swapUsedG.toFixed(2)} G used   ·   ${root.mem.swapPct}%`

        Glyph { text: "󰍛"; color: Theme.accMemory }
        NumberText { value: root.mem.usedG; decimals: 1; suffix: "G" }
    }

    Sep { visible: root.temp !== null }

    Cell {
        visible: root.temp !== null
        tip: root.temp?.tip ?? ""

        Glyph {
            text: "󰔏"
            color: root.temp?.cls === "good" ? Theme.accTemp : root.tempText
            pulsing: root.temp?.cls === "critical"
        }
        NumberText { value: root.temp?.value ?? 0; suffix: "°"; color: root.tempText }
    }
}
