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
    readonly property string calendar: Quickshell.iconPath("x-office-calendar-symbolic")
    readonly property string chevron: Quickshell.iconPath("pan-down-symbolic")
}
