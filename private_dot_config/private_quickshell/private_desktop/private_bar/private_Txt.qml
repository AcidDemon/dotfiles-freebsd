import QtQuick
import qs.theme

Text {
    property bool fade: false

    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Font.Medium
    font.hintingPreference: Font.PreferFullHinting
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter

    onTextChanged: if (fade) fadeIn.restart()

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
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
