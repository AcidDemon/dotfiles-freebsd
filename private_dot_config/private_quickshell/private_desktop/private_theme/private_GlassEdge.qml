import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.theme

// The launcher's and the notification panel's surface: a filled outline with a shadow,
// a soft glow just inside the edge and a glass rim, both lit from the top.
Item {
    id: root

    property var outline: []
    property var glowInner: []
    property var rimInner: []
    property real shadowX: 0
    property real shadowY: 0
    // the body, for containmentMask on mouse areas
    readonly property alias body: body

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

    Shape {
        id: body

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        containsMode: Shape.FillContains
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1
            shadowColor: Qt.alpha(Theme.crust, 0.7)
            shadowHorizontalOffset: root.shadowX
            shadowVerticalOffset: root.shadowY
        }

        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                y2: root.height
                GradientStop { position: 0; color: Qt.alpha(Base16.base02, 0.94) }
                GradientStop { position: Math.min(0.5, 90 / root.height); color: Qt.alpha(Base16.base00, 0.94) }
                GradientStop { position: 1; color: Qt.alpha(Base16.base01, 0.94) }
            }

            PathPolyline {
                path: root.outline
            }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        Ring {
            outer: root.outline
            inner: root.glowInner
            fillGradient: LinearGradient {
                y2: root.height
                GradientStop { position: 0; color: Qt.alpha("white", 0.14) }
                GradientStop { position: Math.min(0.5, 80 / root.height); color: Qt.alpha("white", 0.03) }
                GradientStop { position: 1; color: Qt.alpha("white", 0) }
            }
        }

        Ring {
            outer: root.outline
            inner: root.rimInner
            fillGradient: LinearGradient {
                y2: root.height
                GradientStop { position: 0; color: Qt.alpha("white", 0.85) }
                GradientStop { position: Math.min(0.5, 55 / root.height); color: Qt.alpha("white", 0.18) }
                GradientStop { position: 0.7; color: Qt.alpha("white", 0.12) }
                GradientStop { position: 1; color: Qt.alpha("white", 0.03) }
            }
        }
    }
}
