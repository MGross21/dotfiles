import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"

// Reads clipse's history; clipse keeps recording it.
Provider {
    id: root

    property var history: []

    function age(recorded: string): string {
        const then = Date.parse(recorded.replace(" ", "T"));
        if (isNaN(then))
            return recorded;
        const mins = Math.round((Date.now() - then) / 60000);
        if (mins < 1)
            return "just now";
        if (mins < 60)
            return `${mins} min ago`;
        if (mins < 1440)
            return `${Math.round(mins / 60)} h ago`;
        return `${Math.round(mins / 1440)} d ago`;
    }

    function clipItem(entry: var, positions: var): var {
        const image = entry.filePath && entry.filePath !== "null";
        const line = entry.value.replace(/\s+/g, " ").trim().slice(0, 200);
        const copy = () => image ? Quickshell.execDetached(["sh", "-c", 'wl-copy < "$1"', "sh", entry.filePath]) : root.copy(entry.value);
        return {
            key: `clip:${entry.recorded}`,
            title: image ? "Image" : line,
            subtitle: `${entry.pinned ? "Pinned · " : ""}${root.age(entry.recorded)}${image ? "" : ` · ${entry.value.length} chars`}`,
            icon: image ? Icons.fileKind("image") : Icons.paste,
            positions,
            pinned: entry.pinned,
            preview: image ? {
                kind: "image",
                path: entry.filePath
            } : {
                kind: "text",
                text: entry.value,
                mono: true
            },
            run: copy
        };
    }

    prefix: "#"
    name: "Clipboard"
    icon: Icons.paste
    placeholder: "Search clipboard history"
    enterHint: "copy"
    items: {
        if (!root.active)
            return [];
        const terms = Fuzzy.terms(root.text);
        const sorted = [...root.history].sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));
        if (terms.length === 0)
            return sorted.map(e => root.clipItem(e, []));
        return sorted.filter(e => terms.every(t => e.value.toLowerCase().includes(t))).map(e => {
            const line = e.value.replace(/\s+/g, " ").trim().slice(0, 200).toLowerCase();
            const positions = [];
            for (const t of terms) {
                const at = line.indexOf(t);
                for (let i = 0; at >= 0 && i < t.length; i++)
                    positions.push(at + i);
            }
            return root.clipItem(e, positions);
        });
    }

    property FileView file: FileView {
        id: file

        path: root.active ? `${Quickshell.env("HOME")}/.config/clipse/clipboard_history.json` : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.history = JSON.parse(file.text()).clipboardHistory ?? [];
            } catch (e) {
                root.history = [];
            }
        }
    }
}
