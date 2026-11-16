pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Ui
import "../components"
import "../config"
import "../services"
import "providers"

Item {
    id: root

    property string omarchyPath: ""
    property var shell: null
    property var manifest: null

    property bool opened: false
    readonly property int listHeight: Theme.launcherRows * Theme.launcherRowHeight
    readonly property int paneWidth: Theme.launcherWidth + (ui.preview ? Theme.launcherPreviewWidth + Theme.padding : 0)

    property string input: ""
    property string preset: ""
    // Set while a result's actions are listed; the query that produced it is kept in savedInput.
    property string actionsKey: ""
    property string actionsTitle: ""
    property string savedInput: ""

    readonly property string source: root.actionsKey !== "" ? root.savedInput : root.input
    readonly property var providers: [windows, files, run, calc, emoji, clipboard, session, web, ask, ssh, ...scripts.instances]
    readonly property Provider mode: root.providers.find(p => p.prefix !== "" && root.source.startsWith(p.prefix)) ?? apps
    readonly property string query: root.mode === apps ? root.source : root.source.slice(root.mode.prefix.length).replace(/^\s+/, "")
    readonly property bool grid: ui.grid && root.mode === apps && root.query.trim() === "" && root.actionsKey === ""

    readonly property var results: {
        if (root.mode !== apps)
            return root.mode.items;
        if (root.query.trim() === "")
            return apps.items;
        const merged = [...calc.items, ...apps.items, ...session.matches(root.query)];
        return merged.length > 0 ? merged : web.fallback(root.query);
    }

    readonly property var shown: {
        if (root.actionsKey === "")
            return root.results;
        const parent = root.results.find(i => i.key === root.actionsKey);
        const terms = Fuzzy.terms(root.input);
        const out = [];
        for (const a of parent?.actions ?? []) {
            const r = Fuzzy.matchAll(terms, a.title);
            if (r)
                out.push(Object.assign({
                    preview: parent.preview
                }, a, {
                    positions: r.positions
                }));
        }
        return out;
    }

    signal presetApplied

    // Host summon. `payloadJson` may carry `text` to type in, e.g. "@" for windows or "#" for clipboard.
    function open(payloadJson: string): void {
        let payload = {};
        try {
            payload = JSON.parse(payloadJson || "{}") ?? {};
        } catch (e) {}
        root.preset = String(payload.text ?? "");
        if (root.opened) {
            root.presetApplied();
            return;
        }
        root.opened = true;
    }

    // Host hide.
    function close(): void {
        root.opened = false;
        root.input = "";
        root.actionsKey = "";
        root.savedInput = "";
        apps.category = "";
    }

    function dismiss(): void {
        root.close();
        root.shell?.hide(root.manifest?.id ?? "");
    }

    // Returns true when the launcher stays open.
    function activate(item: var, mode: string): bool {
        if (!item?.run)
            return true;
        const keep = mode === "keep";
        const stay = item.run(keep ? "default" : mode) === true;
        if (keep || stay)
            return true;
        root.dismiss();
        return false;
    }

    AppsProvider {
        id: apps

        active: root.opened && root.mode === apps
        text: apps.active ? root.query : ""
        grouped: !ui.grid
    }

    WindowsProvider {
        id: windows

        active: root.opened && root.mode === windows
        text: windows.active ? root.query : ""
    }

    FilesProvider {
        id: files

        active: root.opened && root.mode === files
        text: files.active ? root.query : ""
    }

    RunProvider {
        id: run

        active: root.opened && root.mode === run
        text: run.active ? root.query : ""
    }

    CalcProvider {
        id: calc

        active: root.opened && root.mode === calc
        auto: root.opened && root.mode === apps && root.actionsKey === ""
        text: calc.active || calc.auto ? root.query : ""
    }

    EmojiProvider {
        id: emoji

        active: root.opened && root.mode === emoji
        text: emoji.active ? root.query : ""
    }

    ClipboardProvider {
        id: clipboard

        active: root.opened && root.mode === clipboard
        text: clipboard.active ? root.query : ""
    }

    SessionProvider {
        id: session

        active: root.opened && root.mode === session
        text: root.opened && (session.active || root.mode === apps) ? root.query : ""
    }

    WebProvider {
        id: web

        active: root.opened && root.mode === web
        text: web.active ? root.query : ""
    }

    AskProvider {
        id: ask

        active: root.opened && root.mode === ask
        text: ask.active ? root.query : ""
    }

    SshProvider {
        id: ssh

        active: root.opened && root.mode === ssh
        text: ssh.active ? root.query : ""
    }

    Variants {
        id: scripts

        model: specs.entries

        ScriptProvider {
            id: script

            required property var modelData

            spec: script.modelData
            active: root.opened && root.mode === script
            text: script.active ? root.query : ""
        }
    }

    FileView {
        id: specs

        property var entries: []

        path: Paths.data("providers.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                specs.entries = JSON.parse(specs.text());
            } catch (e) {
                specs.entries = [];
            }
        }
    }

    FileView {
        path: Paths.state("launcher-ui.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: ui

            property bool grid: false
            property bool preview: true
        }
    }

    OverlayWindow {
        shown: root.opened

        WlrLayershell.namespace: "dotfiles-launcher"

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismiss()
        }

        Loader {
            anchors.fill: parent
            active: root.opened
            sourceComponent: paneComponent
        }
    }

    Component {
        id: paneComponent

        Item {
            id: pane

            property bool revealing: true
            property bool altHeld: false
            property string lastQuery: ""
            property string selectedKey: ""

            readonly property var view: root.grid ? tiles : list
            readonly property var current: root.shown[pane.view.currentIndex] ?? null
            readonly property int firstVisible: {
                const probe = y => list.count > 0 ? list.indexAt(Theme.padding, list.contentY + y) : -1;
                const top = probe(Theme.launcherRowHeight / 2);
                return top >= 0 ? top : Math.max(0, probe(Theme.launcherSectionHeight + Theme.launcherRowHeight / 2));
            }

            function move(step: int): void {
                const v = pane.view;
                if (v.count === 0)
                    return;
                pane.select(Math.max(0, Math.min(v.count - 1, v.currentIndex + step)));
            }

            // Views reset currentIndex on model swaps, so the selection is tracked by key here.
            function select(index: int): void {
                pane.view.currentIndex = index;
                pane.selectedKey = root.shown[index]?.key ?? "";
            }

            function openActions(item: var): void {
                if (!item?.actions?.length || root.actionsKey !== "")
                    return;
                root.savedInput = root.input;
                root.actionsKey = item.key;
                root.actionsTitle = item.title;
                field.text = "";
            }

            function closeActions(): void {
                const restore = root.savedInput;
                root.actionsKey = "";
                root.savedInput = "";
                field.text = restore;
                field.cursorPosition = restore.length;
            }

            function quick(n: int): void {
                const index = (root.grid ? 0 : pane.firstVisible) + n - 1;
                if (index < root.shown.length)
                    root.activate(root.shown[index], "default");
            }

            function setPrefix(prefix: string): void {
                const rest = root.mode === apps ? root.input : root.query;
                field.text = prefix + rest;
                field.cursorPosition = field.text.length;
                field.forceActiveFocus();
            }

            function syncSelection(): void {
                const v = pane.view;
                const scope = root.source + "\u0000" + root.actionsKey + "\u0000" + root.input;
                if (scope !== pane.lastQuery) {
                    pane.lastQuery = scope;
                    pane.select(0);
                } else {
                    pane.select(Math.max(0, root.shown.findIndex(item => item.key === pane.selectedKey)));
                }
                if (v === list)
                    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
            }

            Connections {
                target: root

                function onPresetApplied(): void {
                    field.text = root.preset;
                    root.preset = "";
                    field.cursorPosition = field.text.length;
                }
            }

            Timer {
                interval: Theme.durSlow
                running: true
                onTriggered: pane.revealing = false
            }

            BorderSurface {
                id: body

                readonly property int maxHeight: Theme.cardPadding * 2 + Theme.padding * 3 + Theme.launcherFieldHeight + Theme.launcherChipHeight + root.listHeight + Theme.launcherHintHeight

                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(0, (parent.height - body.maxHeight) / 2)
                width: Math.min(root.paneWidth + body.contentLeftInset + body.contentRightInset, parent.width)
                height: column.implicitHeight + body.contentTopInset + body.contentBottomInset
                radius: Theme.radius
                color: Theme.base
                borderSpec: Theme.borderSpec
                padding: Theme.cardPadding
                opacity: 0
                Component.onCompleted: intro.start()

                NumberAnimation {
                    id: intro

                    target: body
                    property: "opacity"
                    to: 1
                    duration: Theme.durBase
                    easing.type: Theme.easeStandard
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.durBase
                        easing.type: Theme.easeStandard
                    }
                }

                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    id: column

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: body.contentTopInset
                        leftMargin: body.contentLeftInset
                        rightMargin: body.contentRightInset
                    }
                    spacing: Theme.padding

                    Item {
                        width: parent.width
                        height: Theme.launcherFieldHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius
                            color: Theme.controlFill
                            border.width: 1
                            border.color: Theme.focusBorder
                        }

                        Icon {
                            id: glyph

                            anchors {
                                left: parent.left
                                leftMargin: Theme.padding
                                verticalCenter: parent.verticalCenter
                            }
                            source: root.actionsKey !== "" ? Icons.next : root.mode.icon
                            color: field.text === "" && root.mode === apps ? Theme.inkDim : Theme.accent
                        }

                        Rectangle {
                            id: crumb

                            anchors {
                                left: glyph.right
                                leftMargin: Theme.padding
                                verticalCenter: parent.verticalCenter
                            }
                            visible: root.actionsKey !== ""
                            width: visible ? crumbText.implicitWidth + Theme.padding : 0
                            height: Theme.launcherChipHeight
                            radius: Theme.radius
                            color: Theme.selectionFill

                            Text {
                                id: crumbText

                                anchors.centerIn: parent
                                text: root.actionsTitle
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        TextInput {
                            id: field

                            anchors {
                                left: crumb.right
                                leftMargin: crumb.visible ? Theme.padding : 0
                                right: status.left
                                rightMargin: Theme.padding
                                verticalCenter: parent.verticalCenter
                            }
                            focus: true
                            color: Theme.fg
                            selectionColor: Theme.tinted(Theme.accent, 0.3)
                            selectedTextColor: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSizeInput
                            clip: true
                            onTextChanged: {
                                root.input = field.text;
                                session.armed = "";
                            }
                            Component.onCompleted: {
                                field.text = root.preset;
                                root.preset = "";
                                field.forceActiveFocus();
                            }

                            Keys.onReleased: event => {
                                if (event.key === Qt.Key_Alt)
                                    pane.altHeld = false;
                            }

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier;
                                const alt = event.modifiers & Qt.AltModifier;
                                const shift = event.modifiers & Qt.ShiftModifier;
                                const key = event.key;
                                const atEnd = field.cursorPosition === field.text.length && field.selectedText === "";
                                const cols = Math.max(1, Math.floor(tiles.width / tiles.cellWidth));
                                if (key === Qt.Key_Alt) {
                                    pane.altHeld = true;
                                    return;
                                }
                                if (key === Qt.Key_Escape) {
                                    if (root.actionsKey !== "")
                                        pane.closeActions();
                                    else
                                        root.dismiss();
                                } else if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                                    root.activate(pane.current, alt ? "workspace" : ctrl ? "keep" : shift ? "alt" : "default");
                                } else if (alt && key >= Qt.Key_1 && key <= Qt.Key_9) {
                                    pane.quick(key - Qt.Key_0);
                                } else if (key === Qt.Key_Down || key === Qt.Key_Tab || ctrl && (key === Qt.Key_J || key === Qt.Key_N)) {
                                    pane.move(root.grid && key === Qt.Key_Down ? cols : 1);
                                } else if (key === Qt.Key_Up || key === Qt.Key_Backtab || ctrl && (key === Qt.Key_K || key === Qt.Key_P)) {
                                    pane.move(root.grid && key === Qt.Key_Up ? -cols : -1);
                                } else if (key === Qt.Key_PageDown) {
                                    pane.move(Theme.launcherRows - 1);
                                } else if (key === Qt.Key_PageUp) {
                                    pane.move(-(Theme.launcherRows - 1));
                                } else if (root.grid && field.text === "" && (key === Qt.Key_Left || key === Qt.Key_Right)) {
                                    pane.move(key === Qt.Key_Right ? 1 : -1);
                                } else if (ctrl && (key === Qt.Key_Left || key === Qt.Key_Right) && root.mode === apps && root.actionsKey === "") {
                                    apps.cycleCategory(key === Qt.Key_Right ? 1 : -1);
                                } else if (key === Qt.Key_Right && atEnd && pane.current?.actions?.length || ctrl && key === Qt.Key_L) {
                                    pane.openActions(pane.current);
                                } else if (root.actionsKey !== "" && (key === Qt.Key_Left && field.cursorPosition === 0 || key === Qt.Key_Backspace && field.text === "")) {
                                    pane.closeActions();
                                } else if (ctrl && key === Qt.Key_S && pane.current?.pin) {
                                    pane.current.pin();
                                } else if (ctrl && key === Qt.Key_H && pane.current?.hide) {
                                    pane.current.hide();
                                } else if (ctrl && key === Qt.Key_G) {
                                    ui.grid = !ui.grid;
                                } else if (ctrl && key === Qt.Key_O) {
                                    ui.preview = !ui.preview;
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.actionsKey !== "" ? "Filter actions" : root.mode.placeholder
                                color: Theme.inkDim
                                font: parent.font
                                visible: field.text === "" || field.text === root.mode.prefix
                                x: field.text === "" ? 0 : field.contentWidth + Theme.gap
                            }
                        }

                        Row {
                            id: status

                            anchors {
                                right: parent.right
                                rightMargin: Theme.padding
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: Theme.gap * 2

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.mode.busy
                                source: Icons.refresh
                                color: Theme.accent

                                RotationAnimator on rotation {
                                    from: 0
                                    to: 360
                                    duration: 900
                                    loops: Animation.Infinite
                                    running: root.mode.busy
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.mode !== apps
                                text: root.mode.name
                                color: Theme.accent
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Flickable {
                        id: chips

                        width: parent.width
                        height: Theme.launcherChipHeight
                        opacity: root.actionsKey === "" ? 1 : 0
                        enabled: root.actionsKey === ""
                        contentWidth: chipRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick

                        readonly property bool categories: root.mode === apps
                        readonly property var model: chips.categories ? apps.categories : [apps, ...root.providers].map(p => ({
                                    id: p.prefix,
                                    label: p.prefix === "" || p.prefix.trim().toLowerCase() === p.name.toLowerCase() ? p.name : `${p.prefix.trim()} ${p.name}`,
                                    provider: p
                                }))

                        Row {
                            id: chipRow

                            spacing: Theme.gap

                            Repeater {
                                model: chips.model

                                delegate: Rectangle {
                                    id: chip

                                    required property var modelData
                                    readonly property bool on: chips.categories ? apps.category === chip.modelData.id : root.mode === chip.modelData.provider

                                    width: chipLabel.implicitWidth + Theme.padding * 1.5
                                    height: Theme.launcherChipHeight
                                    radius: Theme.radius
                                    color: chip.on ? Theme.selectionFill : chipHover.hovered ? Theme.controlHoverFill : Theme.transparent
                                    border.width: 1
                                    border.color: chip.on ? Theme.transparent : Theme.controlBorder
                                    antialiasing: true

                                    Text {
                                        id: chipLabel

                                        anchors.centerIn: parent
                                        text: chip.modelData.label
                                        color: chip.on ? Theme.selectedText : Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                        font.weight: chip.on ? Font.Bold : Font.Normal
                                    }

                                    HoverHandler {
                                        id: chipHover
                                    }

                                    TapHandler {
                                        onTapped: {
                                            if (chips.categories)
                                                apps.category = chip.on ? "" : chip.modelData.id;
                                            else
                                                pane.setPrefix(chip.modelData.id);
                                            field.forceActiveFocus();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.padding

                        Column {
                            id: results

                            width: Theme.launcherWidth

                            Flickable {
                                id: answer

                                readonly property bool shown: root.mode === ask && ask.hasAnswer

                                width: parent.width
                                height: answer.shown ? root.listHeight - Math.min(list.count, 3) * Theme.launcherRowHeight : 0
                                visible: answer.shown
                                contentHeight: answerText.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                onContentHeightChanged: {
                                    if (ask.busy)
                                        answer.contentY = Math.max(0, answer.contentHeight - answer.height);
                                }

                                TextEdit {
                                    id: answerText

                                    width: parent.width
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.Wrap
                                    textFormat: ask.error !== "" ? TextEdit.PlainText : TextEdit.MarkdownText
                                    text: ask.error !== "" ? ask.error : ask.answer !== "" ? ask.answer : "Thinking…"
                                    color: ask.error !== "" ? Theme.accent : Theme.fg
                                    selectionColor: Theme.tinted(Theme.accent, 0.3)
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSizeLarge
                                }
                            }

                            ListView {
                                id: list

                                // x < 0: no pointer seen yet
                                property point pointer: Qt.point(-1, -1)

                                width: parent.width
                                height: root.grid ? 0 : Math.min(list.contentHeight, root.listHeight - answer.height)
                                visible: !root.grid && count > 0
                                model: root.grid ? [] : root.shown
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                highlightMoveDuration: Theme.durFast
                                highlightResizeDuration: 0
                                currentIndex: 0
                                section.property: "section"
                                section.criteria: ViewSection.FullString
                                onModelChanged: pane.syncSelection()

                                section.delegate: Text {
                                    required property string section

                                    width: list.width
                                    height: section === "" ? 0 : Theme.launcherSectionHeight
                                    visible: section !== ""
                                    leftPadding: Theme.padding
                                    verticalAlignment: Text.AlignVCenter
                                    text: section.toUpperCase()
                                    color: Theme.inkDim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1
                                }

                                highlight: Rectangle {
                                    radius: Theme.radius
                                    color: Theme.selectionFill
                                }

                                delegate: ResultRow {
                                    id: row

                                    width: list.width
                                    reveal: pane.revealing && row.index < Theme.launcherRows
                                    badge: pane.altHeld && row.index >= pane.firstVisible && row.index < pane.firstVisible + 9 ? row.index - pane.firstVisible + 1 : 0
                                    onHovered: pointer => {
                                        const moved = list.pointer.x >= 0 && (pointer.x !== list.pointer.x || pointer.y !== list.pointer.y);
                                        list.pointer = pointer;
                                        if (moved)
                                            pane.select(row.index);
                                    }
                                    onActivated: mode => root.activate(row.modelData, mode)
                                    onMenu: {
                                        pane.select(row.index);
                                        pane.openActions(row.modelData);
                                    }
                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: Theme.durBase
                                        easing.type: Theme.easeStandard
                                    }
                                }
                            }

                            GridView {
                                id: tiles

                                property point pointer: Qt.point(-1, -1)

                                width: parent.width
                                height: root.grid ? root.listHeight : 0
                                visible: root.grid
                                model: root.grid ? root.shown : []
                                cellWidth: Math.floor(width / Math.floor(width / Theme.launcherTileSize))
                                cellHeight: Theme.launcherTileSize
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                highlightMoveDuration: Theme.durFast
                                currentIndex: 0
                                onModelChanged: pane.syncSelection()

                                highlight: Rectangle {
                                    radius: Theme.radius
                                    color: Theme.selectionFill
                                }

                                delegate: Item {
                                    id: cell

                                    required property var modelData
                                    required property int index

                                    width: tiles.cellWidth
                                    height: tiles.cellHeight

                                    ResultTile {
                                        anchors.centerIn: parent
                                        modelData: cell.modelData
                                        index: cell.index
                                        width: tiles.cellWidth
                                        onHovered: pointer => {
                                            const moved = tiles.pointer.x >= 0 && (pointer.x !== tiles.pointer.x || pointer.y !== tiles.pointer.y);
                                            tiles.pointer = pointer;
                                            if (moved)
                                                pane.select(cell.index);
                                        }
                                        onActivated: mode => root.activate(cell.modelData, mode)
                                        onMenu: {
                                            pane.select(cell.index);
                                            pane.openActions(cell.modelData);
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                height: Theme.launcherRowHeight
                                visible: root.shown.length === 0 && !answer.shown
                                text: {
                                    if (root.mode.busy)
                                        return "Searching…";
                                    if (root.mode !== apps && root.query.trim() === "")
                                        return root.mode.placeholder;
                                    return "No matches";
                                }
                                color: Theme.inkDim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSizeLarge
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Preview {
                            visible: ui.preview
                            width: Theme.launcherPreviewWidth
                            height: Math.max(results.height, Theme.launcherRowHeight * 4)
                            item: pane.current
                        }
                    }

                    Item {
                        width: parent.width
                        height: Theme.launcherHintHeight

                        Text {
                            id: hintLeft

                            anchors {
                                left: parent.left
                                leftMargin: Theme.gap
                                verticalCenter: parent.verticalCenter
                            }
                            width: parent.width - (hintRight.visible ? hintRight.implicitWidth + Theme.padding : 0)
                            text: {
                                if (root.actionsKey !== "")
                                    return "esc back";
                                if (root.mode === apps && root.input === "")
                                    return root.providers.map(p => p.prefix.trim().toLowerCase() === p.name.toLowerCase() ? p.prefix.trim() : `${p.prefix.trim()} ${p.name.toLowerCase()}`).join("   ");
                                return `${root.mode.name.toLowerCase()} · ${root.shown.length} result${root.shown.length === 1 ? "" : "s"}`;
                            }
                            color: Theme.inkDim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
                        }

                        Text {
                            id: hintRight

                            anchors {
                                right: parent.right
                                rightMargin: Theme.gap
                                verticalCenter: parent.verticalCenter
                            }
                            visible: !(root.mode === apps && root.input === "") || ui.grid
                            text: {
                                const enter = root.actionsKey !== "" ? "run" : pane.current?.running && root.mode === apps ? "focus" : root.mode.enterHint;
                                const hints = [`↵ ${enter}`];
                                if (root.mode.altHint && root.actionsKey === "")
                                    hints.push(`⇧↵ ${root.mode.altHint}`);
                                hints.push("^↵ keep open");
                                if (pane.current?.actions?.length && root.actionsKey === "")
                                    hints.push("→ actions");
                                hints.push("alt+1-9");
                                return hints.join("   ");
                            }
                            color: Theme.inkDim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }
            }
        }
    }
}
