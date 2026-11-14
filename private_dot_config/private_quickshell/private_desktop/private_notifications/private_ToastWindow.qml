import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.bar
import qs.theme

PanelWindow {
    id: root

    anchors {
        top: true
        right: true
        bottom: true
    }
    implicitWidth: 470
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    mask: Region {
        item: stack
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-toasts"

    Column {
        id: stack

        x: 10
        y: 6
        width: 450
        spacing: 8

        Repeater {
            model: ScriptModel {
                values: Notifs.popups
            }

            delegate: NotificationSlot {
                required property var modelData

                width: stack.width
                notification: modelData
                opacityLevel: 0.92
                // critical stays until dismissed and ignores the sender's timeout
                timeoutMs: modelData.urgency === NotificationUrgency.Critical ? 0
                    : modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000
                    : modelData.urgency === NotificationUrgency.Low ? 2000
                    : 4000
                bodyLines: 5
                onGone: Notifs.popupExpired(modelData)
                onActivated: action => Notifs.activate(modelData, action)
            }
        }
    }
}
