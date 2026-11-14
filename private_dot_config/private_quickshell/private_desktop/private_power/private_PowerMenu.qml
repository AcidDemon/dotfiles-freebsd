import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

Scope {
    id: root

    IpcHandler {
        target: "power"

        function toggle(): void {
            Power.open = !Power.open;
        }
    }

    LazyLoader {
        active: Power.open

        Variants {
            model: Quickshell.screens

            PowerWindow {
                required property ShellScreen modelData

                screen: modelData
            }
        }
    }
}
