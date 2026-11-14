import QtQuick
import qs.theme

Txt {
    id: root

    property real value: 0
    property int decimals: 0
    property int padTo: 0
    property string suffix: "%"
    property real shown: value

    text: shown.toFixed(decimals).padStart(padTo, " ") + suffix

    Behavior on shown {
        NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic }
    }
}
