pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Sampled only while a detail panel is open; procfs and sysfs emit no inotify events.
Singleton {
    id: root

    readonly property int interval: 1000
    readonly property int historyLength: 60
    readonly property string dgpu: Quickshell.env("DOTFILES_SYSMON_DGPU") ?? ""

    property int viewers: 0

    property int cpu: 0
    property var cores: []
    property var cpuHistory: []
    property string loadAvg: ""
    property var _prevCpu: []

    property int mem: 0
    property real memUsedGib: 0
    property real memTotalGib: 0
    property real swapUsedGib: 0
    property var memHistory: []

    property int temp: 0
    property var tempHistory: []

    property bool gpuAwake: false
    property int gpu: 0
    property int gpuTemp: 0
    property real vramUsedGib: 0
    property real vramTotalGib: 0
    property real gpuWatts: NaN
    property var gpuHistory: []

    function _push(history: var, value: real): var {
        const next = history.concat([value]);
        return next.length > root.historyLength ? next.slice(next.length - root.historyLength) : next;
    }

    Timer {
        interval: root.interval
        running: root.viewers > 0
        repeat: true
        triggeredOnStart: true
        onRunningChanged: if (running) {
            root._prevCpu = [];
            root.cpuHistory = [];
            root.memHistory = [];
            root.tempHistory = [];
            root.gpuHistory = [];
        }
        onTriggered: {
            stat.reload();
            meminfo.reload();
            loadavg.reload();
            if (thermal.path !== "")
                thermal.reload();
            if (root.dgpu !== "")
                pmStatus.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const prev = root._prevCpu;
            const next = [];
            const usage = [];
            for (const line of text().split("\n")) {
                if (!line.startsWith("cpu"))
                    break;
                // user nice system idle iowait irq softirq steal; guest is already inside user.
                const f = line.split(/\s+/).slice(1, 9).map(Number);
                const idle = f[3] + f[4];
                const total = f.reduce((a, b) => a + b, 0);
                const p = prev[next.length];
                usage.push(p && total > p.total ? Math.round(100 * (1 - (idle - p.idle) / (total - p.total))) : 0);
                next.push({
                    idle,
                    total
                });
            }
            root._prevCpu = next;
            if (prev.length === 0)
                return;
            root.cpu = usage[0];
            root.cores = usage.slice(1);
            root.cpuHistory = root._push(root.cpuHistory, root.cpu);
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
            root.memTotalGib = kb.MemTotal / 1048576;
            root.memUsedGib = used / 1048576;
            root.swapUsedGib = (kb.SwapTotal - kb.SwapFree) / 1048576;
            root.mem = Math.round(100 * used / kb.MemTotal);
            root.memHistory = root._push(root.memHistory, root.mem);
        }
    }

    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: root.loadAvg = text().split(" ").slice(0, 3).join("  ")
    }

    // hwmon indices reshuffle across boots.
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name) in coretemp|k10temp|zenpower) echo $h/temp1_input; exit;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: thermal.path = text.trim()
        }
    }

    FileView {
        id: thermal
        path: ""
        onLoaded: {
            root.temp = Math.round(Number(text().trim()) / 1000);
            root.tempHistory = root._push(root.tempHistory, root.temp);
        }
    }

    FileView {
        id: pmStatus
        path: root.dgpu === "" ? "" : root.dgpu + "/power/runtime_status"
        onLoaded: {
            root.gpuAwake = text().trim() === "active";
            if (root.gpuAwake && !nvidia.running)
                nvidia.running = true;
        }
    }

    Process {
        id: nvidia
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.split("\n")[0].split(",").map(s => Number(s.trim()));
                if (f.length < 4 || isNaN(f[0]))
                    return;
                root.gpu = f[0];
                root.gpuTemp = f[1];
                root.vramUsedGib = f[2] / 1024;
                root.vramTotalGib = f[3] / 1024;
                root.gpuWatts = f[4];
                root.gpuHistory = root._push(root.gpuHistory, root.gpu);
            }
        }
    }
}
