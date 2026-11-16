import QtQuick
import Quickshell
import "../../config"
import "../../services"

Provider {
    id: root

    readonly property var mainCategories: [
        {
            id: "Development",
            label: "Dev"
        },
        {
            id: "Network",
            label: "Web"
        },
        {
            id: "AudioVideo",
            label: "Media"
        },
        {
            id: "Graphics",
            label: "Graphics"
        },
        {
            id: "Office",
            label: "Office"
        },
        {
            id: "Game",
            label: "Games"
        },
        {
            id: "Utility",
            label: "Utility"
        },
        {
            id: "System",
            label: "System"
        },
        {
            id: "Settings",
            label: "Settings"
        }
    ]
    readonly property var categories: {
        const present = root.mainCategories.filter(c => AppSearch.apps.some(app => app.categories.includes(c.id)));
        const hidden = AppSearch.hiddenApps.length > 0 ? [
            {
                id: "hidden",
                label: "Hidden"
            }
        ] : [];
        return [
            {
                id: "",
                label: "All"
            }
        ].concat(present, hidden);
    }
    property string category: ""
    property bool grouped: true

    function cycleCategory(step: int): void {
        const ids = root.categories.map(c => c.id);
        const i = Math.max(0, ids.indexOf(root.category));
        root.category = ids[(i + step + ids.length) % ids.length];
    }

    function appItem(app: DesktopEntry, positions: var, section: string): var {
        const wins = AppSearch.windowsOf(app);
        const pinned = AppSearch.isPinned(app);
        const hidden = AppSearch.isHidden(app);
        const pin = () => {
            AppSearch.togglePin(app);
            return true;
        };
        const hide = () => {
            AppSearch.toggleHidden(app);
            return true;
        };
        return {
            key: `app:${app.id}`,
            title: app.name,
            subtitle: app.genericName || app.comment,
            icon: app.icon,
            positions,
            section,
            running: wins.length > 0,
            pinned,
            preview: {
                kind: "app",
                app,
                windows: wins.length
            },
            pin,
            hide,
            actions: root._actions(app, wins, pinned, hidden, pin, hide),
            run: mode => {
                if (mode === "workspace")
                    AppSearch.launch(app, true);
                else if (wins.length > 0 && mode !== "alt")
                    AppSearch.focus(wins[0]);
                else
                    AppSearch.launch(app, false);
            }
        };
    }

    function _actions(app: DesktopEntry, wins: var, pinned: bool, hidden: bool, pin: var, hide: var): var {
        const out = app.actions.map(action => ({
                    key: `action:${app.id}:${action.id}`,
                    title: action.name,
                    icon: action.icon || app.icon,
                    run: () => AppSearch.launchAction(app, action)
                }));
        if (wins.length > 0)
            out.push({
                key: "new",
                title: "New window",
                icon: Icons.windowNew,
                run: () => AppSearch.launch(app, false)
            });
        out.push({
            key: "workspace",
            title: "Open on empty workspace",
            icon: Icons.grid,
            run: () => AppSearch.launch(app, true)
        }, {
            key: "pin",
            title: pinned ? "Unpin" : "Pin",
            icon: Icons.star,
            run: pin
        }, {
            key: "hide",
            title: hidden ? "Unhide" : "Hide from launcher",
            icon: Icons.hide,
            run: hide
        });
        return out;
    }

    function _pool(): var {
        if (root.category === "hidden")
            return AppSearch.hiddenApps;
        if (root.category === "")
            return AppSearch.apps;
        return AppSearch.apps.filter(app => app.categories.includes(root.category));
    }

    function _home(pool: var): var {
        const byName = [...pool].sort((a, b) => a.name.localeCompare(b.name));
        if (root.category !== "" || !root.grouped)
            return byName.map(app => root.appItem(app, [], ""));
        const pinned = AppSearch.pinned.map(id => pool.find(app => app.id === id)).filter(app => app);
        const recent = AppSearch.recent(6).filter(app => !pinned.includes(app));
        return [...pinned.map(app => root.appItem(app, [], "Pinned")), ...recent.map(app => root.appItem(app, [], "Recent")), ...byName.map(app => root.appItem(app, [], "All apps"))];
    }

    name: "Apps"
    icon: Icons.search
    placeholder: "Search apps, or type a prefix"
    enterHint: "open"
    altHint: "new window"
    items: {
        if (!root.active)
            return [];
        const pool = root._pool();
        if (root.text.trim() === "")
            return root._home(pool);
        return AppSearch.query(root.text, pool).map(r => root.appItem(r.app, r.positions, ""));
    }
}
