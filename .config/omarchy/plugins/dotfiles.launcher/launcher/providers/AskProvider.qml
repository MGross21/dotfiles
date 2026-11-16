import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"

Provider {
    id: root

    property string question: ""
    property string answer: ""
    property string error: ""
    property string model: ""
    property var pending: null
    readonly property bool hasAnswer: root.question !== "" && (root.busy || root.answer !== "" || root.error !== "")

    function ask(question: string, model: string): void {
        root.question = question;
        root.model = model;
        root.answer = "";
        root.error = "";
        root.pending = ["claude", "-p", "--model", model, "--tools", "", "--setting-sources", "", "--strict-mcp-config", "--no-session-persistence", "--output-format", "stream-json", "--verbose", "--include-partial-messages", "--system-prompt", "You answer quick questions from a desktop launcher. Be concise and direct. Use Markdown only when it helps.", question];
        if (proc.running)
            proc.running = false;
        else
            root._start();
    }

    function _start(): void {
        if (!root.pending)
            return;
        proc.command = root.pending;
        root.pending = null;
        proc.running = true;
    }

    function _event(line: string): void {
        let msg;
        try {
            msg = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (msg.type === "stream_event" && msg.event?.type === "content_block_delta" && msg.event.delta?.type === "text_delta")
            root.answer += msg.event.delta.text;
        else if (msg.type === "result" && msg.is_error)
            root.error = msg.result || "Request failed";
    }

    onActiveChanged: {
        if (!root.active) {
            root.pending = null;
            proc.running = false;
            root.question = "";
        }
    }

    prefix: "ai "
    name: "Ask Claude"
    icon: Icons.ask
    placeholder: "Ask Claude anything"
    enterHint: "ask (Haiku)"
    altHint: "ask (Sonnet)"
    busy: proc.running
    items: {
        const q = root.text.trim();
        if (!root.active || q === "")
            return [];
        if (q !== root.question)
            return [
                {
                    key: "ask",
                    title: q,
                    subtitle: "Ask Claude",
                    icon: Icons.ask,
                    preview: {
                        kind: "generic",
                        icon: Icons.ask,
                        title: "Ask Claude",
                        detail: "Enter asks Haiku, Shift+Enter asks Sonnet"
                    },
                    run: mode => {
                        root.ask(q, mode === "alt" ? "sonnet" : "haiku");
                        return true;
                    }
                }
            ];
        return [
            {
                key: "copy",
                title: "Copy answer",
                subtitle: root.busy ? "Still answering…" : `${root.model} · ${root.answer.length} chars`,
                icon: Icons.paste,
                run: () => root.copy(root.answer)
            },
            {
                key: "terminal",
                title: "Continue in Claude Code",
                subtitle: "Open an interactive session with this question",
                icon: Icons.terminal,
                run: () => root.terminal(Quickshell.env("HOME"), `claude ${JSON.stringify(q).replace(/\$/g, "\\$").replace(/`/g, "\\`")}`)
            },
            {
                key: "again",
                title: "Ask again",
                subtitle: "Retry with Sonnet",
                icon: Icons.refresh,
                run: () => {
                    root.ask(q, "sonnet");
                    return true;
                }
            }
        ];
    }

    property Process proc: Process {
        id: proc

        workingDirectory: Quickshell.env("HOME")
        onExited: root._start()
        stdout: SplitParser {
            onRead: line => {
                if (!root.pending)
                    root._event(line);
            }
        }
        stderr: StdioCollector {
            id: stderr

            onStreamFinished: {
                if (root.answer === "" && root.error === "" && stderr.text.trim() !== "")
                    root.error = stderr.text.trim();
            }
        }
    }
}
