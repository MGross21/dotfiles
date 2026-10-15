import QtQuick
import Quickshell
import "../../config"
import "../../services"

// Declared in Nix (desktop.bar.launcher.providers): static `entries`, and/or a `list` command printing `title[\tsubtitle[\tvalue]]` lines.
Provider {
    id: root

    required property var spec
    property var listed: []
    readonly property var entries: (root.spec.entries ?? []).map(e => ({
                title: e.title,
                subtitle: e.subtitle ?? "",
                value: e.value ?? e.title
            })).concat(root.listed)

    function argv(value: string): var {
        return root.spec.exec.map(a => a.split("{}").join(value));
    }

    function entryItem(e: var, positions: var): var {
        return {
            key: `script:${root.spec.prefix}:${e.value}`,
            title: e.title,
            subtitle: e.subtitle,
            icon: root.icon,
            positions,
            preview: {
                kind: "generic",
                icon: root.icon,
                title: e.title,
                detail: root.argv(e.value).join(" ")
            },
            run: () => Quickshell.execDetached(["uwsm", "app", "--", ...root.argv(e.value)])
        };
    }

    onActiveChanged: {
        if (root.active && root.spec.list?.length)
            job.start(root.spec.list);
    }

    prefix: root.spec.prefix
    name: root.spec.name
    icon: Icons.named(root.spec.icon)
    placeholder: root.spec.placeholder || `Search ${root.spec.name}`
    enterHint: "run"
    busy: job.running
    items: {
        if (!root.active)
            return [];
        const terms = Fuzzy.terms(root.text);
        const out = [];
        for (const e of root.entries) {
            const r = Fuzzy.matchAll(terms, e.title);
            if (r)
                out.push({
                    e,
                    r
                });
        }
        return out.sort((a, b) => b.r.score - a.r.score).map(x => root.entryItem(x.e, x.r.positions));
    }

    property Job job: Job {
        id: job

        onDone: out => root.listed = out.split("\n").filter(l => l.trim() !== "").map(l => {
                const [title, subtitle, value] = l.split("\t");
                return {
                    title,
                    subtitle: subtitle ?? "",
                    value: value ?? title
                };
            })
    }
}
