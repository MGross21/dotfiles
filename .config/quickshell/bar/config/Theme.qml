pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The only place literal colors, durations and radii may appear.
Singleton {
    id: root

    // ── palette ────────────────────────────────────────────────────────
    // Literals are fallbacks for running outside the NixOS config.
    property var pal: ({})

    FileView {
        id: paletteFile
        path: "/etc/quickshell/colors.json"
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
    readonly property color hi: pal.hi ?? "#ffffff"
    readonly property color accent: pal.accent ?? "#fc595f"
    readonly property color good: pal.good ?? "#a63c40"
    readonly property color warn: pal.warn ?? "#d3494e"
    readonly property color urgent: pal.urgent ?? "#ff0000"

    // ── surface / glass ────────────────────────────────────────────────
    // Fills must stay translucent.
    readonly property real surfaceAlpha: 0.10
    readonly property real surfaceHoverAlpha: 0.18
    readonly property real surfaceActiveAlpha: 0.26
    readonly property real rimAlpha: 0.16
    readonly property real trackAlpha: 0.18

    readonly property real sheenAlpha: 0.9 // scales `alpha`
    readonly property real outlineAlpha: 0.10
    readonly property real shadowAlpha: 0.28

    readonly property real popoutAlpha: 0.88
    readonly property real launcherAlpha: 0.62
    readonly property real launcherAlphaMax: 0.92
    readonly property real scrimAlpha: 0.25
    readonly property real inkDimAlpha: 0.55
    readonly property real selectionAlpha: 0.16
    readonly property real selectionRimAlpha: 0.30

    readonly property color transparent: "transparent"

    function surface(a: real): color {
        return Qt.rgba(1, 1, 1, a);
    }

    function shade(a: real): color {
        return Qt.rgba(0, 0, 0, a);
    }

    function tinted(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    readonly property color inkDim: tinted(fg, inkDimAlpha)

    // ── metrics ────────────────────────────────────────────────────────
    // barHeight is the island height; the window is barMargin taller.
    readonly property int barHeight: 26
    readonly property int barMargin: 6
    readonly property int islandPadding: 4
    readonly property int gap: 4
    readonly property int iconSize: 14

    readonly property int contentHeight: barHeight - islandPadding * 2

    readonly property int islandRadius: barHeight / 2
    readonly property int pillRadius: contentHeight / 2
    readonly property int popoutRadius: 14

    readonly property int popoutWidth: 190
    readonly property int menuWidth: 200
    readonly property int listWidth: 250

    readonly property int launcherWidth: 640
    readonly property int launcherPadding: 12
    readonly property int launcherRadius: 18
    readonly property int launcherFieldHeight: 44
    readonly property int launcherFieldRadius: 12
    readonly property int launcherRows: 8
    readonly property int launcherRowHeight: 48
    readonly property int launcherRowRadius: 10
    readonly property int launcherIconSize: 30
    readonly property int launcherPreviewWidth: 320
    readonly property int launcherPreviewIconSize: 72
    readonly property int launcherSectionHeight: 26
    readonly property int launcherChipHeight: 24
    readonly property int launcherHintHeight: 18
    readonly property int launcherTileSize: 96
    readonly property int launcherTileIconSize: 44
    readonly property int launcherStagger: 18 // ms per row on open

    // ── type ───────────────────────────────────────────────────────────
    readonly property string font: pal.fontMono ?? "JetBrainsMono Nerd Font"
    readonly property string fontSans: pal.fontSans ?? "Geist"
    readonly property int fontSize: 10
    readonly property int fontSizeLarge: 13
    readonly property int fontSizeSmall: 9
    readonly property int fontSizeInput: 15
    readonly property int fontSizeHeading: 18
    readonly property int fontSizeDisplay: 30

    // ── motion ─────────────────────────────────────────────────────────
    readonly property int durFast: 120
    readonly property int durBase: 200
    readonly property int durSlow: 350
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutBack

    // Returns exact palette colors only, never a blend.
    function severity(value: real, warnAt: real, critAt: real): color {
        if (value >= critAt)
            return root.urgent;
        if (value >= warnAt)
            return root.warn;
        return root.fg;
    }
}
