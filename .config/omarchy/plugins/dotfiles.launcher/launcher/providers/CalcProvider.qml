import QtQuick
import "../../config"

Provider {
    id: root

    // Answer unprefixed queries too, when they look like math.
    property bool auto: false
    property string result: ""
    property string expression: ""

    function looksLikeMath(text: string): bool {
        return /^[-+(.√\d]/.test(text) && /\d/.test(text) && /[-+*\/^%()!=√]|\bto\b/i.test(text);
    }

    onTextChanged: debounce.restart()

    prefix: "="
    name: "Calculator"
    icon: Icons.calculator
    placeholder: "Math, units, currency (10 km to mi, 20 usd to eur)"
    enterHint: "copy result"
    busy: job.running
    items: {
        if (!root.active && !root.auto || root.result === "" || root.expression !== root.text.trim())
            return [];
        return [
            {
                key: "calc",
                title: root.result,
                subtitle: `${root.expression} =`,
                icon: Icons.calculator,
                preview: {
                    kind: "text",
                    text: `${root.expression}\n= ${root.result}`,
                    mono: true
                },
                run: () => root.copy(root.result)
            }
        ];
    }

    property Timer debounce: Timer {
        id: debounce

        interval: 80
        onTriggered: {
            const expr = root.text.trim();
            if (expr === "" || !root.active && !(root.auto && root.looksLikeMath(expr))) {
                job.stop();
                root.result = "";
                return;
            }
            job.expr = expr;
            job.start(["qalc", "-t", "-s", "update exchange rates 1", expr]);
        }
    }

    property Job job: Job {
        id: job

        property string expr

        onDone: out => {
            const value = out.trim().split("\n").pop() ?? "";
            const useful = value !== "" && value !== job.expr && !/error|warning|[ℜℑ]|\(\)/i.test(value);
            root.result = useful ? value : "";
            root.expression = job.expr;
        }
    }
}
