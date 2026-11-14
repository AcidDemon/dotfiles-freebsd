import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.theme

PanelWindow {
    id: bar

    readonly property alias card: hoverCard
    // the laptop panel: the tunnel name and the tray fold away so the island fits
    readonly property bool compact: width < 3000

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.railMarginTop
        left: Theme.railMarginSide
        right: Theme.railMarginSide
    }
    // room below the frame for its shadow; windows still only make way for the frame itself
    implicitHeight: Theme.railHeight + 14
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.railHeight
    mask: Region {
        item: rail
    }
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"
    // niri and Hyprland blur behind the frame only, not the shadow below it
    BackgroundEffect.blurRegion: Region {
        item: rail
        radius: Theme.railRadius
    }

    IdleInhibitor {
        window: bar
        enabled: Sys.idleInhibited
    }

    HoverCard {
        id: hoverCard

        screen: bar.screen
    }

    Item {
        id: rail

        width: parent.width
        height: Theme.railHeight

        RectangularShadow {
            anchors.fill: parent
            radius: Theme.railRadius
            blur: 12
            offset.y: 3
            color: Qt.alpha("black", 0.4)
        }

        // frosted: a light tint over the blurred wallpaper
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Base16.base00, 0.75)
            radius: Theme.railRadius
        }

        // rim lit from the top like the launcher, the notification panel and the OSD
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill
                fillGradient: LinearGradient {
                    y2: rail.height
                    GradientStop { position: 0; color: Qt.alpha("white", 0.6) }
                    GradientStop { position: 0.15; color: Qt.alpha("white", 0.22) }
                    GradientStop { position: 0.6; color: Qt.alpha("white", 0.07) }
                    GradientStop { position: 1; color: Qt.alpha("white", 0.05) }
                }

                PathRectangle {
                    width: rail.width
                    height: rail.height
                    radius: Theme.railRadius
                }
                PathRectangle {
                    x: 2
                    y: 2
                    width: rail.width - 4
                    height: rail.height - 4
                    radius: Theme.railRadius - 2
                }
            }
        }

        RowLayout {
            id: leftRow

            anchors {
                left: parent.left
                leftMargin: 4
                verticalCenter: parent.verticalCenter
            }
            spacing: 0

            Pill {
                pad: 0
                rightInset: 14
                hoverFill: Qt.tint(Theme.pillBg, Qt.alpha(Theme.accPower, 0.22))

                Cell {
                    padLeft: 9
                    padRight: 9
                    hoverable: false
                    onClicked: Power.open = !Power.open

                    Glyph {
                        text: "󰐥"
                        size: 19
                        color: Theme.accPower
                    }
                }
            }

            Workspaces {
                screen: bar.screen
            }

            MediaGroup {}
        }

        // truly centred, and never wider than the room on its narrower side
        Island {
            x: (rail.width - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            maxWidth: 2 * Math.min(rail.width / 2 - (leftRow.x + leftRow.width), rightRow.x - rail.width / 2) - 24
        }

        RowLayout {
            id: rightRow

            anchors {
                right: parent.right
                rightMargin: 4
                verticalCenter: parent.verticalCenter
            }
            spacing: 0

            SystemGroup {}
            NetGroup { compact: bar.compact }
            AudioDrawer {}
            Battery {}
            UtilGroup { compact: bar.compact }
            ClockDrawer {}
        }
    }
}
