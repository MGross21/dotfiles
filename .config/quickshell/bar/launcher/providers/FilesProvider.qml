import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"

Provider {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property var found: []

    readonly property var kinds: ({
            image: ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "avif", "heic"],
            video: ["mp4", "mkv", "webm", "mov", "avi"],
            audio: ["mp3", "flac", "ogg", "wav", "opus", "m4a"],
            script: ["sh", "py", "js", "ts", "nix", "lua", "qml", "rs", "go", "c", "cpp", "h", "java", "rb"],
            archive: ["zip", "tar", "gz", "xz", "zst", "7z", "rar"]
        })

    function kindOf(path: string): string {
        if (path.endsWith("/"))
            return "folder";
        const ext = path.split(".").pop().toLowerCase();
        for (const [kind, exts] of Object.entries(root.kinds)) {
            if (exts.includes(ext))
                return kind;
        }
        return ext === "pdf" ? "pdf" : "text";
    }

    function tilde(path: string): string {
        return path.startsWith(root.home) ? "~" + path.slice(root.home.length) : path;
    }

    function fileItem(path: string, positions: var): var {
        const clean = path.replace(/\/$/, "");
        const slash = clean.lastIndexOf("/");
        const base = clean.slice(slash + 1);
        const dir = clean.slice(0, slash) || "/";
        const kind = root.kindOf(path);
        return {
            key: `file:${path}`,
            title: base,
            subtitle: root.tilde(dir),
            icon: Icons.fileKind(kind),
            positions,
            preview: {
                kind: "file",
                path: clean,
                fileKind: kind
            },
            actions: [
                {
                    key: "open",
                    title: "Open",
                    icon: Icons.fileKind(kind),
                    run: () => root.open(clean)
                },
                {
                    key: "folder",
                    title: "Open containing folder",
                    icon: Icons.fileKind("folder"),
                    run: () => root.open(dir)
                },
                {
                    key: "terminal",
                    title: "Open terminal here",
                    icon: Icons.terminal,
                    run: () => root.terminal(kind === "folder" ? clean : dir, "")
                },
                {
                    key: "copy",
                    title: "Copy path",
                    icon: Icons.paste,
                    run: () => root.copy(clean)
                }
            ],
            run: mode => mode === "alt" ? root.open(dir) : root.open(clean)
        };
    }

    onTextChanged: debounce.restart()
    onActiveChanged: {
        if (!root.active) {
            job.stop();
            root.found = [];
        }
    }

    prefix: "/"
    name: "Files"
    icon: Icons.fileKind("folder")
    placeholder: "Search files in ~"
    enterHint: "open"
    altHint: "open folder"
    busy: job.running
    items: {
        const terms = Fuzzy.terms(root.text);
        if (!root.active || terms.length === 0)
            return [];
        const out = [];
        for (const path of root.found) {
            const clean = path.replace(/\/$/, "");
            const base = clean.slice(clean.lastIndexOf("/") + 1);
            const r = Fuzzy.matchAll(terms, base);
            const depth = clean.split("/").length;
            if (r)
                out.push({
                    path,
                    score: r.score - depth,
                    positions: r.positions
                });
            else if (terms.every(t => clean.toLowerCase().includes(t)))
                out.push({
                    path,
                    score: -depth,
                    positions: []
                });
        }
        return out.sort((a, b) => b.score - a.score).slice(0, 100).map(x => root.fileItem(x.path, x.positions));
    }

    property Timer debounce: Timer {
        id: debounce

        interval: 150
        onTriggered: {
            const terms = Fuzzy.terms(root.text);
            if (!root.active || terms.length === 0) {
                root.found = [];
                return;
            }
            const longest = terms.reduce((a, b) => b.length > a.length ? b : a);
            job.start(["fd", "--hidden", "--absolute-path", "--ignore-case", "--fixed-strings", "--max-results", "2000", "--exclude", ".git", "--exclude", ".cache", "--exclude", "node_modules", "--exclude", ".local/share/Trash", ...(longest.includes("/") ? ["--full-path"] : []), "--", longest, root.home]);
        }
    }

    property Job job: Job {
        id: job

        onDone: out => root.found = out.split("\n").filter(l => l !== "")
    }
}
