pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    readonly property real halfLifeDays: 14
    readonly property var all: DesktopEntries.applications.values.filter(app => !app.noDisplay)
    readonly property var apps: root.all.filter(app => !root.isHidden(app))
    readonly property var hiddenApps: root.all.filter(app => root.isHidden(app))
    readonly property var meta: {
        const out = {};
        for (const app of root.all)
            out[app.id] = [app.genericName, app.comment, ...app.keywords, ...app.categories].join(" ").toLowerCase();
        return out;
    }

    // Lowercased app id or WM class -> HyprlandToplevel[].
    readonly property var windows: {
        const out = {};
        for (const t of Hyprland.toplevels.values) {
            const id = (t.wayland?.appId || t.lastIpcObject?.class || "").toLowerCase();
            if (id)
                out[id] = [...(out[id] ?? []), t];
        }
        return out;
    }

    readonly property var pinned: store.pinned

    // Returns { app, score, positions }[] best-first; every term must match.
    function query(text: string, pool: var): var {
        const terms = Fuzzy.terms(text);
        const out = [];
        for (const app of pool) {
            const r = root._score(app, terms);
            if (r)
                out.push(r);
        }
        return out.sort((a, b) => b.score - a.score || a.app.name.localeCompare(b.app.name));
    }

    function frecency(app: DesktopEntry): real {
        const u = store.usage[app.id];
        if (!u)
            return 0;
        const days = (Date.now() - u.last) / 86400000;
        return u.score * Math.pow(0.5, days / root.halfLifeDays);
    }

    function recent(count: int): var {
        return root.apps.map(app => ({
                    app,
                    f: root.frecency(app)
                })).filter(r => r.f > 0).sort((a, b) => b.f - a.f).slice(0, count).map(r => r.app);
    }

    function windowsOf(app: DesktopEntry): var {
        for (const key of [app.startupClass, app.id, app.id.split(".").pop()]) {
            const hit = key && root.windows[key.toLowerCase()];
            if (hit)
                return hit;
        }
        return [];
    }

    function launch(app: DesktopEntry, emptyWorkspace: bool): void {
        root._record(app);
        const argv = ["uwsm", "app", "--", `${app.id}.desktop`];
        if (emptyWorkspace)
            root.dispatch(`hl.dsp.exec_cmd(${JSON.stringify(argv.join(" "))}, { workspace = "empty" })`);
        else
            Quickshell.execDetached(argv);
    }

    function launchAction(app: DesktopEntry, action: DesktopAction): void {
        root._record(app);
        Quickshell.execDetached(["uwsm", "app", "--", ...action.command]);
    }

    function dispatch(expr: string): void {
        Quickshell.execDetached(["hyprctl", "dispatch", expr]);
    }

    function focus(toplevel: HyprlandToplevel): void {
        root.dispatch(`hl.dsp.focus({ window = "address:0x${toplevel.address}" })`);
    }

    function isPinned(app: DesktopEntry): bool {
        return store.pinned.includes(app.id);
    }

    function isHidden(app: DesktopEntry): bool {
        return store.hidden.includes(app.id);
    }

    function togglePin(app: DesktopEntry): void {
        store.pinned = root.isPinned(app) ? store.pinned.filter(id => id !== app.id) : [...store.pinned, app.id];
    }

    function toggleHidden(app: DesktopEntry): void {
        store.hidden = root.isHidden(app) ? store.hidden.filter(id => id !== app.id) : [...store.hidden, app.id];
    }

    function _record(app: DesktopEntry): void {
        store.usage = Object.assign({}, store.usage, {
            [app.id]: {
                score: root.frecency(app) + 1,
                last: Date.now()
            }
        });
    }

    function _score(app: DesktopEntry, terms: var): var {
        const boost = Math.log1p(root.frecency(app)) * 6;
        if (terms.length === 0)
            return {
                app,
                score: boost,
                positions: []
            };

        let score = boost;
        let positions = [];
        for (const term of terms) {
            const r = Fuzzy.match(term, app.name);
            if (r) {
                score += r.score;
                positions = positions.concat(r.positions);
            } else if (root.meta[app.id]?.includes(term)) {
                score += term.length * 4;
            } else {
                return null;
            }
        }
        return {
            app,
            score,
            positions
        };
    }

    FileView {
        path: Quickshell.statePath("launcher.json")
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            const legacy = Object.entries(store.counts);
            if (legacy.length === 0)
                return;
            const usage = Object.assign({}, store.usage);
            for (const [id, count] of legacy) {
                if (!usage[id])
                    usage[id] = {
                        score: count,
                        last: Date.now()
                    };
            }
            store.usage = usage;
            store.counts = {};
        }

        JsonAdapter {
            id: store

            property var usage: ({})
            property var pinned: []
            property var hidden: []
            // Pre-frecency launch counts, migrated into `usage` on load.
            property var counts: ({})
        }
    }
}
