import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool open: false

    IpcHandler {
        target: "switcher"

        function toggle(): void {
            root.open = !root.open;
        }
    }

    // built hidden in the background at startup and kept, so the wallpapers are already decoded when it opens
    LazyLoader {
        loading: true

        SwitcherWindow {
            switcher: root
        }
    }
}
