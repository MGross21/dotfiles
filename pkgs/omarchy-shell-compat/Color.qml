pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    readonly property color foreground: Theme.fg
    readonly property color background: Theme.base
    readonly property color accent: Theme.accent
    readonly property color urgent: Theme.urgent
    readonly property color muted: Theme.fgDim

    readonly property color surface: Theme.tinted(Theme.base, Theme.popoutAlpha)
    readonly property color outline: Theme.surface(Theme.outlineAlpha)

    readonly property var shellValues: ({
            "popups.border-alpha": Theme.outlineAlpha,
            "popups.border-width": 1,
            "tooltip.border-alpha": Theme.outlineAlpha,
            "tooltip.border-width": 1
        })

    readonly property QtObject bar: QtObject {
        readonly property color background: Theme.transparent
        readonly property color text: root.foreground
        readonly property color active: root.urgent
    }

    readonly property QtObject popups: QtObject {
        readonly property color background: root.surface
        readonly property color text: root.foreground
        readonly property color border: root.outline
    }

    readonly property QtObject tooltip: QtObject {
        readonly property color background: root.surface
        readonly property color text: root.foreground
        readonly property color border: root.outline
    }

    readonly property QtObject menu: QtObject {
        readonly property color background: root.surface
        readonly property color text: root.foreground
        readonly property color border: root.outline
        readonly property color scrim: Theme.tinted(Theme.base, 0.5)
        readonly property color selectedBackground: Theme.surface(Theme.surfaceHoverAlpha)
        readonly property color selectedText: root.accent
        readonly property color selectedBorder: Theme.transparent
    }

    Binding {
        target: Style
        property: "fontFamily"
        value: Theme.font
    }

    Binding {
        target: Style
        property: "fontBaseSize"
        value: Theme.fontSize
    }

    Binding {
        target: Style
        property: "barScaleWithFont"
        value: false
    }

    Binding {
        target: Style
        property: "barOverrides"
        value: ({
                "size-horizontal": Theme.contentHeight,
                "icon-slot": Theme.contentHeight + 4,
                "icon-canvas": Theme.iconSize,
                "icon-font": Theme.fontSizeLarge,
                "status-slot": Theme.contentHeight
            })
    }
}
