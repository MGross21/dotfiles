pragma Singleton

import QtQuick
import Quickshell

// Freedesktop names, resolved against the IconTheme pragma in shell.qml.
Singleton {
    id: root

    function volume(vol: real, muted: bool): string {
        if (muted)
            return Quickshell.iconPath("audio-volume-muted-symbolic");
        const name = vol > 0.66 ? "audio-volume-high-symbolic" : vol > 0.33 ? "audio-volume-medium-symbolic" : vol > 0.0 ? "audio-volume-low-symbolic" : "audio-volume-muted-symbolic";
        return Quickshell.iconPath(name);
    }

    // The charging ramp stops at 90; full is `-charged`.
    function battery(pct: int, charging: bool): string {
        const level = Math.max(0, Math.min(100, Math.round(pct / 10) * 10));
        const suffix = !charging ? "" : level >= 100 ? "-charged" : "-charging";
        return Quickshell.iconPath(`battery-level-${level}${suffix}-symbolic`, "battery-missing-symbolic");
    }

    function wifi(strength: int, enabled: bool, connected: bool): string {
        if (!enabled)
            return Quickshell.iconPath("network-wireless-disabled-symbolic", "network-offline-symbolic");
        if (!connected)
            return Quickshell.iconPath("network-wireless-signal-none-symbolic");
        const band = strength >= 80 ? "excellent" : strength >= 55 ? "good" : strength >= 30 ? "ok" : strength > 0 ? "weak" : "none";
        return Quickshell.iconPath(`network-wireless-signal-${band}-symbolic`);
    }

    readonly property string wired: Quickshell.iconPath("network-wired-symbolic")
    readonly property string offline: Quickshell.iconPath("network-offline-symbolic")
    readonly property string vpn: Quickshell.iconPath("network-vpn-symbolic")
    readonly property string locked: Quickshell.iconPath("changes-prevent-symbolic")
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
    readonly property string share: Quickshell.iconPath("send-to-symbolic")
    readonly property string camera: Quickshell.iconPath("camera-photo-symbolic")

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
    readonly property string displayExtend: Quickshell.iconPath("video-joined-displays-symbolic")
    readonly property string displayMirror: Quickshell.iconPath("display-projector-symbolic")
    readonly property string suspend: Quickshell.iconPath("weather-clear-night-symbolic")
    readonly property string reboot: Quickshell.iconPath("system-reboot-symbolic")
    readonly property string shutdown: Quickshell.iconPath("system-shutdown-symbolic")
    readonly property string calendar: Quickshell.iconPath("x-office-calendar-symbolic")
    readonly property string chevron: Quickshell.iconPath("pan-down-symbolic")
}
