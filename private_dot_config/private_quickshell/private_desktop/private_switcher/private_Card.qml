import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.theme

// A wallpaper cut to a rounded outline that can slant into a parallelogram (theme cards).
Item {
    id: root

    property string source: ""
    // one size for every card, so a theme card and the preview share a decoded image
    property int sourceWidth: 2048
    // 0..1
    property real slant: 0
    property real radius: 14
    property color rim: Qt.alpha("white", 0.18)
    property real rimWidth: 1.5
    default property alias overlay: decor.data

    readonly property real shift: slant * height * 0.2
    readonly property string outline: path(width, height, shift, Math.min(radius, height / 4))

    function path(w, h, k, r) {
        const pts = [[k, 0], [w, 0], [w - k, h], [0, h]];
        const unit = (a, c) => {
            const dx = c[0] - a[0], dy = c[1] - a[1], len = Math.hypot(dx, dy) || 1;
            return [dx / len, dy / len];
        };
        const at = (p, u, d) => `${p[0] + u[0] * d} ${p[1] + u[1] * d}`;
        const u = [0, 1, 2, 3].map(i => unit(pts[i], pts[(i + 1) % 4]));
        return `M ${at(pts[0], u[0], r)}`
            + ` L ${at(pts[1], u[0], -r)}`
            + ` Q ${pts[1][0]} ${pts[1][1]} ${at(pts[1], u[1], r)}`
            + ` L ${at(pts[2], u[1], -r)}`
            + ` Q ${pts[2][0]} ${pts[2][1]} ${at(pts[2], u[2], r)}`
            + ` L ${at(pts[3], u[2], -r)}`
            + ` Q ${pts[3][0]} ${pts[3][1]} ${at(pts[3], u[3], r)}`
            + ` L ${at(pts[0], u[3], -r)}`
            + ` Q ${pts[0][0]} ${pts[0][1]} ${at(pts[0], u[0], r)} Z`;
    }

    Item {
        id: picture

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            color: Theme.crust
        }

        Image {
            anchors.fill: parent
            source: root.source !== "" ? "file://" + root.source : ""
            sourceSize.width: root.sourceWidth
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }

    Shape {
        id: mask

        anchors.fill: parent
        visible: false
        layer.enabled: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "white"
            strokeWidth: -1

            PathSvg { path: root.outline }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: picture
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Item {
        id: decor

        anchors.fill: parent
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.rim
            strokeWidth: root.rimWidth

            PathSvg { path: root.outline }
        }
    }
}
