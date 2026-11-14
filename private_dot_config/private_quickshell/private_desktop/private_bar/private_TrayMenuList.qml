import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root

    property var menu: null

    signal activated

    spacing: 1

    QsMenuOpener {
        id: opener

        menu: root.menu
    }

    Repeater {
        model: opener.children

        delegate: TrayMenuEntry {
            Layout.fillWidth: true
            onActivated: root.activated()
        }
    }
}
