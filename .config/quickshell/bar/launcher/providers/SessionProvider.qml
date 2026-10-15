import QtQuick
import Quickshell
import "../../config"
import "../../services"

Provider {
    id: root

    // Key of the dangerous entry awaiting a second Enter.
    property string armed: ""

    readonly property var entries: [
        {
            key: "lock",
            title: "Lock",
            subtitle: "Lock the screen",
            icon: Icons.lock,
            argv: ["idlectl", "lock"]
        },
        {
            key: "suspend",
            title: "Suspend",
            subtitle: "Sleep to RAM",
            icon: Icons.suspend,
            argv: ["systemctl", "suspend"]
        },
        {
            key: "caffeine",
            title: IdleInhibit.enabled ? "Caffeine off" : "Caffeine on",
            subtitle: IdleInhibit.enabled ? "Allow idle lock and suspend" : "Keep the session awake",
            icon: Icons.caffeine,
            toggle: () => IdleInhibit.enabled = !IdleInhibit.enabled
        },
        {
            key: "bar",
            title: "Toggle bar",
            subtitle: "Show or hide the top bar",
            icon: Icons.grid,
            argv: ["qs", "-c", "bar", "ipc", "call", "bar", "toggle"]
        },
        {
            key: "reload",
            title: "Reload bar",
            subtitle: "Restart quickshell",
            icon: Icons.refresh,
            argv: ["systemctl", "--user", "restart", "quickshell"]
        },
        {
            key: "logout",
            title: "Log out",
            subtitle: "End the Hyprland session",
            icon: Icons.logout,
            argv: ["uwsm", "stop"],
            danger: true
        },
        {
            key: "reboot",
            title: "Reboot",
            subtitle: "Restart the machine",
            icon: Icons.reboot,
            argv: ["systemctl", "reboot"],
            danger: true
        },
        {
            key: "shutdown",
            title: "Shut down",
            subtitle: "Power off",
            icon: Icons.shutdown,
            argv: ["systemctl", "poweroff"],
            danger: true
        }
    ]

    function entryItem(e: var, positions: var): var {
        const armed = root.armed === e.key;
        return {
            key: `session:${e.key}`,
            title: armed ? `${e.title}? Press Enter again` : e.title,
            subtitle: e.subtitle,
            icon: e.icon,
            positions: armed ? [] : positions,
            danger: e.danger ?? false,
            preview: {
                kind: "generic",
                icon: e.icon,
                title: e.title,
                detail: e.subtitle
            },
            run: () => {
                if (e.danger && !armed) {
                    root.armed = e.key;
                    return true;
                }
                root.armed = "";
                if (e.toggle) {
                    e.toggle();
                    return true;
                }
                Quickshell.execDetached(e.argv);
            }
        };
    }

    // Unprefixed matches, merged into app results.
    function matches(text: string): var {
        const terms = Fuzzy.terms(text);
        const out = [];
        for (const e of root.entries) {
            const r = Fuzzy.matchAll(terms, e.title);
            if (r && r.score > terms.join("").length * 18)
                out.push(root.entryItem(e, r.positions));
        }
        return out;
    }

    onTextChanged: root.armed = ""
    onActiveChanged: root.armed = ""

    prefix: "!"
    name: "System"
    icon: Icons.shutdown
    placeholder: "Lock, suspend, reboot, caffeine…"
    enterHint: "run"
    items: {
        if (!root.active)
            return [];
        const terms = Fuzzy.terms(root.text);
        const out = [];
        for (const e of root.entries) {
            const r = Fuzzy.matchAll(terms, e.title);
            if (r)
                out.push(root.entryItem(e, r.positions));
        }
        return out;
    }
}
