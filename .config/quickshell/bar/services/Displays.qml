pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Mirrored outputs drop out of Quickshell.screens and Hyprland.monitors, so state comes from `monitors all`.
Singleton {
    id: root

    property int count: 1
    property bool mirrored: false

    function toggle(): void {
        Quickshell.execDetached(["display-mode", "toggle"]);
    }

    function arrange(): void {
        Quickshell.execDetached(["uwsm", "app", "--", "wdisplays"]);
    }

    Connections {
        target: Quickshell
        function onScreensChanged(): void {
            poll.running = true;
        }
    }

    Process {
        id: poll
        running: true
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            onStreamFinished: {
                const mons = JSON.parse(text).filter(m => !m.disabled);
                root.count = mons.length;
                root.mirrored = mons.some(m => m.mirrorOf !== "none");
            }
        }
    }
}
