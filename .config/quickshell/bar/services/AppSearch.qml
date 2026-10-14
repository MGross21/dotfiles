pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var apps: DesktopEntries.applications.values.filter(app => !app.noDisplay)

    // Returns entries best-first; every whitespace-separated term must match.
    function query(text: string): var {
        const terms = text.toLowerCase().split(/\s+/).filter(t => t !== "");
        return root.apps.map(app => ({
                    app,
                    score: root._score(app, terms)
                })).filter(r => r.score > 0).sort((a, b) => b.score - a.score || a.app.name.localeCompare(b.app.name)).map(r => r.app);
    }

    function launch(app: DesktopEntry): void {
        store.counts = Object.assign({}, store.counts, {
            [app.id]: (store.counts[app.id] ?? 0) + 1
        });
        Quickshell.execDetached(["uwsm", "app", "--", `${app.id}.desktop`]);
    }

    function _score(app: DesktopEntry, terms: var): real {
        const usage = Math.log1p(store.counts[app.id] ?? 0) * 4;
        if (terms.length === 0)
            return 1 + usage;

        const name = app.name.toLowerCase();
        const words = name.split(/[\s\-_.]+/);
        const meta = [app.genericName, app.comment, ...app.keywords, ...app.categories].join(" ").toLowerCase();

        let total = 0;
        for (const term of terms) {
            const s = name.startsWith(term) ? 100 : words.some(w => w.startsWith(term)) ? 80 : name.includes(term) ? 60 : meta.includes(term) ? 30 : root._isSubsequence(term, name) ? 15 : 0;
            if (s === 0)
                return 0;
            total += s;
        }
        return total + usage;
    }

    function _isSubsequence(needle: string, hay: string): bool {
        let i = 0;
        for (const ch of hay) {
            if (ch === needle[i] && ++i === needle.length)
                return true;
        }
        return false;
    }

    FileView {
        path: Quickshell.statePath("launcher.json")
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: store

            property var counts: ({})
        }
    }
}
