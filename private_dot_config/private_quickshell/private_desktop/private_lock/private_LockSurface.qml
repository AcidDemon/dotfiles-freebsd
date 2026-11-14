import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.bar
import qs.theme

// Positions follow the old hyprlock config; its font sizes were points, so ×4/3 for pixels.
Item {
    id: root

    required property var ctx
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    // freebsd: own copy of Sys.player, Sys would start every bar poller and a pipewire client (no server here) inside the locker
    readonly property var player: {
        const players = Mpris.players.values;
        const isProxy = p => p.dbusName.endsWith(".playerctld");
        const proxy = players.find(p => isProxy(p) && p.identity);
        if (proxy) return proxy;
        const real = players.filter(p => !isProxy(p));
        return real.find(p => p.isPlaying) ?? real[0] ?? null;
    }
    readonly property string subtext0: Base16.subtext0
    readonly property color accent: Base16.muted ? Base16.base0D : Base16.base0E
    readonly property color good: Base16.muted ? Theme.muteTone : Base16.base0B
    property bool shown: false
    // clock and date size against the old hyprlock layout; offsets grow with it
    readonly property real clockScale: 1.3

    opacity: shown && !state.unlocking ? 1 : 0

    Component.onCompleted: {
        shown = true;
        input.forceActiveFocus();
    }

    Behavior on opacity {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Image {
        id: wallpaper

        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blurMax: 64
        blurMultiplier: 0.6
        blur: 1
        brightness: -0.06
        contrast: -0.18
        saturation: 0.05
    }

    // the photo is dark; light themes wash it out so their dark text stays readable
    Rectangle {
        anchors.fill: parent
        visible: Theme.light
        color: Qt.alpha(Base16.base00, 0.62)
    }

    Text {
        x: root.cx - 23 * root.clockScale - width / 2
        y: root.cy - 186 * root.clockScale - height / 2
        text: Qt.formatTime(clock.date, "HH")
        color: Base16.base05
        font.family: "Archivo Black"
        font.pixelSize: 187 * root.clockScale
        renderType: Text.NativeRendering
    }

    Text {
        x: root.cx + 23 * root.clockScale - width / 2
        y: root.cy - 53 * root.clockScale - height / 2
        text: Qt.formatTime(clock.date, "mm")
        color: root.accent
        font.family: "Archivo Black"
        font.pixelSize: 187 * root.clockScale
        renderType: Text.NativeRendering
    }

    Text {
        x: root.cx + 35 * root.clockScale - width / 2
        y: root.cy + 35 * root.clockScale - height / 2
        text: Qt.locale("en_GB").toString(clock.date, "dd MMMM, ddd.")
        color: root.subtext0
        font.family: "GeistMono Nerd Font"
        font.pixelSize: 24 * root.clockScale
        renderType: Text.NativeRendering
    }

    Rectangle {
        id: avatarRing

        x: root.cx - width / 2
        y: root.height - 250 - height
        width: 186
        height: 186
        radius: width / 2
        color: root.accent

        Image {
            anchors.centerIn: parent
            width: 180
            height: 180
            source: "avatar.png"
            sourceSize: Qt.size(360, 360)
            fillMode: Image.PreserveAspectCrop
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: avatarMask
            }
        }

        Rectangle {
            id: avatarMask

            width: 180
            height: 180
            radius: 90
            visible: false
            layer.enabled: true
        }
    }

    Text {
        x: root.cx - width / 2
        y: root.height - 190 - height
        text: `Hello, ${Quickshell.env("USER")}`
        color: Base16.base05
        font.family: "Archivo"
        font.weight: Font.DemiBold
        font.pixelSize: 29
        renderType: Text.NativeRendering
    }

    Rectangle {
        id: field

        property real shake: 0

        x: root.cx - width / 2 + shake
        y: root.height - 110 - height
        width: 340
        height: 60
        radius: height / 2
        color: Base16.base02
        border.width: 3
        border.color: root.ctx.failed ? Base16.base08 : root.ctx.capsLock ? Base16.base0A : root.accent

        Behavior on border.color {
            ColorAnimation { duration: Theme.animNormal }
        }

        SequentialAnimation {
            id: shakeAnimation

            NumberAnimation { target: field; property: "shake"; to: -14; duration: 50 }
            NumberAnimation { target: field; property: "shake"; to: 12; duration: 70 }
            NumberAnimation { target: field; property: "shake"; to: -8; duration: 70 }
            NumberAnimation { target: field; property: "shake"; to: 4; duration: 60 }
            NumberAnimation { target: field; property: "shake"; to: 0; duration: 60 }
        }

        Connections {
            target: root.ctx

            function onAttemptsChanged() {
                shakeAnimation.restart();
            }
        }

        TextInput {
            id: input

            anchors.fill: parent
            opacity: 0
            echoMode: TextInput.Password
            text: root.ctx.password
            onTextEdited: {
                root.ctx.password = text;
                root.ctx.failed = false;
            }
            onAccepted: root.ctx.submit()
            Keys.onPressed: event => {
                root.ctx.checkCapsLock(event);
                if (event.key === Qt.Key_Escape) {
                    root.ctx.password = "";
                    event.accepted = true;
                }
            }
        }

        // dots start centred, then grow leftwards once they would reach the submit
        // button; when even that is full, older dots slide out on the left
        Item {
            id: dotArea

            readonly property real fieldCenter: parent.width / 2 - x

            x: 24
            width: 238
            height: parent.height
            clip: true

        Row {
            id: dots

            x: Math.min(dotArea.fieldCenter - width / 2, dotArea.width - width)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Behavior on x {
                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: root.ctx.password.length

                delegate: Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: Base16.base05

                    NumberAnimation on scale {
                        from: 0
                        to: 1
                        duration: Theme.animFast
                        easing.type: Easing.OutBack
                    }
                }
            }
        }
        }

        Text {
            anchors.centerIn: parent
            visible: root.ctx.password === ""
            text: root.ctx.status || "Enter password..."
            color: root.ctx.failed ? Base16.base08 : Base16.base05
            font.family: "Noto Sans"
            font.italic: root.ctx.failed
            font.pixelSize: 18
        }

        MouseArea {
            anchors.fill: parent
            onClicked: input.forceActiveFocus()
        }
    }

    Rectangle {
        x: root.cx + 140 - width / 2
        y: root.height - 120 - height
        width: 40
        height: 40
        radius: 20
        color: submitMouse.containsMouse ? root.accent : Base16.base03
        border.width: 1
        border.color: root.accent

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        Text {
            anchors.centerIn: parent
            text: "→"
            color: Base16.base05
            font.family: "Archivo"
            font.weight: Font.DemiBold
            font.pixelSize: 27
        }

        MouseArea {
            id: submitMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.ctx.submit()
        }
    }

    RowLayout {
        x: root.cx - width / 2
        y: root.height - 55 - height
        visible: root.player !== null
        spacing: 14

        Row {
            spacing: 6

            Repeater {
                model: [
                    { glyph: "󰒮", run: () => root.player.previous() },
                    { glyph: root.player?.isPlaying ? "󰏤" : "󰐊", run: () => root.player.togglePlaying() },
                    { glyph: "󰒭", run: () => root.player.next() }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: 30
                    height: 30
                    radius: 15
                    color: buttonMouse.containsMouse ? Qt.alpha(root.accent, 0.35) : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }

                    Glyph {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        size: 18
                        color: root.good
                    }

                    MouseArea {
                        id: buttonMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: modelData.run()
                    }
                }
            }
        }

        Glyph {
            text: "\u{F1BC}"
            size: 20
            color: root.good
        }

        Text {
            text: `${root.player?.trackTitle ?? ""} - ${root.player?.trackArtist ?? ""}`
            textFormat: Text.PlainText
            color: root.subtext0
            font.family: "GeistMono Nerd Font"
            font.pixelSize: 20
            renderType: Text.NativeRendering
        }
    }
}
