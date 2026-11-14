import QtQuick
import QtQuick.Shapes
import qs.theme

Shape {
    implicitWidth: 15
    implicitHeight: 30
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: Theme.divider
        strokeWidth: 0
        strokeColor: "transparent"
        startX: 15
        startY: 0

        PathArc { x: 15; y: 30; radiusX: 15; radiusY: 15; direction: PathArc.Counterclockwise }
        PathArc { x: 15; y: 0; radiusX: 14; radiusY: 15; direction: PathArc.Clockwise }
    }
}
