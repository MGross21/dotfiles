import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../components"
import "../config"

// Shows the application's name, not its window title. Titles carry document
// and project metadata -- "file.ts — project — Visual Studio Code" — which is
// noise in a bar. The desktop entry knows the short name: "Visual Studio Code".
Row {
    id: root

    readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel
    // HyprlandToplevel exposes no class of its own; the wayland handle carries
    // appId, and the raw IPC object has `class` as a fallback.
    readonly property string appId: toplevel ? (toplevel.wayland?.appId ?? toplevel.lastIpcObject?.class ?? "") : ""

    // Binding (not an imperative lookup) so DesktopEntries initializes -- the
    // service stays empty until something binds to it.
    readonly property var entry: appId === "" ? null : DesktopEntries.byId(appId)

    readonly property string appName: {
        if (appId === "")
            return "";
        if (entry?.name)
            return entry.name;
        // No desktop entry: strip any trailing " — App Name" segment the title
        // carries, then fall back to the appId with its first letter raised.
        return appId.charAt(0).toUpperCase() + appId.slice(1);
    }

    spacing: 6
    opacity: appId === "" ? 0 : 1

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durBase
        }
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        source: root.entry?.icon ? Quickshell.iconPath(root.entry.icon, "application-x-executable-symbolic") : Icons.app(root.appId)
        size: 13
        recolor: false
        visible: root.appId !== ""
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.appName
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        elide: Text.ElideRight
        maximumLineCount: 1
        width: Math.min(implicitWidth, 180)

        Behavior on width {
            NumberAnimation {
                duration: Theme.durBase
                easing.type: Theme.easeStandard
            }
        }
    }
}
