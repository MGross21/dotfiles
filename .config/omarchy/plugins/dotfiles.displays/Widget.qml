pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
    id: root
    moduleName: "dotfiles.displays"

    readonly property var modes: [
        {
            id: "extend",
            name: "Extend",
            glyph: "󰍺"
        },
        {
            id: "present",
            name: "Mirror",
            glyph: "󱒃"
        },
        {
            id: "internal",
            name: "Laptop",
            glyph: "󰌢"
        },
        {
            id: "external",
            name: "External",
            glyph: "󰍹"
        }
    ]

    // "single" while no external display is connected.
    property string mode: "single"
    readonly property var current: modes.find(m => m.id === mode) ?? modes[0]

    function refresh(): void {
        if (!statusProc.running)
            statusProc.running = true;
    }

    function apply(id: string): void {
        Quickshell.execDetached(["display-mode", id]);
        settle.restart();
    }

    visible: mode !== "single"
    implicitWidth: visible ? button.implicitWidth : 0
    implicitHeight: visible ? button.implicitHeight : 0

    Component.onCompleted: refresh()
    onOpenedChanged: if (opened)
        refresh()

    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name.startsWith("monitor"))
                settle.restart();
        }
    }

    Timer {
        id: settle
        interval: 600
        onTriggered: root.refresh()
    }

    Process {
        id: statusProc
        command: ["display-mode", "status"]
        stdout: StdioCollector {
            onStreamFinished: root.mode = text.trim() || "single"
        }
    }

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.current.glyph
        tooltipText: ""
        onPressed: b => b === Qt.RightButton ? root.apply("toggle") : root.toggle()
    }

    KeyboardPanel {
        id: panel
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened && root.visible
        focusTarget: panel.loadedContent
        contentWidth: panel.fittedContentWidth(Style.space(320))
        contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

        content: PanelKeyCatcher {
            anchors.fill: parent
            implicitHeight: column.implicitHeight
            onCloseRequested: root.close()
            onTabRequested: direction => root.switchPanel(direction)

            Column {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Style.space(10)

                PanelSectionHeader {
                    text: "Displays"
                    foreground: root.bar.foreground
                    fontFamily: root.bar.fontFamily
                }

                Row {
                    id: modeRow
                    width: parent.width
                    spacing: Style.space(6)
                    readonly property real cellWidth: (width - spacing * (root.modes.length - 1)) / root.modes.length

                    Repeater {
                        model: root.modes

                        Button {
                            required property var modelData
                            width: modeRow.cellWidth
                            iconText: modelData.glyph
                            iconSize: Style.font.title
                            text: modelData.name
                            fontSize: Style.font.bodySmall
                            foreground: root.bar.foreground
                            fontFamily: root.bar.fontFamily
                            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                            bordered: true
                            active: root.mode === modelData.id
                            onClicked: root.apply(modelData.id)
                        }
                    }
                }

                PanelSeparator {
                    foreground: root.bar.foreground
                }

                Button {
                    width: parent.width
                    iconText: "󱄄"
                    text: "Arrange displays"
                    leftAlign: true
                    foreground: root.bar.foreground
                    fontFamily: root.bar.fontFamily
                    onClicked: {
                        root.close();
                        root.bar.run("uwsm app -- wdisplays");
                    }
                }
            }
        }
    }
}
