import QtQuick
import Quickshell.Widgets
import "../components"
import "../config"

// Theme names resolve as app icons; resolved paths pass through; `-symbolic` ones get recolored.
Item {
    id: root

    property var item
    property int size: Theme.launcherIconSize
    property color color: Theme.fg
    readonly property string glyph: root.item?.glyph ?? ""
    readonly property string source: {
        const icon = root.item?.icon ?? "";
        if (icon === "")
            return "";
        return icon.includes(":") || icon.startsWith("/") ? icon : Icons.desktopEntry(icon);
    }
    readonly property bool symbolic: root.source.includes("-symbolic")

    implicitWidth: root.size
    implicitHeight: root.size

    Text {
        anchors.centerIn: parent
        visible: root.glyph !== ""
        text: root.glyph
        color: root.color
        font.family: Theme.font
        font.pixelSize: Math.round(root.size * 0.8)
    }

    IconImage {
        anchors.fill: parent
        visible: root.glyph === "" && !root.symbolic
        source: root.source
        implicitSize: root.size
        asynchronous: true
    }

    Icon {
        anchors.centerIn: parent
        visible: root.glyph === "" && root.symbolic
        source: root.source
        size: Math.round(root.size * 0.66)
        color: root.color
    }
}
