import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.bar
import qs.theme
import "Match.js" as Match

Item {
    id: root

    required property var modelData
    required property int index
    property bool selected: false
    property string query: ""
    readonly property string typed: modelData.fields ? query : ""
    readonly property string matchColor: selected ? Theme.matchOnAccent : Theme.matchOnDark

    signal hoverMoved
    signal activated

    NumberAnimation on opacity {
        from: 0
        to: 1
        duration: Theme.animNormal
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 14
            bottomMargin: 3
        }
        spacing: 12

        Item {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            IconImage {
                anchors.fill: parent
                visible: !root.modelData.glyph
                source: root.modelData.icon ? Quickshell.iconPath(root.modelData.icon, true) : ""
            }

            Text {
                anchors.centerIn: parent
                visible: !!root.modelData.glyph
                text: root.modelData.glyph ?? ""
                font.family: root.modelData.kind === "emoji" ? "Noto Color Emoji" : Theme.iconFamily
                font.pixelSize: 22
                color: root.selected ? Theme.onAccent : Theme.fgDim
            }
        }

        Txt {
            Layout.maximumWidth: root.width * 0.62
            text: Match.highlight(root.modelData.title, root.typed, root.matchColor)
            textFormat: Text.StyledText
            elide: Text.ElideRight
            font.weight: root.selected ? Font.DemiBold : Font.Medium
            color: root.selected ? Theme.onAccent : Theme.fg
        }

        Txt {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: Match.highlight(root.modelData.detail, root.typed, root.matchColor)
            textFormat: Text.StyledText
            elide: Text.ElideRight
            font.pixelSize: 13
            color: root.selected ? Qt.alpha(Theme.onAccent, 0.75) : Theme.overlay0
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: root.hoverMoved()
        onClicked: root.activated()
    }
}
