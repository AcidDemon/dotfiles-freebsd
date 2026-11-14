import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.theme

Pill {
    id: root

    readonly property var alertIcons: ({
            none: "󰅺",
            notification: "󰡟",
            "dnd-none": "󰽤",
            "dnd-notification": "󰽥"
        })
    readonly property string alert: (Notifs.dnd ? "dnd-" : "") + (Notifs.count > 0 ? "notification" : "none")
    readonly property var trayItems: SystemTray.items.values.filter(item => item.status !== Status.Passive)
    // narrow screens: the tray folds into a drawer that opens on hover, like the clock's date
    property bool compact: false
    // a tray icon with its menu open keeps the drawer from closing under it
    property Item menuHolder: null

    Cell {
        tip: Sys.idleInhibited ? "Idle inhibited" : "Idle allowed"
        onClicked: Sys.idleInhibited = !Sys.idleInhibited

        Glyph {
            text: Sys.idleInhibited ? "󰅶" : "󰾪"
            size: 19
            color: Sys.idleInhibited ? Theme.accIdle : Theme.fgDim
        }
    }

    Cell {
        tip: Notifs.count > 0 ? `${Notifs.count} Notification${Notifs.count === 1 ? "" : "s"}` : ""
        onClicked: button => {
            if (button === Qt.LeftButton) Notifs.panelOpen = !Notifs.panelOpen;
            else if (button === Qt.RightButton) Notifs.toggleDnd();
        }

        Glyph {
            text: root.alertIcons[root.alert]
            size: 19
            color: Notifs.count > 0 ? Theme.accWindow : Theme.fgDim
        }
    }

    Cell {
        visible: root.compact && root.trayItems.length > 0
        hoverable: false

        Glyph {
            text: "󰅁"
            size: 15
            color: Theme.fgDim
            rotation: tray.open ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: Theme.animDrawer; easing.type: Easing.OutCubic }
            }
        }
    }

    Drawer {
        id: tray

        open: !root.compact || root.hovered || root.menuHolder !== null

        RowLayout {
            Layout.leftMargin: 7
            Layout.rightMargin: 7
            spacing: 8

            Repeater {
                model: ScriptModel {
                    values: root.trayItems
                }

                delegate: TrayIcon {
                    onMenuOpenChanged: {
                        if (menuOpen) root.menuHolder = this;
                        else if (root.menuHolder === this) root.menuHolder = null;
                    }
                }
            }
        }
    }
}
