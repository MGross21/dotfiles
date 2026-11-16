pragma Singleton

import QtQuick
import qs.Commons
import qs.Commons as Commons

// Launcher tokens, mapped onto the omarchy shell's [menu] palette and Style metrics.
QtObject {
    id: root

    readonly property color base: Commons.Color.menu.background
    readonly property color fg: Commons.Color.menu.text
    readonly property color accent: Commons.Color.accent
    readonly property color selectedText: Commons.Color.menu.selectedText
    readonly property color danger: Commons.Color.urgent
    readonly property color selectionFill: Commons.Color.menu.selectedBackground
    readonly property color scrim: Commons.Color.menu.scrim
    readonly property color border: Commons.Color.menu.border
    readonly property var borderSpec: Border.surfaceSpec("menu", "border", root.border, Math.max(1, Style.space(2)))
    readonly property color controlFill: Style.normalFill
    readonly property color controlHoverFill: Style.hoverFill
    readonly property color controlBorder: Style.normalBorderColor
    readonly property color focusBorder: Style.focusBorderColor
    readonly property color inkDim: root.tinted(root.fg, 0.58)
    readonly property color transparent: "transparent"

    function tinted(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    readonly property int radius: Style.cornerRadius
    readonly property int gap: Style.spacing.sm
    readonly property int padding: Style.spacing.xxl
    readonly property int cardPadding: Style.spacing.panelPadding
    readonly property int iconSize: Style.font.icon

    readonly property int launcherWidth: Style.space(640)
    readonly property int launcherFieldHeight: Math.max(Style.space(40), Style.font.heading + Style.spacing.inputPaddingY * 2)
    readonly property int launcherRows: 8
    readonly property int launcherRowHeight: Math.max(Style.space(48), Style.font.title + Style.font.body + Style.spacing.rowPaddingX * 2)
    readonly property int launcherIconSize: Style.space(30)
    readonly property int launcherPreviewWidth: Style.space(320)
    readonly property int launcherPreviewIconSize: Style.space(72)
    readonly property int launcherSectionHeight: Style.space(26)
    readonly property int launcherChipHeight: Style.spacing.controlHeight
    readonly property int launcherHintHeight: Style.space(18)
    readonly property int launcherTileSize: Style.space(96)
    readonly property int launcherTileIconSize: Style.space(44)

    readonly property string font: Style.font.menuFamily
    readonly property int fontSize: Style.font.body
    readonly property int fontSizeSmall: Style.font.caption
    readonly property int fontSizeLarge: Style.font.title
    readonly property int fontSizeInput: Style.font.heading
    readonly property int fontSizeHeading: Style.font.heading

    readonly property int durFast: Style.duration(120)
    readonly property int durBase: Style.duration(200)
    readonly property int durSlow: Style.duration(350)
    readonly property int stagger: Style.duration(18) // ms per row on open
    readonly property int easeStandard: Easing.OutCubic
}
