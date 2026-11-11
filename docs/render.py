import html
import json
import re
import sys
from itertools import groupby
from pathlib import Path

ROLE = re.compile(r"\{(option|var|env|file|command|manpage)\}`([^`]+)`")


def slug(name):
    return re.sub(r"[^A-Za-z0-9._-]+", "-", name).strip("-")


def kind(type_):
    t = type_.removeprefix("null or ")
    if t == "boolean":
        return "boolean"
    if t.startswith("list of"):
        return "list"
    if t.startswith(("attribute set", "lazy attribute set")) or "submodule" in t:
        return "attrs"
    if t == "package":
        return "package"
    if t.startswith(("signed integer", "16 bit", "integer", "positive", "unsigned", "floating", "number")):
        return "number"
    if "string" in t or t.startswith(("one of", "absolute path", "path")):
        return "string"
    return "other"


def code(value):
    text = html.escape(value)
    return f"<pre><code>{text}</code></pre>" if "\n" in value else f"<code>{text}</code>"


def literal(value):
    if value is None:
        return None
    if isinstance(value, dict) and value.get("_type") == "literalMD":
        return f"<span>{html.escape(value['text'])}</span>"
    if isinstance(value, dict) and "text" in value:
        return code(value["text"])
    return code(json.dumps(value))


def option(name, opt, hosts, pages):
    def role(m):
        target = pages.get(m[2])
        return f"[`{m[2]}`]({target}#{slug(m[2])})" if m[1] == "option" and target else f"`{m[2]}`"

    rows = [("Type", f"<code>{html.escape(opt['type'])}</code>")]
    for label, key in (("Default", "default"), ("Example", "example")):
        if (cell := literal(opt.get(key))) is not None:
            rows.append((label, cell))
    if values := hosts.get(name):
        cells = "".join(f"<tr><th>{html.escape(h)}</th><td>{code(v)}</td></tr>" for h, v in sorted(values.items()))
        rows.append(("Hosts", f'<table class="hosts">{cells}</table>'))
    if links := "".join(f'<a href="{d["url"]}">{html.escape(d["name"])}</a>' for d in opt.get("declarations", [])):
        rows.append(("Source", links))
    if opt.get("readOnly"):
        rows.append(("Access", "read-only"))
    meta = "".join(f"<div><dt>{k}</dt><dd>{v}</dd></div>" for k, v in rows)
    return [
        f'<div class="option" data-kind="{kind(opt["type"])}" markdown>',
        "",
        f"### `{name}` {{ #{slug(name)} }}",
        "",
        ROLE.sub(role, opt.get("description") or ""),
        "",
        f'<dl class="meta" data-search-exclude>{meta}</dl>',
        "",
        "</div>",
        "",
    ]


def main(sections_path, hosts_path, out_dir):
    out = Path(out_dir)
    hosts = json.loads(Path(hosts_path).read_text())
    sections = [
        {**s, "options": opts}
        for s in json.loads(Path(sections_path).read_text())
        if (opts := json.loads(Path(s["file"]).read_text()))
    ]
    pages = {name: f"{s['id']}.md" for s in sections for name in s["options"]}
    index = ["# Options", "", "| Section | Options |", "| --- | --: |"]
    for s in sections:
        index.append(f"| [{s['title']}]({s['id']}.md) | {len(s['options'])} |")
        lines = [f"# {s['title']}", ""]
        for ns, group in groupby(sorted(s["options"].items()), key=lambda kv: kv[0].split(".")[0]):
            lines += [f"## {ns}", ""]
            for name, opt in group:
                lines += option(name, opt, hosts, pages)
        (out / f"{s['id']}.md").write_text("\n".join(lines))
    (out / "index.md").write_text("\n".join(index) + "\n")


if __name__ == "__main__":
    main(*sys.argv[1:])
