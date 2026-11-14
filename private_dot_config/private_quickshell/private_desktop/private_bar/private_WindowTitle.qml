import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme

Pill {
    id: root

    required property ShellScreen screen
    property Toplevel current: null
    property bool focusedHere: false
    readonly property var niriWindow: Niri.activeWindow(screen.name)
    readonly property string title: (Niri.active ? niriWindow?.title : current?.title) ?? ""
    readonly property string iconName: {
        const appId = (Niri.active ? niriWindow?.app_id : current?.appId) ?? "";
        // entries load asynchronously, reading them re-evaluates this once they arrive
        const loaded = DesktopEntries.applications.values.length > 0;
        return appId && loaded ? (DesktopEntries.heuristicLookup(appId)?.icon ?? appId) : "";
    }

    function isOnScreen(toplevel) {
        const screens = toplevel.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === screen.name) return true;
        }
        return false;
    }

    function sync() {
        const active = ToplevelManager.activeToplevel;
        if (!active) {
            if (focusedHere) current = null;
            return;
        }
        focusedHere = isOnScreen(active);
        if (focusedHere) current = active;
    }

    pad: 13
    shown: title !== ""

    Component.onCompleted: sync()

    Connections {
        target: ToplevelManager

        function onActiveToplevelChanged() {
            root.sync();
        }
    }

    Cell {
        padLeft: 0
        padRight: 0
        hoverable: false
        tip: root.title
        spacing: 7

        IconImage {
            implicitSize: 16
            source: root.iconName ? Quickshell.iconPath(root.iconName, true) : ""
            visible: source !== ""
        }

        Txt {
            fade: true
            color: Theme.subtext1
            text: root.title
            elide: Text.ElideRight
            Layout.maximumWidth: 288
        }
    }
}
