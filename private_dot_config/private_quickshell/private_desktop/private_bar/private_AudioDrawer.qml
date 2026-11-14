import QtQuick
import Quickshell
import qs.theme
import "Parse.js" as Parse

Pill {
    id: root

    readonly property var sink: Sys.sink
    readonly property var source: Sys.source
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property int micVolume: Math.round((source?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property string formFactor: {
        const props = sink?.properties ?? {};
        // freebsd: pulseaudio spells these with underscores
        return props["device.form_factor"] ?? props["device.icon_name"] ?? "";
    }
    readonly property var backlight: Sys.backlight

    animated: false

    Drawer {
        open: root.hovered

        Cell {
            visible: root.backlight !== null
            tip: `${root.backlight?.device ?? ""} · ${root.backlight?.percent ?? 0}%`
            onScrolled: steps => Sys.stepBacklight(steps)

            Glyph {
                text: Parse.iconFor(root.backlight?.percent ?? 0, ["󰃞", "󰃟", "󰃠"])
                color: Theme.accBacklight
            }
            NumberText { value: root.backlight?.percent ?? 0 }
        }

        Sep { visible: root.backlight !== null }

        Cell {
            tip: !root.source ? "no audio source"
                : root.micMuted ? `mic muted · input ${root.micVolume}%`
                : `mic live · input ${root.micVolume}%`
            // freebsd: pactl nodes are plain data, Sys writes them
            onClicked: if (root.source) Sys.setMuted(root.source, !root.micMuted)

            Glyph {
                text: !root.source ? "󰍮" : root.micMuted ? "󰍭" : "󰍬"
                color: !root.source || root.micMuted ? Theme.stCritical : Theme.accMic
            }
            Txt {
                visible: root.source !== null
                text: root.micMuted ? "off" : `${root.micVolume}%`
                color: root.micMuted ? Theme.stCritical : Theme.fg
            }
        }
    }

    Cell {
        tip: `${root.sink?.description ?? ""} · ${root.volume}%`
        onClicked: button => {
            if (button === Qt.MiddleButton) Quickshell.execDetached([Tools.pavucontrol]);
            else if (button === Qt.LeftButton && root.sink) Sys.setMuted(root.sink, !root.muted);
        }
        onScrolled: steps => {
            if (root.sink) Sys.setVolume(root.sink, Math.max(0, Math.min(1, root.sink.audio.volume + steps * 0.05)));
        }

        Glyph {
            text: root.muted ? "󰝟"
                : /headset/.test(root.formFactor) ? "󰋎"
                : /headphone/.test(root.formFactor) ? "󰋋"
                : Parse.iconFor(root.volume, ["󰕿", "󰖀", "󰕾"])
            color: root.muted ? Theme.stCritical : Theme.accVolume
        }
        NumberText { value: root.volume }
    }
}
