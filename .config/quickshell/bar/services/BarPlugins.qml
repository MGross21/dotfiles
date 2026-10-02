pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []

    FileView {
        path: Quickshell.shellPath("plugins/layout.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.entries = JSON.parse(text())
    }
}
