import QtQuick
import Quickshell.Io

// Restartable process; `done` fires only for the latest start().
Process {
    id: root

    property var pending: null
    property int generation: 0
    property int runGeneration: 0

    signal done(string out)

    function start(argv: var): void {
        root.generation++;
        root.pending = argv;
        if (root.running)
            root.running = false;
        else
            root._launch();
    }

    function stop(): void {
        root.generation++;
        root.pending = null;
        root.running = false;
    }

    function _launch(): void {
        if (!root.pending)
            return;
        root.command = root.pending;
        root.runGeneration = root.generation;
        root.pending = null;
        root.running = true;
    }

    onExited: root._launch()

    stdout: StdioCollector {
        id: collector

        onStreamFinished: {
            if (root.runGeneration === root.generation && root.pending === null)
                root.done(collector.text);
        }
    }
}
