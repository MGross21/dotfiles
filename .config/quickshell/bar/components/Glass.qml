import QtQuick
import "../config"

// Translucent surface with a rim highlight. The blur behind it is the
// compositor's job (hypr layer_rule on the quickshell-bar namespace); this
// only has to stay see-through and provide the specular edge.
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
}
