import QtQuick
import QtQuick.Shapes
import "../config"

// Compact arc readout for cpu / memory / temperature. Adwaita ships no
// cpu, ram or temperature symbolic icons, and a generic glyph would carry less
// information than the value itself -- so the value is the icon.
Item {
    id: root

    property real value: 0        // 0..100
    property string label: ""     // short unit shown under the number
    property real warnAt: 70
    property real critAt: 88

    readonly property color tone: Theme.severity(value, warnAt, critAt)
    readonly property real sweep: Math.max(0, Math.min(100, value)) / 100 * 270

    implicitWidth: Theme.contentHeight
    implicitHeight: implicitWidth

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Track
        ShapePath {
            strokeWidth: 2
            strokeColor: Theme.surface(Theme.trackAlpha)
            fillColor: Theme.transparent
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - 1.5
                radiusY: root.height / 2 - 1.5
                startAngle: 135
                sweepAngle: 270
            }
        }

        // Value
        ShapePath {
            strokeWidth: 2
            strokeColor: root.tone
            fillColor: Theme.transparent
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: arc
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - 1.5
                radiusY: root.height / 2 - 1.5
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

    Text {
        anchors.centerIn: parent
        text: Math.round(root.value)
        color: root.tone
        font.family: Theme.font
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true

        Behavior on color {
            ColorAnimation {
                duration: Theme.durBase
            }
        }
    }
}
