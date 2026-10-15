import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"

Provider {
    id: root

    // { name, hostname }[] from ~/.ssh/config, wildcard patterns skipped.
    property var hosts: []

    function parse(text: string): var {
        const out = [];
        let current = [];
        for (const raw of text.split("\n")) {
            const [key, ...args] = raw.trim().split(/\s+/);
            const k = (key ?? "").toLowerCase();
            if (k === "host") {
                current = args.filter(a => !/[*?!]/.test(a)).map(name => ({
                            name,
                            hostname: ""
                        }));
                out.push(...current);
            } else if (k === "match") {
                current = [];
            } else if (k === "hostname") {
                for (const h of current)
                    h.hostname = args[0] ?? "";
            }
        }
        return out;
    }

    prefix: "ssh "
    name: "SSH"
    icon: Icons.server
    placeholder: "Connect to a host from ~/.ssh/config"
    enterHint: "connect"
    items: {
        if (!root.active)
            return [];
        const terms = Fuzzy.terms(root.text);
        const out = [];
        for (const h of root.hosts) {
            const r = Fuzzy.matchAll(terms, h.name);
            if (r)
                out.push({
                    key: `ssh:${h.name}`,
                    title: h.name,
                    subtitle: h.hostname,
                    icon: Icons.server,
                    positions: r.positions,
                    score: r.score,
                    preview: {
                        kind: "generic",
                        icon: Icons.server,
                        title: h.name,
                        detail: `ssh ${h.name}`
                    },
                    run: () => Quickshell.execDetached(["uwsm", "app", "--", "ghostty", "-e", "ssh", h.name])
                });
        }
        return out.sort((a, b) => b.score - a.score);
    }

    property FileView config: FileView {
        id: config

        path: root.active ? `${Quickshell.env("HOME")}/.ssh/config` : ""
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.hosts = root.parse(config.text())
    }
}
