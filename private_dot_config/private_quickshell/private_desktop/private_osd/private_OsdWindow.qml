import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.bar
import qs.theme

// macOS-style capsule with a 16-segment level bar, 15 % above the bottom edge
PanelWindow {
    id: root

    required property var ctx

    // a filled ring, so the curve is antialiased like the card itself
    component Rim: Shape {
        id: rim

        property real lineWidth
        property real strength

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: 0
                y2: rim.height
                GradientStop { position: 0; color: Qt.alpha("white", rim.strength) }
                GradientStop { position: 0.22; color: Qt.alpha("white", rim.strength * 0.08) }
                GradientStop { position: 0.78; color: Qt.alpha("white", rim.strength * 0.06) }
                GradientStop { position: 1; color: Qt.alpha("white", rim.strength * 0.75) }
            }

            PathRectangle {
                width: rim.width
                height: rim.height
                radius: rim.height / 2
            }
            PathRectangle {
                x: rim.lineWidth
                y: rim.lineWidth
                width: rim.width - 2 * rim.lineWidth
                height: rim.height - 2 * rim.lineWidth
                radius: height / 2
            }
        }
    }

    readonly property bool isLock: ctx.kind === "caps" || ctx.kind === "num"
    readonly property bool lockOn: ctx.kind === "caps" ? ctx.capsLock : ctx.numLock
    readonly property var device: ctx.kind === "mic" ? Sys.source : Sys.sink
    readonly property real level: ctx.kind === "brightness" ? (Sys.backlight?.percent ?? 0) / 100
        : Math.min(1, device?.audio?.volume ?? 0)
    readonly property string icon: {
        if (ctx.kind === "brightness") return Quickshell.iconPath("display-brightness-symbolic");
        if (ctx.kind === "caps") return Quickshell.iconPath("caps-lock-symbolic");
        if (ctx.kind === "num") return Quickshell.iconPath("num-lock-symbolic");
        const percent = Math.round(level * 100);
        const state = device?.audio?.muted || percent === 0 ? "muted"
            : percent <= 33 ? "low"
            : percent <= 66 ? "medium"
            : "high";
        // freebsd: theme icons, the swayosd source with its own icons is a nix store path
        return Quickshell.iconPath(ctx.kind === "mic" ? `microphone-sensitivity-${state}-symbolic` : `audio-volume-${state}-symbolic`);
    }

    anchors.bottom: true
    margins.bottom: Math.round(screen.height * 0.15) - 20
    implicitWidth: card.width + 40
    implicitHeight: card.height + 40
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-osd"

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 400
        height: 86
        radius: height / 2
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Base16.base02, 0.8) }
            GradientStop { position: 1; color: Qt.alpha(Base16.base00, 0.88) }
        }

        opacity: root.ctx.shown ? 1 : 0
        scale: root.ctx.shown ? 1 : 0.9
        anchors.verticalCenterOffset: root.ctx.shown ? 0 : 14

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
        }
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        // glass rim: lit along the straight top and bottom edges, fading out round the ends
        Rim {
            anchors.fill: parent
            lineWidth: 1.5
            strength: 0.8
        }

        // softer glow band just inside the rim
        Rim {
            anchors {
                fill: parent
                margins: 1.5
            }
            lineWidth: 7
            strength: 0.12
        }

        IconImage {
            id: glyph

            x: 27
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 32
            source: root.icon
            opacity: root.isLock && !root.lockOn ? 0.5 : 1
            layer.enabled: true
            layer.effect: MultiEffect {
                brightness: 1
                colorization: 1
                colorizationColor: Base16.base05
            }

            onSourceChanged: pop.restart()

            NumberAnimation on scale {
                id: pop

                running: false
                from: 0.75
                to: 1
                duration: Theme.animNormal
                easing.type: Easing.OutBack
            }

            Behavior on opacity {
                NumberAnimation { duration: Theme.animFast }
            }
        }

        Item {
            id: body

            anchors {
                left: glyph.right
                leftMargin: 23
                right: parent.right
                rightMargin: 40
                verticalCenter: parent.verticalCenter
            }
            height: 32

            Row {
                id: segments

                // one value sweeps, so segments fill in order instead of all at once
                property real shownLevel: root.level * count
                readonly property int count: 16
                readonly property real gap: 2

                visible: !root.isLock
                anchors.verticalCenter: parent.verticalCenter
                spacing: gap

                Behavior on shownLevel {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                Repeater {
                    model: segments.count

                    Rectangle {
                        required property int index

                        width: Math.floor((body.width - segments.gap * (segments.count - 1)) / segments.count)
                        height: 5
                        radius: 1
                        color: Qt.alpha(Base16.base05, 0.2)

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, segments.shownLevel - parent.index))
                            height: parent.height
                            radius: parent.radius
                            color: Base16.base05
                        }
                    }
                }
            }

            Text {
                visible: root.isLock
                anchors.centerIn: parent
                text: `${root.ctx.kind === "caps" ? "Caps Lock" : "Num Lock"} ${root.lockOn ? "On" : "Off"}`
                color: Base16.base05
                font.family: "sans-serif"
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }
        }
    }
}
