import QtQuick
import Quickshell.Io
import "../components"
import "../config"

Popout {
    id: root

    Column {
        spacing: 2

        Process {
            id: proc
        }

        Repeater {
            model: [
                {
                    label: "Lock",
                    icon: Icons.lock,
                    cmd: ["hyprlock"],
                    danger: false
                },
                {
                    label: "Suspend",
                    icon: Icons.suspend,
                    cmd: ["systemctl", "suspend"],
                    danger: false
                },
                {
                    label: "Reboot",
                    icon: Icons.reboot,
                    cmd: ["systemctl", "reboot"],
                    danger: true
                },
                {
                    label: "Shut down",
                    icon: Icons.shutdown,
                    cmd: ["systemctl", "poweroff"],
                    danger: true
                }
            ]

            delegate: Item {
                id: row
                required property var modelData

                width: Theme.menuWidth
                height: 32

                Glass {
                    anchors.fill: parent
                    radius: 8
                    alpha: rowHover.hovered ? Theme.surfaceHoverAlpha : 0.0
                    rim: rowHover.hovered
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 10

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: row.modelData.icon
                        color: row.modelData.danger && rowHover.hovered ? Theme.urgent : Theme.fg
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.label
                        color: row.modelData.danger && rowHover.hovered ? Theme.urgent : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                }

                HoverHandler {
                    id: rowHover
                }

                TapHandler {
                    onTapped: {
                        proc.command = row.modelData.cmd;
                        proc.startDetached();
                        root.visible = false;
                    }
                }
            }
        }
    }
}
