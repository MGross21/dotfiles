pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false

    Process {
        running: root.enabled
        command: ["systemd-inhibit", "--what=idle", "--who=Caffeine", "--why=Kept awake from the launcher", "sleep", "infinity"]
    }
}
