import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

Scope {
    id: root

    property string kind: ""
    property bool shown: false
    property bool loaded: false
    readonly property bool capsLock: capsLed.on
    readonly property bool numLock: numLed.on

    function show(newKind) {
        if (newKind === "brightness") Sys.refreshPower();
        kind = newKind;
        shown = true;
        hide.restart();
    }

    // the compositor keeps every keyboard's LEDs in step, so one per kind is enough
    component Led: FileView {
        property string kind
        property bool on: false
        property bool known: false

        printErrors: false
        onPathChanged: known = false
        onLoaded: {
            const now = text().trim() !== "0";
            if (known && now !== on) {
                on = now;
                root.show(kind);
            }
            on = now;
            known = true;
        }
    }

    onShownChanged: {
        if (shown) {
            unload.stop();
            loaded = true;
        } else {
            unload.restart();
        }
    }

    Timer {
        id: hide

        interval: 1000
        onTriggered: root.shown = false
    }

    Timer {
        id: unload

        interval: 260
        onTriggered: root.loaded = false
    }

    // freebsd: no /sys/class/leds and evdev is root-only, so the root kbdleds service publishes
    // the two LED bits (../.system/kbdleds, installed by hand); it also covers hotplug, so no udevadm rescan
    Led {
        id: capsLed

        kind: "caps"
        path: "/var/run/kbdleds/caps"
    }

    Led {
        id: numLed

        kind: "num"
        path: "/var/run/kbdleds/num"
    }

    // ponytail: LED changes raise no event a reader can wait on, so poll
    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: {
            capsLed.reload();
            numLed.reload();
        }
    }

    IpcHandler {
        target: "osd"

        function popup(kind: string): void {
            root.show(kind);
        }
    }

    LazyLoader {
        active: root.loaded

        Variants {
            model: Quickshell.screens

            OsdWindow {
                required property ShellScreen modelData

                screen: modelData
                ctx: root
            }
        }
    }
}
