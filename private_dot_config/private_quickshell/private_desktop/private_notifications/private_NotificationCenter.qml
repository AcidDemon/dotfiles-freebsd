import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

Scope {
    id: root

    property bool loaded: false

    Connections {
        target: Notifs

        function onPanelOpenChanged() {
            if (Notifs.panelOpen) {
                unload.stop();
                Notifs.hideAllPopups();
                root.loaded = true;
            } else {
                unload.restart();
            }
        }
    }

    Timer {
        id: unload

        interval: 320
        onTriggered: root.loaded = false
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            Notifs.panelOpen = !Notifs.panelOpen;
        }

        function toggleDnd(): void {
            Notifs.toggleDnd();
        }

        function clearAll(): void {
            Notifs.clearAll();
        }
    }

    LazyLoader {
        active: root.loaded

        CenterWindow {}
    }

    LazyLoader {
        active: Notifs.popups.length > 0

        ToastWindow {}
    }
}
