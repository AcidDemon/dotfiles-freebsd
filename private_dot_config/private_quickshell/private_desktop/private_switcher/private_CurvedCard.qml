import QtQuick
import "Ring.js" as Ring

// A wallpaper card bent onto the inside of the ring; as it slants into a theme
// card it straightens back into the flat Card it is drawn from.
Item {
    id: root

    property string source: ""
    property real flatX: 0
    property real flatY: 0
    property real flatWidth: 0
    property real flatHeight: 0
    property real slant: 0
    property real theta: 0
    property real arc: 0
    property real cardHeight: 0
    property real focal: 1
    property real back: 0
    property real centreX: 0
    property real centreY: 0
    property real floorY: 0
    property bool selected: false
    property var colors: ({})
    property real fade: 1
    property real gloss: 0
    property real edge: 0
    property real shadow: 0
    property real reflect: 0
    property real floorOpacity: 0
    // reflection and shadow go here, under the theme cards and every other card
    property Item under: null
    readonly property real bend: 1 - slant
    default property alias content: card.overlay
    readonly property alias picture: card

    // niri's border: the theme's active gradient, inactive-color for the rest
    readonly property color borderTop: selected ? colors.borderFrom : colors.base02
    readonly property color borderBottom: selected ? colors.borderTo : colors.base02
    readonly property real pad: cardHeight * 0.008

    signal clicked

    anchors.fill: parent

    component Strip: ShaderEffect {
        property vector4d flatRect: Qt.vector4d(root.flatX, root.flatY, root.flatWidth, root.flatHeight)
        property vector4d view: Qt.vector4d(root.focal, root.centreX, root.centreY, root.back)
        property vector4d strip: Qt.vector4d(root.theta, root.arc, root.cardHeight, 0)
        property vector4d pose: Qt.vector4d(root.bend, 1, 0, root.floorY)
        property vector4d light: Qt.vector4d(0, 0, 0, 0)
        property vector4d colorTop: Qt.vector4d(0, 0, 0, 0)
        property vector4d colorBottom: Qt.vector4d(0, 0, 0, 0)
        property vector4d box: Qt.vector4d(0, 0, 1, 0)

        anchors.fill: parent
        visible: opacity > 0
        vertexShader: Qt.resolvedUrl("shaders/ring.vert.qsb")
        mesh: GridMesh {
            resolution: Qt.size(64, 1)
        }
    }

    Card {
        id: card

        width: root.flatWidth
        height: root.flatHeight
        source: root.source
        slant: root.slant
        radius: root.flatHeight * 0.05
        rimWidth: root.slant > 0.001 ? 1.5 * root.slant : -1
    }

    // a hidden layer is drawn once; this follows MiniDesktop and peek as they change
    ShaderEffectSource {
        id: picture

        width: card.width
        height: card.height
        sourceItem: card
        hideSource: true
        live: true
        visible: false
    }

    Strip {
        property var source: picture

        parent: root.under ?? root
        visible: root.visible && opacity > 0
        opacity: root.reflect * (1 - root.floorOpacity) * root.fade * root.bend
        pose: Qt.vector4d(root.bend, 1, 1, root.floorY)
        fragmentShader: Qt.resolvedUrl("shaders/card.frag.qsb")
    }

    // soft shadow: a blurred core about the card's size, a little lower
    Strip {
        parent: root.under ?? root
        visible: root.visible && opacity > 0
        opacity: root.shadow * root.fade * root.bend
        strip: Qt.vector4d(root.theta, root.arc * 1.24, root.cardHeight * 1.5, -0.07 * root.cardHeight)
        pose: Qt.vector4d(root.bend, 1.05, 0, root.floorY)
        colorTop: Qt.vector4d(0, 0, 0, 1)
        colorBottom: Qt.vector4d(0, 0, 0, 1)
        box: Qt.vector4d(0.07, 0.148, root.arc * 1.24 / Math.max(1e-6, root.cardHeight * 1.5), 0.2)
        fragmentShader: Qt.resolvedUrl("shaders/shape.frag.qsb")
    }

    Strip {
        readonly property real h: root.cardHeight + 2 * root.pad
        readonly property real pixels: Math.max(1, h * root.focal / (1 + root.back))

        opacity: root.fade * root.bend
        strip: Qt.vector4d(root.theta, root.arc + 2 * root.pad, h, 0)
        pose: Qt.vector4d(root.bend, 1.002, 0, root.floorY)
        colorTop: Qt.vector4d(root.borderTop.r, root.borderTop.g, root.borderTop.b, 1)
        colorBottom: Qt.vector4d(root.borderBottom.r, root.borderBottom.g, root.borderBottom.b, 1)
        box: Qt.vector4d((root.cardHeight * 0.05 + root.pad) / Math.max(1e-6, h), 0.5 / pixels, (root.arc + 2 * root.pad) / Math.max(1e-6, h), 0.5 / pixels)
        fragmentShader: Qt.resolvedUrl("shaders/shape.frag.qsb")
    }

    Strip {
        property var source: picture

        opacity: root.fade
        light: Qt.vector4d(root.gloss * root.bend, root.edge * root.bend, 0, 0)
        fragmentShader: Qt.resolvedUrl("shaders/card.frag.qsb")
    }

    MouseArea {
        readonly property var area: root.bend > 0.5
            ? Ring.bounds(root.theta, root.arc, root.cardHeight, 0, root.back, root.focal, root.centreX, root.centreY)
            : Qt.rect(root.flatX, root.flatY, root.flatWidth, root.flatHeight)

        x: area.x
        y: area.y
        width: area.width
        height: area.height
        onClicked: root.clicked()
    }
}
