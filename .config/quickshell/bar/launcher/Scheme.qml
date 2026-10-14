import QtQuick
import "../config"

QtObject {
    property bool light: false

    readonly property color paper: light ? Theme.hi : Theme.base
    readonly property color ink: light ? Theme.base : Theme.fg
    readonly property color inkStrong: light ? Theme.base : Theme.hi
    readonly property color inkDim: Theme.tinted(ink, Theme.inkDimAlpha)
    readonly property color accent: light ? Qt.darker(Theme.accent, 1.8) : Theme.accent
}
