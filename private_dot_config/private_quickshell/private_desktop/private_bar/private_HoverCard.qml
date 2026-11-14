import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme

PanelWindow {
    id: root

    property Item target: null
    property Item pending: null
    property bool wanted: false
    property bool glide: false
    readonly property Component panel: target?.panel ?? null
    readonly property real boxWidth: content.implicitWidth + 2
    readonly property real boxHeight: content.implicitHeight + 2

    function enter(cell) {
        if (!cell.tip && !cell.panel) return;
        closeTimer.stop();
        if (wanted) {
            target = cell;
            content.flash();
        } else {
            pending = cell;
            openTimer.restart();
        }
    }

    function leave(cell) {
        if (pending === cell) {
            openTimer.stop();
            pending = null;
        }
        if (target === cell) closeTimer.restart();
    }

    function place() {
        if (!target) return;
        // this surface has no real width until the compositor configures it
        const barWidth = target.QsWindow.window.width;
        const center = target.mapToItem(null, target.width / 2, 0).x;
        box.targetX = Math.max(0, Math.min(center - boxWidth / 2, barWidth - boxWidth));
    }

    onTargetChanged: if (!target && wanted) closeTimer.restart()

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.railMarginTop + Theme.railHeight + 6
        left: Theme.railMarginSide
        right: Theme.railMarginSide
    }
    exclusionMode: ExclusionMode.Ignore
    implicitHeight: Math.max(box.height, boxHeight) + 8
    color: "transparent"
    visible: false
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-bar-card"

    Timer {
        id: openTimer

        interval: 120
        onTriggered: {
            root.target = root.pending;
            root.pending = null;
            root.glide = false;
            root.visible = true;
            root.place();
            root.wanted = true;
            Qt.callLater(() => root.glide = true);
        }
    }

    Timer {
        id: closeTimer

        interval: 120
        onTriggered: {
            root.wanted = false;
            root.glide = false;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer

        interval: Theme.animFast
        onTriggered: if (!root.wanted) root.visible = false
    }

    Timer {
        interval: 50
        repeat: true
        running: root.visible
        onTriggered: root.place()
    }

    Rectangle {
        id: box

        property real targetX: 0

        x: targetX
        y: root.wanted ? 0 : -6
        width: root.boxWidth
        height: root.boxHeight
        opacity: root.wanted ? 1 : 0
        color: Theme.cardBg
        radius: 12
        border {
            width: 1
            color: Theme.cardBorder
        }
        clip: true

        Behavior on x {
            enabled: root.glide
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
        }

        Behavior on width {
            enabled: root.glide
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
        }

        Behavior on height {
            enabled: root.glide
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast }
        }

        Item {
            id: content

            function flash() {
                flashIn.restart();
            }

            x: 1
            y: 1
            implicitWidth: root.panel ? panelLoader.implicitWidth : label.implicitWidth
            implicitHeight: root.panel ? panelLoader.implicitHeight : label.implicitHeight

            NumberAnimation on opacity {
                id: flashIn

                running: false
                from: 0
                to: 1
                duration: Theme.animNormal
            }

            Txt {
                id: label

                visible: !root.panel
                text: root.target?.tip ?? ""
                textFormat: Text.PlainText
                font.pixelSize: 14
                leftPadding: 10
                rightPadding: 10
                topPadding: 6
                bottomPadding: 6
            }

            Loader {
                id: panelLoader

                active: root.panel !== null
                sourceComponent: root.panel
            }
        }
    }
}
