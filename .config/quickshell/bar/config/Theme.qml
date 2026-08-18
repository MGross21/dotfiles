pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Design tokens. Everything visual reads from here -- no literal colors,
// durations or radii anywhere else in the shell.
Singleton {
    id: root

    // ── palette ────────────────────────────────────────────────────────
    // Emitted by modules/theme.nix, so the bar follows `theming.name` along
    // with ghostty, nvim, hyprland and the rest. The literals below are only
    // a fallback for running the bar outside the NixOS config.
    property var pal: ({})

    FileView {
        id: paletteFile
        path: "/etc/quickshell/colors.json"
        // Colors are needed before the first frame is drawn, which is the one
        // case the docs sanction blockLoading for.
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.pal = root._parse()
    }

    Component.onCompleted: root.pal = root._parse()

    function _parse(): var {
        try {
            return JSON.parse(paletteFile.text());
        } catch (e) {
            return {};
        }
    }

    readonly property color base: pal.base ?? "#151515"
    readonly property color fg: pal.fg ?? "#f5f5f5"
    readonly property color fgDim: pal.fgDim ?? "#5d6f71"
    readonly property color accent: pal.accent ?? "#fc595f"
    readonly property color good: pal.good ?? "#a63c40"
    readonly property color warn: pal.warn ?? "#d3494e"
    readonly property color urgent: pal.urgent ?? "#ff0000"

    // ── surface / glass ────────────────────────────────────────────────
    // Fills stay translucent on purpose: the compositor blurs the region
    // behind the layer surface, and an opaque fill hides that entirely.
    readonly property real surfaceAlpha: 0.10
    readonly property real surfaceHoverAlpha: 0.18
    readonly property real surfaceActiveAlpha: 0.26
    readonly property real rimAlpha: 0.16
    readonly property real trackAlpha: 0.18

    readonly property color transparent: "transparent"

    function surface(a: real): color {
        return Qt.rgba(1, 1, 1, a);
    }

    function tinted(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // ── metrics ────────────────────────────────────────────────────────
    // barHeight is the island height; the window is barMargin taller so the
    // islands float clear of the screen edge.
    readonly property int barHeight: 26
    readonly property int barMargin: 6
    readonly property int islandPadding: 4
    readonly property int gap: 4
    readonly property int iconSize: 14

    // Height of anything sitting inside an island.
    readonly property int contentHeight: barHeight - islandPadding * 2

    readonly property int islandRadius: barHeight / 2
    readonly property int pillRadius: contentHeight / 2
    readonly property int popoutRadius: 14

    // Popout content widths.
    readonly property int popoutWidth: 190
    readonly property int menuWidth: 200
    readonly property int listWidth: 250

    // ── type ───────────────────────────────────────────────────────────
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 10
    readonly property int fontSizeLarge: 13
    readonly property int fontSizeSmall: 9
    readonly property int fontSizeHeading: 18
    readonly property int fontSizeDisplay: 30

    // ── motion ─────────────────────────────────────────────────────────
    readonly property int durFast: 120
    readonly property int durBase: 200
    readonly property int durSlow: 350
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutBack

    // Severity ramp shared by every gauge and readout.
    function severity(value: real, warnAt: real, critAt: real): color {
        if (value >= critAt)
            return root.urgent;
        if (value >= warnAt)
            return root.warn;
        return root.accent;
    }
}
