import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../config"
import "../../services"

Provider {
    id: root

    function windowItem(t: HyprlandToplevel, positions: var): var {
        const appId = t.wayland?.appId || t.lastIpcObject?.class || "";
        const entry = appId ? DesktopEntries.heuristicLookup(appId) : null;
        const address = `address:0x${t.address}`;
        const workspace = t.workspace?.name ?? "?";
        return {
            key: `window:${t.address}`,
            title: t.title || appId,
            subtitle: `${entry?.name ?? appId} · workspace ${workspace}`,
            icon: entry?.icon ?? appId,
            positions,
            running: t.activated,
            preview: {
                kind: "window",
                toplevel: t.wayland,
                title: t.title,
                appId,
                workspace
            },
            actions: [
                {
                    key: "focus",
                    title: "Focus",
                    icon: Icons.windows,
                    run: () => AppSearch.focus(t)
                },
                {
                    key: "here",
                    title: "Move to this workspace",
                    icon: Icons.grid,
                    run: () => AppSearch.dispatch(`hl.dsp.window.move({ workspace = ${Hyprland.focusedWorkspace?.id ?? 1}, window = "${address}" })`)
                },
                {
                    key: "close",
                    title: "Close",
                    icon: Icons.close,
                    danger: true,
                    run: () => {
                        AppSearch.dispatch(`hl.dsp.window.close({ window = "${address}" })`);
                        return true;
                    }
                }
            ],
            run: () => AppSearch.focus(t)
        };
    }

    onActiveChanged: {
        if (root.active)
            Hyprland.refreshToplevels();
    }

    prefix: "@"
    name: "Windows"
    icon: Icons.windows
    placeholder: "Switch to window"
    enterHint: "focus"
    items: {
        if (!root.active)
            return [];
        const terms = Fuzzy.terms(root.text);
        const recency = t => t.lastIpcObject?.focusHistoryID ?? 1e6;
        const wins = Hyprland.toplevels.values.filter(t => t.address);
        if (terms.length === 0)
            return wins.sort((a, b) => recency(a) - recency(b)).map(t => root.windowItem(t, []));
        const out = [];
        for (const t of wins) {
            const title = t.title || "";
            const r = Fuzzy.matchAll(terms, title) ?? (Fuzzy.matchAll(terms, t.lastIpcObject?.class ?? "") ? {
                    score: 1,
                    positions: []
                } : null);
            if (r)
                out.push({
                    t,
                    r
                });
        }
        return out.sort((a, b) => b.r.score - a.r.score).map(x => root.windowItem(x.t, x.r.positions));
    }
}
