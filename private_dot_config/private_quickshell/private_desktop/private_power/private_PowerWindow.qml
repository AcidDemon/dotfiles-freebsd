import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.bar
import qs.theme

// Same layout and colours as the old wlogout style.css.
PanelWindow {
    id: root

    property int focusIndex: -1
    // both directions animate, so moving between tiles shows one shrinking while the next grows
    readonly property int motion: 380
    readonly property real gridMargin: 230
    readonly property color accent: Base16.muted ? Base16.base0D : Base16.base0E
    readonly property color tile: mix(Base16.base00, Base16.muted ? Base16.base03 : Base16.base0E, 0.12)
    // freebsd: no suspend or hibernate tiles, the firmware has no S3 and no S4BIOS (hw.acpi.supported_sleep_state=S4 S5)
    // ponytail: fixed for this laptop; template on hw.acpi.supported_sleep_state if a host with S3 shows up
    readonly property var actions: [
        { name: "lock", text: "Lock", key: Qt.Key_L },
        { name: "logout", text: "Logout", key: Qt.Key_E },
        { name: "reboot", text: "Reboot", key: Qt.Key_R },
        { name: "shutdown", text: "Shutdown", key: Qt.Key_S }
    ]

    function mix(a, b, amount) {
        return Qt.rgba(a.r + (b.r - a.r) * amount, a.g + (b.g - a.g) * amount, a.b + (b.b - a.b) * amount, 1);
    }

    function run(name) {
        Power.open = false;
        Power.run(name);
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Qt.alpha(Theme.crust, 0.25)
    // keeps the blur rules both compositors already have for wlogout
    WlrLayershell.namespace: "logout_dialog"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const hit = root.actions.find(a => a.key === event.key);
            if (event.key === Qt.Key_Escape) Power.open = false;
            else if (hit) root.run(hit.name);
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.focusIndex = (root.focusIndex + 1) % root.actions.length;
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) root.focusIndex = (root.focusIndex + root.actions.length - 1) % root.actions.length;
            else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.focusIndex >= 0) root.run(root.actions[root.focusIndex].name);
            else return;
            event.accepted = true;
        }
    }

    Row {
        anchors {
            fill: parent
            margins: root.gridMargin
        }

        Repeater {
            model: root.actions

            delegate: Item {
                id: cell

                required property var modelData
                required property int index
                readonly property bool hovered: mouse.containsMouse
                readonly property bool first: index === 0
                readonly property bool last: index === root.actions.length - 1
                // wlogout's tile margin, dropped on hover so the tile grows
                property real inset: hovered ? 0 : 50
                property real corner: hovered ? 36 : 0

                // whole pixels, fractional tile edges showed as seams
                width: Math.round((index + 1) * parent.width / root.actions.length) - Math.round(index * parent.width / root.actions.length)
                height: parent.height

                Item {
                    anchors.fill: parent
                    clip: true

                Rectangle {
                    // a rounded Rectangle antialiases its straight sides too, so a
                    // square side is pushed past the clip edge instead of drawn
                    readonly property real leftExtra: cell.first || cell.corner > 0 ? 0 : 40
                    readonly property real rightExtra: cell.last || cell.corner > 0 ? 0 : 40

                    x: -leftExtra
                    y: cell.inset
                    width: parent.width + leftExtra + rightExtra
                    height: parent.height - 2 * cell.inset
                    topLeftRadius: cell.first ? 36 : cell.corner
                    bottomLeftRadius: cell.first ? 36 : cell.corner
                    topRightRadius: cell.last ? 36 : cell.corner
                    bottomRightRadius: cell.last ? 36 : cell.corner
                    color: cell.hovered ? Qt.alpha(root.accent, 0.45)
                        : root.focusIndex === cell.index ? Qt.alpha(Base16.base02, 0.92)
                        : Qt.alpha(root.tile, 0.88)

                    Behavior on color {
                        ColorAnimation { duration: root.motion; easing.type: Easing.OutCubic }
                    }
                }
                }

                Image {
                    property real size: cell.hovered ? 86 : 76

                    anchors.centerIn: parent
                    width: size
                    height: size
                    source: `icons/${cell.modelData.name}_white.png`
                    // white icons, drawn in the text colour on light themes
                    layer.enabled: Theme.light
                    layer.effect: MultiEffect {
                        brightness: -1
                        colorization: 1
                        colorizationColor: Base16.base05
                    }
                    sourceSize: Qt.size(172, 172)
                    smooth: true
                    mipmap: true

                    Behavior on size {
                        NumberAnimation { duration: root.motion; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 + (parent.height - 100) * 0.38 - height / 2
                    text: cell.modelData.text
                    color: Base16.base05
                    font.family: "Noto Sans"
                    font.pixelSize: 16
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.run(cell.modelData.name)
                }

                Behavior on inset {
                    NumberAnimation { duration: root.motion; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }

                Behavior on corner {
                    NumberAnimation { duration: root.motion; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }
            }
        }
    }
}
