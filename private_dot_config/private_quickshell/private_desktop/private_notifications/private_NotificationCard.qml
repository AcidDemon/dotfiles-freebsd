import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.bar
import qs.theme
import "Notify.js" as Notify

Item {
    id: root

    required property var notification
    property int bodyLines: 10
    property real remaining: -1
    property real slide: 0
    property real dragOffset: 0
    property bool dragging: false
    readonly property bool hovered: hover.hovered
    readonly property string image: notification?.image ?? ""
    // the first that resolves: the sender's icon, its desktop entry's, then one found by app name
    readonly property string appIcon: {
        const n = notification;
        const names = [n?.appIcon, DesktopEntries.byId(n?.desktopEntry ?? "")?.icon, DesktopEntries.heuristicLookup(n?.appName ?? "")?.icon];
        for (const name of names.filter(Boolean)) {
            const source = Notify.iconUrl(name) || Quickshell.iconPath(name, true);
            if (source) return source;
        }
        return "";
    }
    readonly property color urgencyColor: notification?.urgency === NotificationUrgency.Critical ? Theme.stCritical
        : notification?.urgency === NotificationUrgency.Low ? Theme.overlay0
        : Theme.accClock

    signal closeRequested
    signal activated(var action)

    implicitHeight: content.implicitHeight + 24 + body.depth

    HoverHandler {
        id: hover
    }

    Plastic {
        id: body

        x: root.slide + root.dragOffset
        width: parent.width
        height: parent.height
        color: Base16.base01
        radius: 14
        depth: 3

        Behavior on x {
            enabled: !root.dragging
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        MouseArea {
            property real startX: 0
            property bool moved: false

            anchors.fill: parent
            onPressed: event => {
                startX = mapToItem(null, event.x, 0).x;
                moved = false;
                root.dragging = true;
            }
            onPositionChanged: event => {
                const offset = mapToItem(null, event.x, 0).x - startX;
                if (Math.abs(offset) > 6) moved = true;
                root.dragOffset = Math.max(0, offset);
            }
            onReleased: {
                root.dragging = false;
                if (root.dragOffset > root.width * 0.3) root.closeRequested();
                else root.dragOffset = 0;
                if (!moved) root.activated(null);
            }
        }

        Rectangle {
            x: 5
            y: 10
            width: 3
            height: parent.height - 20
            radius: 1.5
            color: root.urgencyColor
        }

        ColumnLayout {
            id: content

            x: 16
            y: 12
            width: parent.width - 16 - 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item {
                    visible: root.image !== "" || root.appIcon !== ""
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    Layout.alignment: Qt.AlignTop

                    ClippingRectangle {
                        anchors.fill: parent
                        visible: root.image !== ""
                        radius: 10
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            source: root.image
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    IconImage {
                        anchors.fill: parent
                        visible: root.image === ""
                        source: root.appIcon
                    }

                    IconImage {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                            margins: -4
                        }
                        visible: root.image !== "" && root.appIcon !== ""
                        implicitSize: 24
                        source: root.appIcon
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Txt {
                            Layout.fillWidth: true
                            text: root.notification?.summary ?? ""
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        Txt {
                            text: Notify.ageLabel(Notifs.now - (Notifs.arrivals[root.notification?.id] ?? Notifs.now))
                            font.pixelSize: 12
                            color: Theme.overlay0
                        }

                        // always there, so a single notification can go without a swipe
                        Keycap {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 11
                            depth: 2
                            glyph: "\u{F0156}"
                            glyphSize: 12
                            opacity: root.hovered ? 1 : 0.7
                            onClicked: root.closeRequested()
                        }
                    }

                    Txt {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: Notify.sanitizeBody(root.notification?.body ?? "")
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: root.bodyLines
                        elide: Text.ElideRight
                        font.pixelSize: 13
                        font.weight: Font.Normal
                        color: Theme.subtext1
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                visible: actionRepeater.count > 0
                spacing: 6

                Repeater {
                    id: actionRepeater

                    model: Notifs.actionsOf(root.notification).filter(a => a.identifier !== "default")

                    delegate: Keycap {
                        required property var modelData

                        height: 32
                        radius: 9
                        depth: 3
                        label: modelData.text
                        onClicked: root.activated(modelData)
                    }
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: 14
                bottomMargin: 2
            }
            visible: root.remaining >= 0
            width: Math.max(0, (parent.width - 28) * root.remaining)
            height: 2
            radius: 1
            color: root.urgencyColor
            opacity: 0.8
        }
    }
}
