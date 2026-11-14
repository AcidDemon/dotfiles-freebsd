import Quickshell
import qs.bar
import qs.launcher
import qs.notifications
import qs.osd
import qs.power
import qs.switcher

ShellRoot {
    Launcher {}
    NotificationCenter {}
    Osd {}
    PowerMenu {}
    Switcher {}

    Variants {
        model: Quickshell.screens

        Bar {
            required property ShellScreen modelData

            screen: modelData
        }
    }
}
