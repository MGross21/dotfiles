import QtQuick
import "../config"

// Translucent surface with edge treatment. The blur behind it is the
// compositor's job; the sheen, outline and shadow are not, because hyprglass'
// own edge effects barely reach an island (hypr/module/glass.lua). Decoration
// is gated on `rim`, so `alpha: 0` fades all of it, not just the fill.
Rectangle {
    id: root

    property real alpha: Theme.surfaceAlpha
    property bool rim: true

    color: Theme.surface(alpha)
    radius: Theme.pillRadius
    antialiasing: true

    Behavior on color {
        ColorAnimation {
            duration: Theme.durBase
            easing.type: Theme.easeStandard
        }
    }

    // Top-face light falloff, the cue a flat fill lacks.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        antialiasing: true
        visible: root.rim
        opacity: root.rim ? 1 : 0

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Theme.surface(root.alpha * Theme.sheenAlpha)
            }
            GradientStop {
                position: 0.55
                color: Theme.transparent
            }
            GradientStop {
                position: 1.0
                color: Theme.transparent
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durBase
            }
        }
    }

    // Defines where the pane ends; a 10%-white fill on a dark backdrop has no
    // discernible border on its own.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        antialiasing: true
        color: Theme.transparent
        border.width: 1
        border.color: Theme.surface(Theme.outlineAlpha)
        visible: root.rim
        opacity: root.rim ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durBase
            }
        }
    }

    // Top-edge specular. Inset by the corner radius so it does not bleed
    // past the curve.
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: parent.radius * 0.6
            rightMargin: parent.radius * 0.6
        }
        height: 1
        radius: 0.5
        visible: root.rim
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Theme.transparent
            }
            GradientStop {
                position: 0.5
                color: Theme.surface(Theme.rimAlpha)
            }
            GradientStop {
                position: 1.0
                color: Theme.transparent
            }
        }
    }

    // Bottom inner shadow. A lit top edge alone reads as paint on a flat shape;
    // pairing it with an occluded bottom edge is what gives thickness.
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: parent.radius * 0.6
            rightMargin: parent.radius * 0.6
        }
        height: 1
        radius: 0.5
        visible: root.rim
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Theme.transparent
            }
            GradientStop {
                position: 0.5
                color: Theme.shade(Theme.shadowAlpha)
            }
            GradientStop {
                position: 1.0
                color: Theme.transparent
            }
        }
    }
}
