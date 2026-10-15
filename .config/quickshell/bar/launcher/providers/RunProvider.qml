import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"

Provider {
    id: root

    readonly property int historySize: 100

    function execute(command: string, inTerminal: bool): void {
        store.history = [command, ...store.history.filter(c => c !== command)].slice(0, root.historySize);
        if (inTerminal)
            root.terminal(Quickshell.env("HOME"), command);
        else
            Quickshell.execDetached(["uwsm", "app", "--", "sh", "-c", command]);
    }

    function commandItem(command: string, positions: var, section: string): var {
        return {
            key: `run:${section}:${command}`,
            title: command,
            subtitle: section === "" ? "Run command" : "",
            icon: Icons.terminal,
            positions,
            section,
            preview: {
                kind: "text",
                text: command,
                mono: true
            },
            actions: [
                {
                    key: "run",
                    title: "Run",
                    icon: Icons.terminal,
                    run: () => root.execute(command, false)
                },
                {
                    key: "terminal",
                    title: "Run in terminal",
                    icon: Icons.terminal,
                    run: () => root.execute(command, true)
                },
                {
                    key: "forget",
                    title: "Remove from history",
                    icon: Icons.close,
                    run: () => {
                        store.history = store.history.filter(c => c !== command);
                        return true;
                    }
                }
            ],
            run: mode => root.execute(command, mode === "alt")
        };
    }

    prefix: ">"
    name: "Run"
    icon: Icons.terminal
    placeholder: "Run a shell command"
    enterHint: "run"
    altHint: "run in terminal"
    items: {
        if (!root.active)
            return [];
        const command = root.text.trim();
        const terms = Fuzzy.terms(command);
        const past = [];
        for (const c of store.history) {
            if (c === command)
                continue;
            const r = Fuzzy.matchAll(terms, c);
            if (r)
                past.push(root.commandItem(c, r.positions, "History"));
        }
        return command === "" ? past : [root.commandItem(command, [], ""), ...past];
    }

    property FileView file: FileView {
        path: Quickshell.statePath("launcher-run.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: store

            property var history: []
        }
    }
}
