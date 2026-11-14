import QtQuick
import Quickshell
import Quickshell.WindowManager
import qs.theme

Pill {
    id: root

    required property ShellScreen screen
    property Item activeItem: null
    readonly property var projection: WindowManager.screenProjection(screen)

    function order(set) {
        const c = set.coordinates;
        return c.length ? c[c.length - 1] : Number(set.name) || 0;
    }

    function visibleSets() {
        const list = projection?.windowsets ?? [];
        const out = [];
        for (let i = 0; i < list.length; i++) {
            if (list[i].shouldDisplay && list[i].name !== "park") out.push(list[i]);
        }
        return out.sort((a, b) => order(a) - order(b));
    }

    pad: 5

    Item {
        implicitWidth: buttons.implicitWidth
        implicitHeight: 30

        Plastic {
            x: (root.activeItem?.x ?? 0) + 3
            width: Math.max(0, (root.activeItem?.width ?? 0) - 3)
            height: parent.height
            radius: height / 2
            depth: 3
            color: Theme.accWorkspace
            opacity: root.activeItem ? 1 : 0

            Behavior on x {
                NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
            }

            Behavior on width {
                NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }
        }

        Row {
            id: buttons

            move: Transition {
                NumberAnimation { property: "x"; duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal }
            }

            Repeater {
                model: ScriptModel {
                    values: root.visibleSets()
                }

                delegate: WorkspaceButton {
                    outputName: root.screen.name
                    onBecameActive: root.activeItem = this
                }
            }
        }
    }
}
