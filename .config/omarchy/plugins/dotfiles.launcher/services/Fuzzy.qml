pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int matchScore: 16
    readonly property int consecutiveBonus: 8
    readonly property int gapOpen: 3
    readonly property int gapExtend: 1

    function _bonus(hay: string, j: int): int {
        if (j === 0)
            return 12;
        const prev = hay[j - 1];
        if (" -_./:\\".includes(prev))
            return 10;
        const ch = hay[j];
        if (prev === prev.toLowerCase() && ch !== ch.toLowerCase())
            return 8;
        return 0;
    }

    // `needle` must be lowercase. Returns null or { score, positions } indexing `hay`.
    function match(needle: string, hay: string): var {
        const n = needle.length;
        const m = hay.length;
        if (n === 0)
            return {
                score: 0,
                positions: []
            };
        if (n > m)
            return null;

        const low = hay.toLowerCase();
        let k = 0;
        for (let j = 0; j < m && k < n; j++) {
            if (low[j] === needle[k])
                k++;
        }
        if (k < n)
            return null;

        const bonus = [];
        for (let j = 0; j < m; j++)
            bonus.push(root._bonus(hay, j));

        const none = -1e9;
        let prevRow = [];
        const back = [];
        for (let i = 0; i < n; i++) {
            const row = new Array(m).fill(none);
            const from = new Array(m).fill(-1);
            let gapBest = none;
            let gapIdx = -1;
            for (let j = i; j < m; j++) {
                if (i > 0 && j >= 2) {
                    const opened = prevRow[j - 2] - root.gapOpen;
                    gapBest -= root.gapExtend;
                    if (opened > gapBest) {
                        gapBest = opened;
                        gapIdx = j - 2;
                    }
                }
                if (low[j] !== needle[i])
                    continue;
                const gain = root.matchScore + bonus[j];
                if (i === 0) {
                    row[j] = gain + bonus[j] - Math.min(j, 8);
                    continue;
                }
                const adjacent = prevRow[j - 1] > none ? prevRow[j - 1] + root.consecutiveBonus : none;
                if (adjacent >= gapBest && adjacent > none) {
                    row[j] = adjacent + gain;
                    from[j] = j - 1;
                } else if (gapBest > none / 2) {
                    row[j] = gapBest + gain;
                    from[j] = gapIdx;
                }
            }
            back.push(from);
            prevRow = row;
        }

        let best = none;
        let end = -1;
        for (let j = 0; j < m; j++) {
            if (prevRow[j] > best) {
                best = prevRow[j];
                end = j;
            }
        }
        if (end < 0)
            return null;

        const positions = new Array(n);
        for (let i = n - 1, j = end; i >= 0; i--) {
            positions[i] = j;
            j = back[i][j];
        }
        return {
            score: best - (m - n) * 0.1,
            positions
        };
    }

    function subsequence(needle: string): var {
        return new RegExp(needle.split("").map(c => c.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join(".*"));
    }

    // Cheap tier for prefiltering big lists: 3 prefix, 2 word start, 1 substring, 0 subsequence, -1 none.
    function quick(needle: string, low: string, seq: var): int {
        const at = low.indexOf(needle);
        if (at === 0)
            return 3;
        if (at > 0)
            return " -_./:".includes(low[at - 1]) ? 2 : 1;
        return seq.test(low) ? 0 : -1;
    }

    // Every term must match; returns null or { score, positions }.
    function matchAll(terms: var, hay: string): var {
        let score = 0;
        let positions = [];
        for (const term of terms) {
            const r = root.match(term, hay);
            if (!r)
                return null;
            score += r.score;
            positions = positions.concat(r.positions);
        }
        return {
            score,
            positions
        };
    }

    function terms(text: string): var {
        return text.toLowerCase().split(/\s+/).filter(t => t !== "");
    }

    function escapeHtml(text: string): string {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function highlight(text: string, positions: var, color: string): string {
        if (!positions || positions.length === 0)
            return root.escapeHtml(text);
        const marked = new Set(positions);
        let out = "";
        let open = false;
        for (let i = 0; i < text.length; i++) {
            const hit = marked.has(i);
            if (hit !== open) {
                out += hit ? `<font color="${color}"><b>` : "</b></font>";
                open = hit;
            }
            out += root.escapeHtml(text[i]);
        }
        return open ? out + "</b></font>" : out;
    }
}
