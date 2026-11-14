import QtQuick
import qs.bar
import qs.theme

Item {
    id: root

    property real value: 0
    property string glyph: ""
    property string label: ""
    property color accent: Theme.accClock
    property real dragValue: 0
    readonly property bool dragging: mouse.pressed && !mouse.onGlyph
    readonly property real shown: dragging ? dragValue : Math.max(0, Math.min(1, value))
    readonly property bool off: shown < 0.005
    readonly property real grooveX: 30
    readonly property real grooveWidth: width - grooveX - 46
    readonly property real knobSize: height - 12
    readonly property real travel: grooveWidth - 12 - knobSize
    property real position: shown

    signal moved(real value)
    signal glyphClicked

    function valueAt(x) {
        return Math.max(0, Math.min(1, (x - grooveX - 6 - knobSize / 2) / travel));
    }

    implicitHeight: 36

    Behavior on position {
        enabled: !root.dragging
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    Glyph {
        x: 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        size: 18
        color: root.off ? Theme.overlay0 : Theme.fg
    }

    Item {
        x: root.grooveX
        width: root.grooveWidth
        height: parent.height

        Plastic {
            anchors.fill: parent
            color: Theme.crust
            radius: height / 2
            recessed: true
            depth: 0
        }

        Plastic {
            id: fill

            x: 3
            y: 3
            width: 3 + root.position * root.travel + root.knobSize + 3
            height: parent.height - 6
            color: root.accent
            radius: height / 2
            depth: 0
            opacity: root.off ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: Theme.animFast }
            }
        }

        Txt {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: root.knobSize + 18
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            visible: root.label !== ""
            text: root.label
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: 13
            color: !root.off && fill.width > x + 60 ? Theme.crust : Theme.fg
        }

        Plastic {
            x: 6 + root.position * root.travel
            y: (parent.height - height) / 2
            width: root.knobSize
            height: root.knobSize
            color: root.off ? Base16.base03 : Base16.base05
            radius: root.knobSize / 2
            depth: 2
            scale: mouse.containsMouse || root.dragging ? 1.14 : 1

            Behavior on scale {
                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack }
            }

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }
    }

    NumberText {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        value: Math.round(root.shown * 100)
        font.pixelSize: 13
        color: root.off ? Theme.overlay0 : Theme.fg
    }

    MouseArea {
        id: mouse

        property bool onGlyph: false
        property int wheelRest: 0

        anchors.fill: parent
        hoverEnabled: true
        onPressed: event => {
            onGlyph = event.x < root.grooveX;
            if (onGlyph) return;
            root.dragValue = root.valueAt(event.x);
            root.moved(root.dragValue);
        }
        onPositionChanged: event => {
            if (!pressed || onGlyph) return;
            root.dragValue = root.valueAt(event.x);
            root.moved(root.dragValue);
        }
        onClicked: {
            if (onGlyph) root.glyphClicked();
        }
        onWheel: event => {
            wheelRest += event.angleDelta.y;
            const steps = Math.trunc(wheelRest / 120);
            if (steps === 0) return;
            wheelRest -= steps * 120;
            root.moved(Math.max(0, Math.min(1, root.value + steps * 0.05)));
        }
    }
}
