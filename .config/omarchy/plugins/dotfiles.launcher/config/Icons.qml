pragma Singleton

import QtQuick
import Quickshell

// Freedesktop names, resolved against the IconTheme pragma in shell.qml.
Singleton {
    id: root

    readonly property string refresh: Quickshell.iconPath("view-refresh-symbolic")
    readonly property string search: Quickshell.iconPath("system-search-symbolic")
    readonly property string grid: Quickshell.iconPath("view-app-grid-symbolic")
    readonly property string windows: Quickshell.iconPath("focus-windows-symbolic")
    readonly property string windowNew: Quickshell.iconPath("window-new-symbolic")
    readonly property string close: Quickshell.iconPath("window-close-symbolic")
    readonly property string star: Quickshell.iconPath("starred-symbolic")
    readonly property string hide: Quickshell.iconPath("view-conceal-symbolic")
    readonly property string terminal: Quickshell.iconPath("utilities-terminal-symbolic")
    readonly property string calculator: Quickshell.iconPath("accessories-calculator-symbolic")
    readonly property string emoji: Quickshell.iconPath("face-smile-symbolic")
    readonly property string paste: Quickshell.iconPath("edit-paste-symbolic")
    readonly property string web: Quickshell.iconPath("web-browser-symbolic")
    readonly property string ask: Quickshell.iconPath("chat-message-new-symbolic")
    readonly property string logout: Quickshell.iconPath("system-log-out-symbolic")
    readonly property string next: Quickshell.iconPath("go-next-symbolic")
    readonly property string server: Quickshell.iconPath("network-server-symbolic")

    function named(name: string): string {
        return Quickshell.iconPath(name, "application-x-executable-symbolic");
    }

    function fileKind(kind: string): string {
        const names = {
            folder: "folder",
            image: "image-x-generic",
            video: "video-x-generic",
            audio: "audio-x-generic",
            script: "text-x-script",
            archive: "package-x-generic",
            pdf: "x-office-document"
        };
        return Quickshell.iconPath(names[kind] ?? "text-x-generic");
    }

    function app(appId: string): string {
        if (!appId)
            return "";
        return Quickshell.iconPath(appId.toLowerCase(), "application-x-executable-symbolic");
    }

    function desktopEntry(icon: string): string {
        return Quickshell.iconPath(icon, "application-x-executable");
    }

    readonly property string lock: Quickshell.iconPath("system-lock-screen-symbolic")
    readonly property string caffeine: Quickshell.iconPath("display-brightness-symbolic")
    readonly property string suspend: Quickshell.iconPath("weather-clear-night-symbolic")
    readonly property string reboot: Quickshell.iconPath("system-reboot-symbolic")
    readonly property string shutdown: Quickshell.iconPath("system-shutdown-symbolic")
}
