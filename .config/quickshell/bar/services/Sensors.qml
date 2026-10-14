pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Polled: procfs emits no inotify events, so watchChanges never fires.
Singleton {
    id: root

    readonly property int interval: 3000
    readonly property int historyLength: 40

    // ── cpu ────────────────────────────────────────────────────────────
    property int cpuUsage: 0
    property real _prevIdle: 0
    property real _prevTotal: 0
    property var cpuHistory: []
    property string loadAvg: ""

    // ── memory ─────────────────────────────────────────────────────────
    property int memUsage: 0
    property real memUsedGb: 0
    property real memTotalGb: 0
    property var memHistory: []

    // ── temperature ────────────────────────────────────────────────────
    property int tempC: 0
    property string tempSensor: ""
    property var tempHistory: []

    function _push(history: var, value: real): var {
        const next = history.concat([value]);
        return next.length > root.historyLength ? next.slice(next.length - root.historyLength) : next;
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            loadavg.reload();
            if (thermal.path !== "")
                thermal.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            // "cpu  user nice system idle iowait irq softirq steal ..."
            const fields = text().split("\n")[0].split(/\s+/).slice(1).map(Number);
            if (fields.length < 5)
                return;

            const idle = fields[3] + fields[4];
            const total = fields.reduce((a, b) => a + b, 0);
            const dIdle = idle - root._prevIdle;
            const dTotal = total - root._prevTotal;

            if (root._prevTotal > 0 && dTotal > 0) {
                root.cpuUsage = Math.round((1 - dIdle / dTotal) * 100);
                root.cpuHistory = root._push(root.cpuHistory, root.cpuUsage);
            }

            root._prevIdle = idle;
            root._prevTotal = total;
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kb = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+) kB/);
                if (m)
                    kb[m[1]] = Number(m[2]);
            }
            if (!kb.MemTotal)
                return;

            const used = kb.MemTotal - kb.MemAvailable;
            root.memTotalGb = kb.MemTotal / 1048576;
            root.memUsedGb = used / 1048576;
            root.memUsage = Math.round((used / kb.MemTotal) * 100);
            root.memHistory = root._push(root.memHistory, root.memUsage);
        }
    }

    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: root.loadAvg = text().split(" ").slice(0, 3).join("  ")
    }

    // Zone indices reshuffle across boots; the first type in this order wins.
    Process {
        running: true
        command: ["sh", "-c", `for t in x86_pkg_temp k10temp acpitz; do
              for z in /sys/class/thermal/thermal_zone*; do
                [ "$(cat "$z/type" 2>/dev/null)" = "$t" ] && { echo "$z/temp $t"; exit 0; }
              done
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const [p, type] = text.trim().split(" ");
                if (!p)
                    return;
                root.tempSensor = ({
                        x86_pkg_temp: "CPU package",
                        k10temp: "CPU (k10temp)",
                        acpitz: "ACPI thermal zone"
                    })[type] ?? type ?? "";
                thermal.path = p;
            }
        }
    }

    FileView {
        id: thermal
        path: ""
        onLoaded: {
            root.tempC = Math.round(Number(text().trim()) / 1000);
            root.tempHistory = root._push(root.tempHistory, root.tempC);
        }
    }
}
