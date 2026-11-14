pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string iconFamily: "Symbols Nerd Font"
    readonly property real fontSize: 16
    readonly property real iconSize: 20.8
    readonly property real gap: 10

    readonly property real railHeight: 46
    readonly property real railMarginTop: 6
    readonly property real railMarginSide: 10
    readonly property real railRadius: 17
    readonly property real pillHeight: 38

    readonly property int animFast: 140
    readonly property int animNormal: 260
    readonly property int animDrawer: 300
    readonly property int animSlow: 420

    readonly property color crust: Base16.crust
    readonly property color overlay0: Base16.overlay0
    readonly property color overlay1: Base16.overlay1
    readonly property color subtext1: Base16.subtext1
    readonly property color sky: Base16.sky
    readonly property color sapphire: Base16.sapphire
    readonly property color pink: Base16.pink

    readonly property color barBg: Qt.alpha(crust, 0.55)
    readonly property color barBorder: Qt.alpha(Base16.base02, 0.90)
    readonly property color pillBg: Base16.base02
    readonly property color pillHover: Base16.base03
    readonly property color divider: Base16.base04
    readonly property color fg: Base16.base05
    readonly property bool light: Base16.polarity === "light"
    // overlay1 is too faint on light backgrounds
    readonly property color fgDim: light ? Base16.subtext0 : overlay1
    // text and icons on an accent fill
    readonly property color muteTone: Base16.subtext0
    // white on light themes and on the work themes' saturated blue, as macOS does
    readonly property color onAccent: light || Base16.muted ? "#ffffff" : crust
    readonly property color islandFill: light ? pillBg : Qt.darker(crust, 1.5)
    readonly property color fieldInvalid: light ? Qt.tint(Base16.base00, Qt.alpha(Base16.base08, 0.18)) : Qt.darker(Base16.base08, 3)
    readonly property color cardBg: Qt.alpha(Base16.base00, 0.78)
    readonly property color cardBorder: Base16.base02
    readonly property color menuBg: Qt.alpha(Base16.base00, 0.96)

    // muted themes keep only the system accent (accClock, accWorkspace); every other widget is neutral
    readonly property color accPower: Base16.muted ? muteTone : Base16.base0E
    readonly property color accWorkspace: Base16.base0D
    readonly property color accMedia: Base16.muted ? muteTone : Base16.base0B
    readonly property color accWindow: Base16.muted ? muteTone : pink
    readonly property color accCpu: Base16.muted ? muteTone : Base16.base0B
    readonly property color accMemory: Base16.muted ? muteTone : Base16.base07
    readonly property color accTemp: Base16.muted ? muteTone : Base16.base09
    readonly property color accWifi: Base16.muted ? muteTone : sapphire
    readonly property color accBacklight: Base16.muted ? muteTone : Base16.base0A
    readonly property color accVolume: Base16.muted ? muteTone : sky
    readonly property color accMic: Base16.muted ? muteTone : pink
    readonly property color accBattery: Base16.muted ? muteTone : Base16.base0C
    readonly property color accIdle: Base16.muted ? muteTone : Base16.base0E
    readonly property color accClock: Base16.base0D

    readonly property color vpnWireguard: Base16.muted ? muteTone : Base16.base06
    readonly property color vpnTailscale: Base16.muted ? muteTone : Base16.base0B

    readonly property color stWarning: Base16.base0A
    readonly property color stCritical: Base16.base08
    readonly property color stInactive: overlay0
    readonly property color stCharging: Base16.base0F
    readonly property color matchOnAccent: Qt.hsla(Base16.base08.hslHue, 0.85, 0.35, 1)
    readonly property color matchOnDark: Qt.hsla(Base16.base08.hslHue, 0.9, light ? 0.4 : 0.65, 1)
}
