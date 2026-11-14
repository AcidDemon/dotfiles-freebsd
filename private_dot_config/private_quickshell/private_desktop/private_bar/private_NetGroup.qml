import QtQuick
import qs.theme
import "Parse.js" as Parse

Pill {
    id: root

    // freebsd: no NetworkManager, so Sys.net (qs-net: default route + ifconfig) stands in for
    // Quickshell.Networking; the uplink is whatever holds the default route
    readonly property var device: Sys.net?.kind ? Sys.net : null
    readonly property var wifi: device?.kind === "wifi" ? ({ name: device.ssid }) : null
    readonly property int strength: device?.strength ?? 0
    readonly property string address: device?.address ?? ""
    readonly property var vpn: Sys.vpn
    // narrow screens: the tunnel name stays in the tooltip only
    property bool compact: false

    Cell {
        id: network

        tip: !root.device ? "disconnected"
            : root.wifi ? `${root.wifi.name}  ·  ${root.strength}%\n${root.address}`
            : `${root.device.name}\n${root.address}`

        Glyph {
            text: !root.device ? "󰤭" : root.wifi ? Parse.iconFor(root.strength, ["󰤟", "󰤢", "󰤥", "󰤨"]) : "󰈀"
            color: root.device ? Theme.accWifi : Theme.overlay0
        }
        NumberText {
            visible: root.wifi !== null
            value: root.strength
        }
    }

    Sep {}

    Cell {
        tip: root.vpn?.tip ?? "no tunnel"

        Glyph {
            text: "󰖂"
            color: root.vpn?.kind === "wireguard" ? Theme.vpnWireguard
                : root.vpn?.kind === "tailscale" ? Theme.vpnTailscale
                : Theme.stInactive
        }
        Txt {
            visible: text !== "" && !root.compact
            fade: true
            text: root.vpn?.label ?? ""
        }
    }
}
