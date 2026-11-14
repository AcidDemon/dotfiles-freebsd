import QtQuick
import Quickshell
import qs.theme

Item {
    id: root

    required property var modelData
    required property int index
    required property string outputName

    readonly property bool isActive: modelData.active
    readonly property bool isEmpty: Niri.isEmpty(outputName, modelData.name)
    readonly property var position: modelData.coordinates
    readonly property string label: Niri.active && position.length ? String(position[position.length - 1] + 1) : modelData.name
    readonly property var niriIcons: ({
            main: "󰞷",
            pim: "󰆎",
            chat: "󰭹",
            scratch: "󰀻",
            music: "󰎆"
        })
    readonly property var hyprlandIcons: ({
            "1": "󰞷",
            "2": "󰈹",
            "3": "󰺻",
            "4": "󰭹",
            "5": "󰙯",
            "6": "󰭻",
            "7": "󱧶",
            "9": "󰎆",
            "10": "󰠮"
        })
    readonly property color tint: modelData.urgent ? Theme.stCritical
        : isActive ? Theme.onAccent
        : hover.hovered ? Theme.fg
        : isEmpty ? Theme.stInactive
        : Theme.fgDim

    signal becameActive

    implicitWidth: 15 + content.implicitWidth + 14
    implicitHeight: 30

    onIsActiveChanged: if (isActive) {
        becameActive();
        icon.popNow();
    }
    Component.onCompleted: if (isActive) becameActive()

    Crescent {
        visible: root.index > 0
    }

    Row {
        id: content

        x: 15
        anchors.verticalCenter: parent.verticalCenter
        spacing: 11

        Glyph {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            text: (Niri.active ? root.niriIcons : root.hyprlandIcons)[root.modelData.name] ?? "󰝥"
            size: Niri.active ? 23.4 : 18
            color: root.tint
            pulsing: root.modelData.urgent
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.pixelSize: 18
            color: root.tint
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        property int wheelRest: 0

        anchors.fill: parent
        onClicked: root.modelData.activate()
        onWheel: event => {
            if (!Tools.hyprctl || !Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) return;
            wheelRest += event.angleDelta.y;
            const steps = Math.trunc(wheelRest / 120);
            if (steps === 0) return;
            wheelRest -= steps * 120;
            const dir = steps > 0 ? "e+1" : "e-1";
            Quickshell.execDetached([Tools.hyprctl, "dispatch", `hl.dsp.focus({ workspace = "${dir}" })`]);
        }
    }
}
