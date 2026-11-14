import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.bar
import qs.theme

// the row across the flared base: most-used apps or emoji, open apps to filter windows by,
// or keys for clipboard filters and recent calculations. Running apps get a dot.
Item {
    id: root

    property var items: []
    property real divider: 0
    readonly property real step: width / 12
    readonly property real iconSize: 34
    readonly property bool chips: items.length > 0 && (items[0].kind === "filter" || items[0].kind === "calc")
    readonly property bool filtering: items.some(item => item.active)

    signal picked(var item, var window)

    function windowOf(item) {
        if (item.kind !== "app") return null;
        return ToplevelManager.toplevels.values.find(t => t.appId === item.entry.id || DesktopEntries.heuristicLookup(t.appId)?.id === item.entry.id) ?? null;
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.divider
        height: 1
        color: Qt.alpha("white", 0.07)
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 12
        }

        Repeater {
            model: root.chips ? [] : root.items

            delegate: Item {
                id: slot

                required property var modelData
                readonly property var window: root.windowOf(modelData)

                width: root.step
                height: root.iconSize + 26

                Item {
                    id: icon

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    width: root.iconSize
                    height: root.iconSize
                    transformOrigin: Item.Bottom
                    scale: mouse.containsMouse ? 1.3 : 1
                    opacity: root.filtering && !slot.modelData.active ? 0.4 : 1

                    Behavior on scale {
                        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }

                    IconImage {
                        anchors.fill: parent
                        visible: slot.modelData.kind === "app" || slot.modelData.kind === "appfilter"
                        source: visible ? Quickshell.iconPath(slot.modelData.icon, true) : ""
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: slot.modelData.kind === "emoji"
                        text: slot.modelData.glyph ?? ""
                        font.family: "Noto Color Emoji"
                        font.pixelSize: 28
                    }

                    Rectangle {
                        anchors {
                            right: parent.right
                            top: parent.top
                            margins: -5
                        }
                        visible: (slot.modelData.count ?? 0) > 1
                        width: Math.max(16, badge.implicitWidth + 8)
                        height: 16
                        radius: 8
                        color: Theme.accClock

                        Txt {
                            id: badge

                            anchors.centerIn: parent
                            text: slot.modelData.count ?? ""
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.crust
                        }
                    }
                }

                Rectangle {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: icon.bottom
                        topMargin: 4
                    }
                    visible: slot.window !== null || slot.modelData.active === true
                    width: slot.modelData.active ? 16 : 4
                    height: 4
                    radius: 2
                    color: slot.modelData.active ? Theme.accClock : Qt.alpha(Theme.fg, 0.7)

                    Behavior on width {
                        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                    }
                }

                Txt {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: icon.top
                        bottomMargin: icon.height * 0.3 + 4
                    }
                    text: slot.modelData.kind === "appfilter" ? `${slot.modelData.title} · ${slot.modelData.count}` : slot.modelData.title
                    font.pixelSize: 12
                    color: Theme.fg
                    opacity: mouse.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.picked(slot.modelData, slot.window)
                }
            }
        }
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        spacing: 10

        Repeater {
            model: root.chips ? root.items : []

            delegate: Keycap {
                required property var modelData

                height: 34
                label: modelData.title.length > 26 ? `${modelData.title.slice(0, 25)}…` : modelData.title
                labelSize: 13
                active: modelData.active ?? false
                onClicked: root.picked(modelData, null)
            }
        }
    }
}
