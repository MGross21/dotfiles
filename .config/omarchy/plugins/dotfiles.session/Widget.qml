pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
    id: root
    moduleName: "dotfiles.session"

    readonly property var actions: [
        {
            id: "lock",
            name: "Lock",
            glyph: "󰌾",
            argv: ["idlectl", "lock"]
        },
        {
            id: "suspend",
            name: "Suspend",
            glyph: "󰤄",
            argv: ["systemctl", "suspend"]
        },
        {
            id: "logout",
            name: "Log out",
            glyph: "󰍃",
            argv: ["uwsm", "stop"],
            danger: true
        },
        {
            id: "reboot",
            name: "Reboot",
            glyph: "󰜉",
            argv: ["systemctl", "reboot"],
            danger: true
        },
        {
            id: "shutdown",
            name: "Shut down",
            glyph: "󰐥",
            argv: ["systemctl", "poweroff"],
            danger: true
        }
    ]

    // Id of the dangerous action awaiting a second click.
    property string armed: ""
    readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent

    function run(action: var): void {
        if (action.danger && armed !== action.id) {
            armed = action.id;
            return;
        }
        armed = "";
        close();
        Quickshell.execDetached(action.argv);
    }

    onOpenedChanged: armed = ""

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "󰐥"
        tooltipText: ""
        onPressed: root.toggle()
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    KeyboardPanel {
        id: panel
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: panel.loadedContent
        contentWidth: panel.fittedContentWidth(Style.space(220))
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
                spacing: Style.space(4)

                PanelSectionHeader {
                    text: "Session"
                    foreground: root.bar.foreground
                    fontFamily: root.bar.fontFamily
                }

                Repeater {
                    model: root.actions

                    Button {
                        required property var modelData
                        readonly property bool armed: root.armed === modelData.id
                        width: column.width
                        iconText: modelData.glyph
                        text: armed ? `${modelData.name}? Click again` : modelData.name
                        leftAlign: true
                        foreground: armed ? root.urgent : root.bar.foreground
                        accent: root.urgent
                        active: armed
                        fontFamily: root.bar.fontFamily
                        onClicked: root.run(modelData)
                    }
                }
            }
        }
    }
}
