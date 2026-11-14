import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Wayland
import qs.bar
import qs.theme
import "Notify.js" as Notify
import "../bar/Parse.js" as Parse
import "../theme/Outline.js" as Outline

PanelWindow {
    id: root

    readonly property real panelWidth: 500
    // how far the ends curve along the screen edge, and how far into the panel the curve reaches
    readonly property real flare: 44
    readonly property real flareDepth: 110
    readonly property real radius: 30
    property bool opened: false
    readonly property bool shown: opened && Notifs.panelOpen
    property real slide: shown ? 0 : panelWidth + 30
    property bool nightLightActive: false
    property bool perAppOpen: false
    readonly property real expanderWidth: 30
    // freebsd: pactl sink-inputs (Sys), qs-net and qs-vpn stand in for Pipewire and Networking
    readonly property var streams: Sys.streams
    readonly property bool wifiOn: Sys.net?.wifiOn ?? false
    readonly property string wifiName: Sys.net?.ssid ?? ""
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)

    readonly property string tunnel: Sys.vpn && Sys.vpn.kind !== "down" ? Sys.vpn.tip : ""

    function launch(command) {
        Sys.launch(["--", ...command]);
        Notifs.panelOpen = false;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        keyboard.forceActiveFocus();
        opened = true;
    }

    Behavior on slide {
        // no overshoot: the flared ends must never lift off the screen edge
        NumberAnimation {
            duration: root.shown ? 380 : 260
            easing.type: root.shown ? Easing.OutQuint : Easing.InCubic
        }
    }

    Timer {
        id: refreshDelay

        interval: 300
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc

        running: true
        // freebsd: gammastep, no sunsetr user unit
        command: [Tools.nightlight, "status"]
        stdout: StdioCollector {
            onStreamFinished: root.nightLightActive = text.trim() === "active"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Notifs.panelOpen = false
    }

    Item {
        id: keyboard

        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) Notifs.panelOpen = false;
            else if (event.key === Qt.Key_C) Notifs.clearAll();
            else if (event.key === Qt.Key_D) Notifs.toggleDnd();
            else return;
            event.accepted = true;
        }
    }

    Item {
        id: sliding

        anchors.fill: parent

        transform: Translate {
            x: root.slide
        }

        Item {
            id: panel

            // the launcher's outline turned to lie against the right edge
            readonly property var geometry: ({
                width: height - 2 * root.flare,
                height: root.panelWidth,
                flare: root.flare,
                flareHeight: root.flareDepth
            })

            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                // the upper curve ends clear of the bar
                topMargin: Theme.railMarginTop + Theme.railHeight + 8
                bottomMargin: 10
            }
            width: root.panelWidth

            GlassEdge {
                id: glass

                anchors.fill: parent
                outline: Outline.side(panel.geometry, 0, 0, root.radius)
                glowInner: Outline.side(panel.geometry, 8, 8, root.radius - 8)
                rimInner: Outline.side(panel.geometry, 1.6, 1.6, root.radius - 1.6)
                shadowX: -6
            }

            MouseArea {
                anchors.fill: parent
                containmentMask: glass.body
                onClicked: keyboard.forceActiveFocus()
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    topMargin: root.flare + 14
                    bottomMargin: root.flare + 12
                    rightMargin: 12
                }
                spacing: 10

                Grid {
                    id: tiles

                    // fixed: a width derived from the Grid's own size spins forever
                    readonly property real tileWidth: (root.panelWidth - 24 - columnSpacing) / 2

                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 8

                    // Wi-Fi only; a cable shows in the bar's network group
                    // freebsd: airplane-toggle brings wlan0 up or down through doas; right click scans, as swaync did
                    QuickTile {
                        width: tiles.tileWidth
                        glyph: root.wifiOn ? "󰖩" : "󰖪"
                        title: "Wi-Fi"
                        status: !root.wifiOn ? "Off" : root.wifiName || "Not connected"
                        on: root.wifiOn
                        onClicked: wifiToggle.running = true
                        onRightClicked: root.launch([Tools.terminal, "-e", "sh", "-c", "ifconfig wlan0 list scan; read -r _"])

                        Process {
                            id: wifiToggle

                            command: [Tools.wifiToggle]
                            onRunningChanged: if (!running) Sys.refreshNet()
                        }
                    }

                    // freebsd: no BlueZ, so no adapter and no tile
                    QuickTile {
                        width: tiles.tileWidth
                        visible: root.adapter !== null
                        enabled: root.adapter !== null
                        glyph: root.adapter?.enabled ? "󰂯" : "󰂲"
                        title: "Bluetooth"
                        status: !root.adapter ? "Unavailable"
                            : !root.adapter.enabled ? "Off"
                            : root.btConnected.length === 1 ? root.btConnected[0].name
                            : root.btConnected.length > 1 ? `${root.btConnected.length} devices`
                            : "On"
                        on: root.adapter?.enabled ?? false
                        onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                        onRightClicked: root.launch([Tools.bluemanManager])
                    }

                    // freebsd: no NetworkManager, so this shows Sys.vpn (WireGuard, else Tailscale) and qs-vpn-toggle
                    // drives wg-quick, or Tailscale while /usr/local/etc/wireguard has no configs
                    QuickTile {
                        width: tiles.tileWidth
                        glyph: "󰖂"
                        title: "VPN"
                        status: root.tunnel || "Off"
                        on: root.tunnel !== ""
                        onClicked: vpnToggle.running = true

                        Process {
                            id: vpnToggle

                            command: [Tools.vpnToggle]
                            onExited: Sys.refreshVpn()
                        }
                    }

                    QuickTile {
                        width: tiles.tileWidth
                        glyph: Notifs.dnd ? "󰂛" : "󰂚"
                        title: "Do Not Disturb"
                        status: Notifs.dnd ? "On" : "Off"
                        on: Notifs.dnd
                        accent: Base16.muted ? Theme.accClock : Base16.base0E
                        onClicked: Notifs.toggleDnd()
                    }

                    QuickTile {
                        width: tiles.tileWidth
                        glyph: "󰌵"
                        title: "Night Light"
                        status: root.nightLightActive ? "On" : "Off"
                        on: root.nightLightActive
                        accent: Base16.base07
                        onClicked: {
                            Quickshell.execDetached([Tools.nightlight]);
                            refreshDelay.restart();
                        }
                    }

                    QuickTile {
                        width: tiles.tileWidth
                        glyph: "󰹑"
                        title: "Screenshot"
                        status: "Select area"
                        onClicked: root.launch([Tools.screenshot])
                    }
                }

                PlasticSlider {
                    Layout.fillWidth: true
                    Layout.rightMargin: root.expanderWidth + 8
                    visible: Sys.backlight !== null
                    glyph: "󰃟"
                    accent: Base16.base07
                    value: (Sys.backlight?.percent ?? 0) / 100
                    onMoved: value => Sys.setBacklight(Math.round(value * 100))
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    PlasticSlider {
                        Layout.fillWidth: true
                        glyph: Sys.sink?.audio?.muted ? "󰝟" : "󰕾"
                        accent: Sys.sink?.audio?.muted ? Theme.overlay0 : Base16.base0D
                        value: Sys.sink?.audio?.volume ?? 0
                        // freebsd: pactl nodes are plain data, Sys writes them
                        onMoved: value => {
                            if (Sys.sink) Sys.setVolume(Sys.sink, value);
                        }
                        onGlyphClicked: {
                            if (Sys.sink) Sys.setMuted(Sys.sink, !Sys.sink.audio.muted);
                        }
                    }

                    Item {
                        Layout.preferredWidth: root.expanderWidth
                        Layout.preferredHeight: root.expanderWidth

                        Keycap {
                            anchors.fill: parent
                            visible: root.streams.length > 0
                            radius: 8
                            depth: 3
                            glyph: root.perAppOpen ? "\u{F0143}" : "\u{F0140}"
                            glyphSize: 14
                            active: root.perAppOpen
                            onClicked: root.perAppOpen = !root.perAppOpen
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: root.expanderWidth + 8
                    visible: root.perAppOpen && root.streams.length > 0
                    spacing: 6

                    Repeater {
                        // freebsd: every pactl read brings new stream objects, so the delegates are keyed
                        // by id (a drag survives) and read the live stream
                        model: ScriptModel {
                            values: root.streams
                            objectProp: "id"
                        }

                        delegate: PlasticSlider {
                            required property var modelData
                            readonly property var stream: Sys.streams.find(s => s.id === modelData.id) ?? modelData

                            Layout.fillWidth: true
                            implicitHeight: 30
                            glyph: stream.audio.muted ? "󰝟" : "󰕾"
                            label: stream.properties["application.name"] ?? stream.description ?? stream.name
                            accent: stream.audio.muted ? Theme.overlay0 : Theme.sapphire
                            value: stream.audio.volume
                            onMoved: value => Sys.setVolume(stream, value)
                            onGlyphClicked: Sys.setMuted(stream, !stream.audio.muted)
                        }
                    }

                    Keycap {
                        Layout.alignment: Qt.AlignRight
                        implicitHeight: 28
                        radius: 8
                        depth: 3
                        label: "Open mixer"
                        labelSize: 12
                        onClicked: root.launch([Tools.pwvucontrol])
                    }
                }

                MediaCard {
                    Layout.fillWidth: true
                    visible: Sys.player !== null
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8

                    Txt {
                        Layout.fillWidth: true
                        text: "Notifications"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Keycap {
                        implicitHeight: 32
                        radius: 9
                        depth: 3
                        label: "Clear All"
                        onClicked: Notifs.clearAll()
                    }
                }

                Plastic {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 100
                    color: Theme.crust
                    radius: 14
                    recessed: true
                    depth: 0

                    Flickable {
                        id: flick

                        readonly property bool overflows: contentHeight > height + 1

                        anchors {
                            fill: parent
                            margins: 8
                        }
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: list.implicitHeight

                        ColumnLayout {
                            id: list

                            width: parent.width
                            spacing: 10

                            Repeater {
                                model: ScriptModel {
                                    values: Notifs.groups
                                    objectProp: "key"
                                }

                                delegate: NotificationGroup {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    groupKey: modelData.key
                                }
                            }
                        }
                    }

                    // more below: the list fades out at the bottom edge
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: 2
                        }
                        height: 48
                        radius: 12
                        opacity: flick.overflows && !flick.atYEnd ? 1 : 0
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.alpha(Theme.crust, 0) }
                            GradientStop { position: 1; color: Theme.crust }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animFast }
                        }
                    }

                    Rectangle {
                        x: parent.width - 6
                        y: 8 + (flick.height - height) * (flick.contentY / Math.max(1, flick.contentHeight - flick.height))
                        visible: flick.overflows
                        width: 3
                        height: Math.max(24, flick.height * flick.height / Math.max(1, flick.contentHeight))
                        radius: 1.5
                        color: Theme.fg
                        opacity: flick.moving || listHover.hovered ? 0.45 : 0.15

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animNormal }
                        }
                    }

                    HoverHandler {
                        id: listHover
                    }

                    Txt {
                        anchors.centerIn: parent
                        visible: Notifs.count === 0
                        text: "No notifications"
                        color: Theme.fgDim
                    }
                }

                ToolDock {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    onReleaseFocus: keyboard.forceActiveFocus()
                }
            }
        }
    }
}
