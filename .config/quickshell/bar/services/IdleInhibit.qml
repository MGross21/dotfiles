pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false

    IpcHandler {
        target: "caffeine"

        function toggle(): void {
            root.enabled = !root.enabled;
        }
    }

    Process {
        running: root.enabled
        command: ["systemd-inhibit", "--what=idle", "--who=Caffeine", "--why=Kept awake from the bar", "sleep", "infinity"]
    }
}
