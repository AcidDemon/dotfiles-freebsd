import QtQuick
import qs.theme

// One line of text that scrolls when it doesn't fit: a pause, then a slow loop
// with a second copy following, so the start comes back round without a jump.
Item {
    id: root

    property string text: ""
    property color color: Theme.fg
    property real pixelSize: Theme.fontSize
    property int weight: Font.Medium
    property bool fade: false
    // pixels per second
    property real speed: 30
    readonly property real gap: 48
    readonly property bool overflows: first.implicitWidth > width + 1

    implicitWidth: first.implicitWidth
    implicitHeight: first.implicitHeight
    clip: true

    // a new track starts from the beginning, with the pause first
    onTextChanged: {
        strip.x = 0;
        if (roll.running) roll.restart();
        if (fade) fadeIn.restart();
    }
    onOverflowsChanged: strip.x = 0

    Row {
        id: strip

        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        Txt {
            id: first

            text: root.text
            textFormat: Text.PlainText
            color: root.color
            font.pixelSize: root.pixelSize
            font.weight: root.weight
        }

        Txt {
            visible: root.overflows
            text: root.text
            textFormat: Text.PlainText
            color: root.color
            font.pixelSize: root.pixelSize
            font.weight: root.weight
        }

        SequentialAnimation on x {
            id: roll

            running: root.overflows && root.visible
            loops: Animation.Infinite

            PauseAnimation { duration: 1800 }
            NumberAnimation {
                from: 0
                to: -(first.implicitWidth + root.gap)
                duration: 1000 * (first.implicitWidth + root.gap) / root.speed
            }
        }
    }

    NumberAnimation on opacity {
        id: fadeIn

        running: false
        from: 0.2
        to: 1
        duration: Theme.animNormal
        easing.type: Easing.OutCubic
    }
}
