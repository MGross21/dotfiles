pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Quickshell 0.3.0 ships no network service, so state comes from nmcli.
// One process per poll emitting a small tagged blob, rather than four separate
// invocations -- this runs every few seconds for the life of the session.
Singleton {
    id: root

    readonly property int interval: 5000

    property bool wifiEnabled: true
    property string kind: "none"        // "wifi" | "ethernet" | "none"
    property string ssid: ""
    property int strength: 0
    property string ipAddress: ""
    property bool connected: kind !== "none"
    property bool scanning: false

    // [{ ssid, signal, security, active, saved }]
    property var networks: []

    readonly property string icon: kind === "ethernet" ? Icons.wired : Icons.wifi(strength, wifiEnabled, kind === "wifi")

    readonly property string label: kind === "ethernet" ? "Wired" : kind === "wifi" ? ssid : wifiEnabled ? "Offline" : "Wi-Fi off"

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    Process {
        id: poll
        command: ["sh", "-c", `
            printf 'RADIO\\t%s\\n' "$(nmcli -t radio wifi 2>/dev/null)"
            nmcli -t -f TYPE,STATE,CONNECTION,DEVICE device 2>/dev/null \\
              | awk -F: '$2=="connected" && ($1=="wifi"||$1=="ethernet") {print "DEV\\t"$1"\\t"$3"\\t"$4}'
            nmcli -t -f NAME connection show 2>/dev/null | sed 's/^/SAVED\\t/'
            nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null \\
              | awk -F: 'length($2)>0 {print "NET\\t"$1"\\t"$2"\\t"$3"\\t"$4}'
        `]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    Process {
        id: action
        onExited: poll.running = true
    }

    function _run(args: list<string>): void {
        action.command = args;
        action.running = true;
    }

    function _parse(out: string): void {
        const saved = {};
        const nets = [];
        let dev = "";
        let kind = "none";
        let ssid = "";

        for (const line of out.split("\n")) {
            const f = line.split("\t");
            switch (f[0]) {
            case "RADIO":
                root.wifiEnabled = f[1] === "enabled";
                break;
            case "DEV":
                // First connected device wins; ethernet outranks wifi.
                if (kind === "none" || f[1] === "ethernet") {
                    kind = f[1];
                    ssid = f[2] ?? "";
                    dev = f[3] ?? "";
                }
                break;
            case "SAVED":
                saved[f[1]] = true;
                break;
            case "NET":
                // The IN-USE column is not marked in nmcli's terse output on
                // every version, so the active AP is matched by SSID below
                // rather than trusted from f[1].
                nets.push({
                    active: false,
                    ssid: f[2],
                    signal: Number(f[3]) || 0,
                    security: f[4] ?? "",
                    saved: false
                });
                break;
            }
        }

        let best = 0;
        for (const n of nets) {
            n.saved = saved[n.ssid] === true;
            n.active = kind === "wifi" && n.ssid === ssid;
            // A mesh SSID appears once per AP; the radio is associated with the
            // strongest, so take the max rather than whichever row came last.
            if (n.active)
                best = Math.max(best, n.signal);
        }
        root.strength = best;

        // Strongest first, de-duplicated by SSID (one row per network, not per AP).
        const seen = {};
        root.networks = nets.sort((a, b) => b.signal - a.signal).filter(n => {
            if (seen[n.ssid])
                return false;
            seen[n.ssid] = true;
            return true;
        });

        root.kind = kind;
        root.ssid = ssid;
        if (kind === "none")
            root.strength = 0;

        if (dev !== "")
            ipProc.command = ["sh", "-c", `nmcli -t -f IP4.ADDRESS device show ${dev} 2>/dev/null | head -1 | cut -d: -f2`];
        else
            root.ipAddress = "";
        if (dev !== "")
            ipProc.running = true;

        root.scanning = false;
    }

    Process {
        id: ipProc
        stdout: StdioCollector {
            onStreamFinished: root.ipAddress = text.trim()
        }
    }

    function toggleWifi(): void {
        root._run(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]);
    }

    function rescan(): void {
        root.scanning = true;
        root._run(["nmcli", "device", "wifi", "rescan"]);
    }

    function connect(ssid: string, password: string): void {
        if (password)
            root._run(["nmcli", "device", "wifi", "connect", ssid, "password", password]);
        else
            root._run(["nmcli", "connection", "up", "id", ssid]);
    }

    function disconnect(ssid: string): void {
        root._run(["nmcli", "connection", "down", "id", ssid]);
    }
}
