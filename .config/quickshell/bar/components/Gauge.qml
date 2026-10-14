import QtQuick
import QtQuick.Shapes
import "../config"

Item {
    id: root

    property real value: 0
    property real min: 0
    property real max: 100
    property string glyph: ""
    property real warnAt: 70
    property real critAt: 88

    readonly property color tone: Theme.severity(value, warnAt, critAt)
    readonly property bool critical: value >= critAt
    readonly property real sweep: Math.max(0, Math.min(1, (value - min) / (max - min))) * 270

    implicitWidth: Theme.contentHeight
    implicitHeight: implicitWidth

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Track
        ShapePath {
            strokeWidth: 2.5
            strokeColor: Theme.surface(Theme.trackAlpha)
            fillColor: Theme.transparent
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - 1.75
                radiusY: root.height / 2 - 1.75
                startAngle: 135
                sweepAngle: 270
            }
        }

        // Value
        ShapePath {
            strokeWidth: 2.5
            strokeColor: root.tone
            fillColor: Theme.transparent
            capStyle: ShapePath.RoundCap

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Theme.durBase
                }
            }

            PathAngleArc {
                id: arc
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - 1.75
                radiusY: root.height / 2 - 1.75
                startAngle: 135
                sweepAngle: root.sweep

                Behavior on sweepAngle {
                    NumberAnimation {
                        duration: Theme.durSlow
                        easing.type: Theme.easeStandard
                    }
                }
            }
        }
    }

    SequentialAnimation on opacity {
        running: root.critical
        loops: Animation.Infinite
        onRunningChanged: if (!running)
            root.opacity = 1

        NumberAnimation {
            to: 0.45
            duration: 700
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 1
            duration: 700
            easing.type: Easing.InOutSine
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: root.tone
        font.family: Theme.font
        font.pixelSize: Theme.fontSizeSmall - 1

        Behavior on color {
            ColorAnimation {
                duration: Theme.durBase
            }
        }
    }
}
