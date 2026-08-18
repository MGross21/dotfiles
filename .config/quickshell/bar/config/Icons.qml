pragma Singleton

import QtQuick
import Quickshell

// Freedesktop icon names, resolved against the theme set by the
// `//@ pragma IconTheme` line in shell.qml.
//
// Adwaita is used rather than Papirus because Papirus ships no `*-symbolic`
// variants at all -- the entire status set would fall back to missing-texture.
// Verified present in adwaita-icon-theme 50: battery-level-N[-charging],
// audio-volume-{high,medium,low,muted}, system-{lock-screen,reboot,shutdown}.
Singleton {
    id: root

    function volume(vol: real, muted: bool): string {
        if (muted)
            return Quickshell.iconPath("audio-volume-muted-symbolic");
        const name = vol > 0.66 ? "audio-volume-high-symbolic" : vol > 0.33 ? "audio-volume-medium-symbolic" : vol > 0.0 ? "audio-volume-low-symbolic" : "audio-volume-muted-symbolic";
        return Quickshell.iconPath(name);
    }

    // Adwaita buckets battery levels in tens. The charging ramp stops at 90 --
    // at full it switches to `-charged`, so 100 needs a special case or it
    // resolves to nothing.
    function battery(pct: int, charging: bool): string {
        const level = Math.max(0, Math.min(100, Math.round(pct / 10) * 10));
        const suffix = !charging ? "" : level >= 100 ? "-charged" : "-charging";
        return Quickshell.iconPath(`battery-level-${level}${suffix}-symbolic`, "battery-missing-symbolic");
    }

    // Adwaita's wifi ramp is named by quality band, not by number.
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

    function app(appId: string): string {
        if (!appId)
            return "";
        // Desktop files are usually lowercase reverse-DNS or plain lowercase;
        // fall back to the generic executable glyph rather than a broken image.
        return Quickshell.iconPath(appId.toLowerCase(), "application-x-executable-symbolic");
    }

    readonly property string lock: Quickshell.iconPath("system-lock-screen-symbolic")
    readonly property string suspend: Quickshell.iconPath("weather-clear-night-symbolic")
    readonly property string reboot: Quickshell.iconPath("system-reboot-symbolic")
    readonly property string shutdown: Quickshell.iconPath("system-shutdown-symbolic")
    readonly property string calendar: Quickshell.iconPath("x-office-calendar-symbolic")
    readonly property string chevron: Quickshell.iconPath("pan-down-symbolic")
}
