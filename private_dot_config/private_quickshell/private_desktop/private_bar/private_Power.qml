pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool open: false

    function run(name) {
        switch (name) {
        case "lock": Sys.launch(["--", Tools.lock]); break;
        case "logout": Quickshell.execDetached([Tools.logout]); break;
        case "suspend": Quickshell.execDetached([Tools.systemctl, "suspend"]); break;
        case "hibernate": Quickshell.execDetached([Tools.systemctl, "hibernate"]); break;
        case "reboot": Quickshell.execDetached([Tools.systemctl, "reboot"]); break;
        case "shutdown": Quickshell.execDetached([Tools.systemctl, "poweroff"]); break;
        }
    }
}
