import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.theme

Cell {
    id: root

    required property var modelData
    property bool menuOpen: false

    padLeft: 0
    padRight: 0
    spacing: 0
    hoverable: false
    tip: modelData.tooltipTitle || modelData.title

    readonly property bool opensMenuOnLeft: modelData.onlyMenu && modelData.hasMenu

    onPressed: button => {
        if (modelData.hasMenu && (button === Qt.RightButton || (button === Qt.LeftButton && opensMenuOnLeft))) menuOpen = true;
    }
    onClicked: button => {
        if (button === Qt.LeftButton && !opensMenuOnLeft) {
            modelData.activate();
        } else if (button === Qt.MiddleButton) {
            modelData.secondaryActivate();
        }
    }
    onScrolled: steps => modelData.scroll(steps, false)

    IconImage {
        implicitSize: 14
        source: root.modelData.icon
        scale: root.hovered ? 1.2 : 1
        // light themes draw every tray icon in the text colour: app pixmaps are made for dark bars
        layer.enabled: Theme.light || String(root.modelData.icon).includes("-symbolic")
        layer.effect: MultiEffect {
            brightness: Theme.light ? -1 : 1
            colorization: 1
            colorizationColor: Theme.fg
        }

        Behavior on scale {
            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack }
        }
    }

    LazyLoader {
        active: root.menuOpen

        TrayMenu {
            trayItem: root.modelData
            anchorItem: root
            onDismissed: root.menuOpen = false
        }
    }
}
