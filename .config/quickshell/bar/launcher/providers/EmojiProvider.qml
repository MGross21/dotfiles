import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"

Provider {
    id: root

    readonly property int limit: 80
    readonly property int shortlist: 160
    // [char, name, group, lowercase name, lowercase group][]; loaded on first use.
    property var glyphs: []
    // Data files still loading.
    property int pending: 2

    onPendingChanged: root._load()

    // A term naming the group ("nerd", "smileys") filters by it unless the name spells it out.
    function _viaGroup(term: string, g: var): bool {
        return g[4].includes(term) && !g[3].includes(term);
    }

    function glyphItem(g: var, positions: var, section: string): var {
        const [char, name, group] = g;
        const remember = () => store.recent = [char, ...store.recent.filter(c => c !== char)].slice(0, 24);
        const codes = [...char].map(c => "U+" + c.codePointAt(0).toString(16).toUpperCase()).join(" ");
        return {
            key: `glyph:${char}:${name}`,
            title: name,
            subtitle: group,
            glyph: char,
            positions,
            section,
            preview: {
                kind: "glyph",
                glyph: char,
                title: name,
                detail: `${group} · ${codes}`
            },
            actions: [
                {
                    key: "copy",
                    title: "Copy",
                    glyph: char,
                    run: () => {
                        remember();
                        root.copy(char);
                    }
                },
                {
                    key: "codepoint",
                    title: `Copy ${codes}`,
                    icon: Icons.paste,
                    run: () => root.copy(codes)
                },
                {
                    key: "name",
                    title: "Copy name",
                    icon: Icons.paste,
                    run: () => root.copy(name)
                }
            ],
            run: mode => {
                remember();
                root.copy(char);
            }
        };
    }

    onActiveChanged: {
        if (root.active && emojiFile.path === "") {
            emojiFile.path = "/etc/quickshell/launcher/emoji-test.txt";
            nerdFile.path = "/etc/quickshell/launcher/glyphnames.json";
        }
    }

    function _load(): void {
        if (root.pending > 0)
            return;
        const out = [];
        let group = "";
        for (const line of (emojiFile.loaded ? emojiFile.text() : "").split("\n")) {
            if (line.startsWith("# group: ")) {
                group = line.slice(9);
                continue;
            }
            const m = /; fully-qualified\s+# (\S+) E[\d.]+ (.+)$/.exec(line);
            if (m)
                out.push(root._entry(m[1], m[2], group));
        }
        try {
            for (const [key, glyph] of Object.entries(nerdFile.loaded ? JSON.parse(nerdFile.text()) : {})) {
                if (key !== "METADATA")
                    out.push(root._entry(glyph.char, key.replace(/^[a-z]+-/, "").replace(/[_-]/g, " "), `nerd ${key.split("-")[0]}`));
            }
        } catch (e) {}
        root.glyphs = out;
    }

    function _entry(char: string, name: string, group: string): var {
        return [char, name, group, name.toLowerCase(), group.toLowerCase()];
    }

    prefix: ":"
    name: "Emoji & glyphs"
    icon: Icons.emoji
    placeholder: "Search emoji and Nerd Font glyphs"
    enterHint: "copy"
    items: {
        if (!root.active)
            return [];
        const terms = Fuzzy.terms(root.text);
        if (terms.length === 0) {
            const recent = store.recent.map(c => root.glyphs.find(g => g[0] === c)).filter(g => g);
            const smileys = root.glyphs.slice(0, root.limit);
            return [...recent.map(g => root.glyphItem(g, [], "Recent")), ...smileys.map(g => root.glyphItem(g, [], "Smileys & Emotion"))];
        }
        const seqs = terms.map(t => Fuzzy.subsequence(t));
        const rough = [];
        for (const g of root.glyphs) {
            let tier = 0;
            for (let i = 0; i < terms.length; i++) {
                const t = terms[i];
                if (root._viaGroup(t, g))
                    continue;
                const q = Fuzzy.quick(t, g[3], seqs[i]);
                if (q < 0) {
                    tier = -1;
                    break;
                }
                tier += q;
            }
            if (tier >= 0)
                rough.push({
                    g,
                    tier
                });
        }
        rough.sort((a, b) => b.tier - a.tier || a.g[1].length - b.g[1].length);
        const out = [];
        for (const x of rough.slice(0, root.shortlist)) {
            const grouped = terms.filter(t => root._viaGroup(t, x.g));
            const r = Fuzzy.matchAll(terms.filter(t => !grouped.includes(t)), x.g[1]);
            if (r)
                out.push({
                    g: x.g,
                    score: r.score + grouped.join("").length * 28 + x.tier * 4 + (x.g[2].startsWith("nerd") ? 0 : 6),
                    positions: r.positions
                });
        }
        return out.sort((a, b) => b.score - a.score).slice(0, root.limit).map(x => root.glyphItem(x.g, x.positions, ""));
    }

    property FileView emojiFile: FileView {
        id: emojiFile

        onLoaded: root.pending--
        onLoadFailed: root.pending--
    }

    property FileView nerdFile: FileView {
        id: nerdFile

        onLoaded: root.pending--
        onLoadFailed: root.pending--
    }

    property FileView recents: FileView {
        path: Quickshell.statePath("launcher-glyphs.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: store

            property var recent: []
        }
    }
}
