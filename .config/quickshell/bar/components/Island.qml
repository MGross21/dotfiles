import QtQuick
import Quickshell.Widgets
import "../config"

// A floating cluster of modules. WrapperRectangle sizes itself to its single
// visual child plus margins, so islands grow and shrink with their contents
// instead of needing hand-computed widths.
WrapperRectangle {
    id: root

    property real alpha: Theme.surfaceAlpha

    margin: Theme.islandPadding
    radius: Theme.islandRadius
    color: Theme.surface(alpha)
    antialiasing: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.durBase
            easing.type: Theme.easeStandard
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.durBase
        }
    }
}
