import QtQuick
import qs.theme

Text {
    id: root

    property real size: Theme.iconSize
    property bool pulsing: false

    function popNow() {
        pop.restart();
    }

    color: Theme.fg
    font.family: Theme.iconFamily
    font.pixelSize: size
    font.hintingPreference: Font.PreferFullHinting
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter

    onTextChanged: pop.restart()
    onPulsingChanged: if (!pulsing) opacity = 1

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    NumberAnimation on scale {
        id: pop

        running: false
        from: 0.72
        to: 1
        duration: Theme.animNormal
        easing.type: Easing.OutBack
    }

    SequentialAnimation on opacity {
        running: root.pulsing
        loops: Animation.Infinite

        NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
    }
}
