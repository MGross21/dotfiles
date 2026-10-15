import QtQuick
import Quickshell

// Item: { key, title, subtitle?, icon? (theme name or path), glyph?, positions?, section?,
//         running?, pinned?, danger?, preview?, actions?: Item[], pin?(), hide?(),
//         run(mode) -> true keeps the launcher open }. mode: default | alt | keep | workspace.
QtObject {
    id: root

    property string prefix: ""
    property string name: ""
    property string icon: ""
    property string placeholder: ""
    // Footer hints for Enter and Shift+Enter.
    property string enterHint: "open"
    property string altHint: ""
    property bool active: false
    property string text: ""
    property bool busy: false
    property var items: []

    function copy(text: string): void {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function open(target: string): void {
        Quickshell.execDetached(["uwsm", "app", "--", "xdg-open", target]);
    }

    function terminal(dir: string, command: string): void {
        const argv = ["uwsm", "app", "--", "ghostty", `--working-directory=${dir}`];
        Quickshell.execDetached(command ? [...argv, "-e", "sh", "-c", `${command}; exec "\${SHELL:-sh}"`] : argv);
    }
}
