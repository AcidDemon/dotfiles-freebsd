import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool loaded: false
    property bool closing: false
    property string mode: "apps"

    function request(next) {
        if (loaded && !closing && mode === next) {
            closing = true;
            return;
        }
        mode = next;
        closing = false;
        loaded = true;
    }

    IpcHandler {
        target: "launcher"

        function open(mode: string): void {
            root.request(mode);
        }
    }

    LazyLoader {
        active: root.loaded

        LauncherWindow {
            launcher: root
        }
    }
}
