import QtQuick
import "../../config"

Provider {
    id: root

    readonly property var engines: [
        {
            key: "ddg",
            title: "DuckDuckGo",
            url: "https://duckduckgo.com/?q="
        },
        {
            key: "google",
            title: "Google",
            url: "https://www.google.com/search?q="
        },
        {
            key: "github",
            title: "GitHub",
            url: "https://github.com/search?type=repositories&q="
        },
        {
            key: "nixpkgs",
            title: "Nix packages",
            url: "https://search.nixos.org/packages?channel=unstable&query="
        },
        {
            key: "nixopts",
            title: "NixOS options",
            url: "https://search.nixos.org/options?channel=unstable&query="
        },
        {
            key: "youtube",
            title: "YouTube",
            url: "https://www.youtube.com/results?search_query="
        },
        {
            key: "wikipedia",
            title: "Wikipedia",
            url: "https://en.wikipedia.org/w/index.php?search="
        }
    ]

    function looksLikeUrl(text: string): bool {
        return /^(https?:\/\/)?[\w-]+(\.[\w-]+)+(:\d+)?(\/\S*)?$/i.test(text);
    }

    function searchItem(engine: var, query: string): var {
        const url = engine.url + encodeURIComponent(query);
        return {
            key: `web:${engine.key}`,
            title: `Search ${engine.title} for “${query}”`,
            subtitle: url,
            icon: Icons.web,
            preview: {
                kind: "generic",
                icon: Icons.web,
                title: engine.title,
                detail: url
            },
            run: () => root.open(url)
        };
    }

    function urlItem(text: string): var {
        const url = /^https?:\/\//i.test(text) ? text : `https://${text}`;
        return {
            key: "web:url",
            title: `Open ${url}`,
            subtitle: "Open in browser",
            icon: Icons.web,
            preview: {
                kind: "generic",
                icon: Icons.web,
                title: "Open URL",
                detail: url
            },
            run: () => root.open(url)
        };
    }

    // Unprefixed fallback when nothing else matches.
    function fallback(text: string): var {
        const q = text.trim();
        if (q === "")
            return [];
        return [...(root.looksLikeUrl(q) ? [root.urlItem(q)] : []), root.searchItem(root.engines[0], q)];
    }

    prefix: "?"
    name: "Web"
    icon: Icons.web
    placeholder: "Search the web"
    enterHint: "search"
    items: {
        const q = root.text.trim();
        if (!root.active || q === "")
            return [];
        return [...(root.looksLikeUrl(q) ? [root.urlItem(q)] : []), ...root.engines.map(e => root.searchItem(e, q))];
    }
}
