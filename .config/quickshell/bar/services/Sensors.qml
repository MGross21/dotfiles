pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// cpu / memory / temperature have no built-in quickshell service, so they come
// straight off procfs and sysfs. Polled on a timer -- procfs does not emit
// inotify events, so FileView.watchChanges is useless here.
Singleton {
    id: root

    readonly property int interval: 3000

    // ── cpu ────────────────────────────────────────────────────────────
    property int cpuUsage: 0
    property real _prevIdle: 0
    property real _prevTotal: 0

    // ── memory ─────────────────────────────────────────────────────────
    property int memUsage: 0
    property real memUsedGb: 0
    property real memTotalGb: 0

    // ── temperature ────────────────────────────────────────────────────
    property int tempC: 0

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
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

            if (root._prevTotal > 0 && dTotal > 0)
                root.cpuUsage = Math.round((1 - dIdle / dTotal) * 100);

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
        }
    }

    // hwmon and thermal_zone indices reshuffle across boots, so resolve the
    // package-temp zone by its type name once at startup instead of hardcoding
    // thermal_zone2.
    Process {
        running: true
        command: ["sh", "-c", `for z in /sys/class/thermal/thermal_zone*; do
              case "$(cat "$z/type" 2>/dev/null)" in
                x86_pkg_temp|k10temp|acpitz) echo "$z/temp"; exit 0 ;;
              esac
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "")
                    thermal.path = p;
            }
        }
    }

    FileView {
        id: thermal
        path: ""
        onLoaded: root.tempC = Math.round(Number(text().trim()) / 1000)
    }
}
