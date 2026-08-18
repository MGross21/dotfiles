import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "../config"

// Recoloring symbolic icons needs BOTH brightness and colorization.
// MultiEffect's `colorization` shifts hue while preserving lightness, and
// Adwaita symbolic icons are near-black (measured: rgb 47,52,54) -- so
// colorization alone leaves them near-black on a dark bar. `brightness: 1.0`
// lifts them first, then colorization carries the hue.
//
// Because brightness saturates lightness, dim variants must come from the
// `opacity` property rather than from a darker `color`.
Item {
    id: root

    property string source: ""
    property color color: Theme.fg
    property int size: Theme.iconSize
    property bool recolor: true

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: img
        anchors.fill: parent
        source: root.source
        asynchronous: true
        visible: !root.recolor
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        visible: root.recolor && root.source !== ""
        brightness: 1.0
        colorization: 1.0
        colorizationColor: root.color

        Behavior on colorizationColor {
            ColorAnimation {
                duration: Theme.durBase
            }
        }
    }
}
