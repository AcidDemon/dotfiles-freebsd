import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.bar
import qs.theme
import "../theme/Outline.js" as Outline

PanelWindow {
    id: root

    required property var launcher
    readonly property var modes: [
        { id: "apps", glyph: "\u{F003B}", label: "Apps", hint: "Search apps" },
        { id: "windows", glyph: "\u{F05AF}", label: "Windows", hint: "Search windows" },
        { id: "clipboard", glyph: "\u{F0147}", label: "Clipboard", hint: "Search clipboard" },
        { id: "emoji", glyph: "\u{F01F5}", label: "Emoji", hint: "Search emoji" },
        { id: "calc", glyph: "\u{F00EC}", label: "Calc", hint: "Calculate" }
    ]
    readonly property string tabMode: launcher.mode === "windows-here" ? "windows" : launcher.mode
    readonly property real rowHeight: 46
    // the panel's own measures: top part, flared base, inset of the result well
    readonly property var geometry: ({
        width: 720,
        height: Math.floor((screen?.height ?? 1080) * 0.45),
        flare: Math.max(0, Math.min(270, ((screen?.width ?? 1920) - 720) / 2)),
        flareHeight: Math.floor((screen?.height ?? 1080) * 0.45 * 0.66)
    })
    readonly property real radius: 30
    readonly property real inset: 16
    readonly property real wellTop: 140
    readonly property bool shelfShown: sources.shelfItems.length > 0
    readonly property real shelfHeight: 76
    readonly property int maxRows: Math.max(1, Math.floor((geometry.height - wellTop - 8 - inset - (shelfShown ? shelfHeight : 12)) / rowHeight))
    property bool opened: false
    property bool settled: false

    function close() {
        launcher.closing = true;
    }

    function run(item) {
        if (!item) return;
        sources.activate(item);
        close();
    }

    function move(delta) {
        if (results.count > 0) results.currentIndex = Math.max(0, Math.min(results.count - 1, results.currentIndex + delta));
    }

    function cycleMode(delta) {
        const current = modes.findIndex(m => m.id === tabMode);
        launcher.mode = modes[(current + delta + modes.length) % modes.length].id;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        search.forceActiveFocus();
        opened = true;
    }

    Timer {
        running: true
        interval: 420
        onTriggered: root.settled = true
    }

    Timer {
        running: root.launcher.closing
        interval: Theme.animNormal
        onTriggered: {
            root.launcher.loaded = false;
            root.launcher.closing = false;
        }
    }

    Sources {
        id: sources

        mode: root.launcher.mode
        query: search.text
        // after the model has applied the change, or the list keeps following the old first row
        onItemsChanged: Qt.callLater(() => results.currentIndex = 0)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // a filled band between two parallel outlines
    component Ring: ShapePath {
        id: ring

        property var outer: []
        property var inner: []

        strokeColor: "transparent"
        fillRule: ShapePath.OddEvenFill

        PathMultiline {
            paths: [ring.outer, ring.inner]
        }
    }

    Item {
        id: panel

        readonly property var outer: Outline.inset(root.geometry, 0, 0, root.radius)
        readonly property var well: Outline.inset(root.geometry, root.inset, root.wellTop, 14)
        readonly property real wallLeft: root.geometry.flare

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: root.geometry.width + 2 * root.geometry.flare
        height: root.geometry.height
        transform: Translate {
            y: root.opened && !root.launcher.closing ? 0 : panel.height + 40

            Behavior on y {
                NumberAnimation {
                    // no overshoot: the base must never lift off the screen edge
                    duration: root.launcher.closing ? Theme.animNormal : 380
                    easing.type: root.launcher.closing ? Easing.InCubic : Easing.OutQuint
                }
            }
        }

        GlassEdge {
            id: glass

            anchors.fill: parent
            outline: panel.outer
            glowInner: Outline.inset(root.geometry, 8, 8, root.radius - 8)
            rimInner: Outline.inset(root.geometry, 1.6, 1.6, root.radius - 1.6)
            shadowY: -6
        }

        // swallows clicks on the panel, so only the space around it closes
        MouseArea {
            anchors.fill: parent
            containmentMask: glass.body
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // result well, the outline inset so it runs parallel to the walls
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    y1: root.wellTop
                    y2: panel.height
                    GradientStop { position: 0; color: Qt.darker(Theme.crust, 1.5) }
                    GradientStop { position: 0.06; color: Theme.crust }
                    GradientStop { position: 1; color: Theme.crust }
                }

                PathPolyline {
                    path: panel.well
                }
            }

            Ring {
                outer: panel.well
                inner: Outline.inset(root.geometry, root.inset + 1.2, root.wellTop + 1.2, 12.8)
                fillGradient: LinearGradient {
                    y1: root.wellTop
                    y2: panel.height
                    GradientStop { position: 0; color: Qt.alpha("black", 0.6) }
                    GradientStop { position: 0.5; color: Qt.alpha("white", 0.05) }
                    GradientStop { position: 1; color: Qt.alpha("white", 0.1) }
                }
            }
        }

        Plastic {
            id: tabs

            readonly property real tabWidth: 118

            anchors.horizontalCenter: parent.horizontalCenter
            y: 14
            width: tabWidth * root.modes.length + 12
            height: 48
            color: Theme.crust
            radius: 24
            recessed: true
            depth: 0

            Plastic {
                x: 6 + tabs.tabWidth * root.modes.findIndex(m => m.id === root.tabMode)
                y: 5
                width: tabs.tabWidth
                height: 38
                color: Theme.accClock
                radius: 17
                depth: 3

                Behavior on x {
                    NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
                }
            }

            Row {
                x: 6
                y: 5
                height: 35

                Repeater {
                    model: root.modes

                    delegate: Item {
                        id: tab

                        required property var modelData
                        readonly property bool active: root.tabMode === modelData.id

                        width: tabs.tabWidth
                        height: parent.height

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tab.modelData.glyph
                                size: 16
                                color: tab.active ? Theme.onAccent : tabMouse.containsMouse ? Theme.fg : Theme.fgDim
                            }

                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tab.modelData.label
                                font.pixelSize: 14
                                font.weight: tab.active ? Font.DemiBold : Font.Medium
                                color: tab.active ? Theme.onAccent : tabMouse.containsMouse ? Theme.fg : Theme.fgDim

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animFast }
                                }
                            }
                        }

                        MouseArea {
                            id: tabMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launcher.mode = tab.modelData.id
                        }
                    }
                }
            }
        }

        Plastic {
            id: field

            x: panel.wallLeft + 24
            y: 80
            width: root.geometry.width - 48
            height: 46
            color: Theme.crust
            radius: 12
            recessed: true
            depth: 0

            Glyph {
                id: magnifier

                anchors {
                    left: parent.left
                    leftMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                text: "\u{F0349}"
                color: Theme.accClock
            }

            TextInput {
                id: search

                anchors {
                    left: magnifier.right
                    right: count.left
                    leftMargin: 10
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                color: Theme.fg
                selectionColor: Theme.accClock
                selectedTextColor: Theme.crust
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
                font.hintingPreference: Font.PreferFullHinting
                renderType: Text.NativeRendering
                clip: true

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key === Qt.Key_Escape) root.close();
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.run(sources.items[results.currentIndex]);
                    else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) root.move(1);
                    else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) root.move(-1);
                    else if (event.key === Qt.Key_PageDown) root.move(root.maxRows);
                    else if (event.key === Qt.Key_PageUp) root.move(-root.maxRows);
                    else if (event.key === Qt.Key_Tab) root.cycleMode(1);
                    else if (event.key === Qt.Key_Backtab) root.cycleMode(-1);
                    else return;
                    event.accepted = true;
                }

                Txt {
                    visible: search.text === ""
                    text: root.modes.find(m => m.id === root.tabMode).hint
                    color: Theme.overlay0
                }
            }

            Txt {
                id: count

                anchors {
                    right: parent.right
                    rightMargin: 16
                    verticalCenter: parent.verticalCenter
                }
                visible: search.text !== "" && root.tabMode !== "calc"
                text: `${results.count} ${results.count === 1 ? "result" : "results"}`
                font.pixelSize: 13
                color: Theme.fgDim
            }
        }

        ListView {
            id: results

            x: panel.wallLeft + root.inset + 4
            y: root.wellTop + 4
            width: root.geometry.width - 2 * root.inset - 8
            height: root.maxRows * root.rowHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Theme.animFast
            highlightMoveVelocity: -1
            highlightResizeDuration: 0
            model: ScriptModel {
                values: sources.items
                objectProp: "key"
            }

            highlight: Plastic {
                color: Theme.accClock
                radius: 10
                depth: 3
            }

            delegate: LauncherRow {
                width: ListView.view.width
                height: root.rowHeight
                selected: ListView.isCurrentItem
                query: sources.query
                onHoverMoved: results.currentIndex = index
                onActivated: root.run(modelData)
            }

            displaced: Transition {
                NumberAnimation { property: "y"; duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }

            Behavior on height {
                NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.wellTop + 40
            visible: results.count === 0
            text: sources.emptyText
            color: Theme.fgDim
        }

        Shelf {
            anchors.horizontalCenter: parent.horizontalCenter
            y: panel.height - root.inset - root.shelfHeight
            width: root.geometry.width + root.geometry.flare * 0.7
            height: root.shelfHeight
            divider: root.geometry.width - 2 * root.inset - 80
            items: sources.shelfItems
            opacity: root.shelfShown ? 1 : 0
            visible: opacity > 0
            onPicked: (item, window) => {
                switch (item.kind) {
                case "appfilter":
                    sources.windowFilter = item.active ? "" : item.key;
                    return;
                case "filter":
                    sources.clipFilter = item.key;
                    return;
                case "calc":
                    search.text = item.expression;
                    search.forceActiveFocus();
                    return;
                }
                if (window) window.activate();
                else sources.activate(item);
                root.close();
            }

            Behavior on opacity {
                NumberAnimation { duration: Theme.animFast }
            }
        }
    }
}
