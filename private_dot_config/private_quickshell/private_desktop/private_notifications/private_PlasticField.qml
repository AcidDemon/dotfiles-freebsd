import QtQuick
import qs.bar
import qs.theme

Plastic {
    id: root

    property alias text: input.text
    property alias placeholder: hint.text
    property alias validator: input.validator
    property alias maximumLength: input.maximumLength
    property bool invalid: false

    signal edited
    signal accepted
    signal escaped

    function focusInput() {
        input.forceActiveFocus();
    }

    color: invalid ? Theme.fieldInvalid : Theme.crust
    radius: 10
    recessed: true
    depth: 0
    opacity: enabled ? 1 : 0.45

    TextInput {
        id: input

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        color: Theme.fg
        selectionColor: Theme.accClock
        selectedTextColor: Theme.crust
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.hintingPreference: Font.PreferFullHinting
        renderType: Text.NativeRendering
        clip: true
        onTextEdited: root.edited()
        onAccepted: root.accepted()
        Keys.onEscapePressed: root.escaped()

        Txt {
            id: hint

            visible: input.text === ""
            font.pixelSize: 13
            color: Theme.overlay0
        }
    }
}
