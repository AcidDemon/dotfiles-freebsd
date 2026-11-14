import QtQuick
import qs.bar
import qs.theme

// Slides a card in from the right, folds it away again and owns its timeout.
Item {
    id: root

    required property var notification
    property int timeoutMs: 0
    property int bodyLines: 10
    property real opacityLevel: 1
    property bool stacked: false
    property bool entered: false
    property bool leaving: false
    property bool closes: false
    property real remaining: 1

    signal gone
    signal activated(var action)

    function leave(close) {
        if (leaving) return;
        closes = close;
        leaving = true;
        leaveTimer.start();
    }

    implicitHeight: entered && !leaving ? card.implicitHeight : 0

    Component.onCompleted: entered = true

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    Timer {
        id: leaveTimer

        interval: Theme.animNormal
        onTriggered: {
            if (root.closes) root.notification?.dismiss();
            else root.gone();
        }
    }

    Timer {
        id: timeout

        interval: Math.max(1, root.timeoutMs)
        running: root.timeoutMs > 0 && !root.leaving && !card.hovered
        onTriggered: root.leave(false)
    }

    NumberAnimation on remaining {
        running: timeout.running
        from: 1
        to: 0
        duration: root.timeoutMs
    }

    Connections {
        target: root.notification

        function onBodyChanged() {
            timeout.restart();
        }

        function onSummaryChanged() {
            timeout.restart();
        }
    }

    NotificationCard {
        id: card

        width: parent.width
        notification: root.notification
        bodyLines: root.bodyLines
        remaining: root.timeoutMs > 0 ? root.remaining : -1
        opacity: root.leaving ? 0 : root.opacityLevel
        layer.enabled: root.opacityLevel < 1
        slide: root.entered && !root.leaving ? 0 : width + 20
        onCloseRequested: root.leave(true)
        onActivated: action => root.activated(action)

        Behavior on opacity {
            NumberAnimation { duration: Theme.animNormal }
        }
    }
}
