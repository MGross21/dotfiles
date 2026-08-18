import QtQuick
import Quickshell.Hyprland
import "../config"

// Focused workspace stretches into a pill; the rest stay dots. Width animates,
// so switching reads as one shape moving rather than boxes blinking.
Row {
    id: root

    required property var monitor

    spacing: 4

    Repeater {
        model: Hyprland.workspaces

        delegate: Item {
            id: ws
            required property HyprlandWorkspace modelData

            readonly property bool here: !root.monitor || modelData.monitor === root.monitor
            readonly property bool isFocused: modelData.focused

            visible: here
            width: !here ? 0 : isFocused ? 26 : modelData.active || wsHover.hovered ? 14 : 8
            height: 8
            anchors.verticalCenter: parent.verticalCenter

            Behavior on width {
                NumberAnimation {
                    duration: Theme.durBase
                    easing.type: Theme.easeEmphasized
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                antialiasing: true
                color: ws.modelData.urgent ? Theme.urgent : ws.isFocused ? Theme.accent : ws.modelData.active ? Theme.fgDim : Theme.surface(Theme.trackAlpha)

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durBase
                    }
                }
            }

            HoverHandler {
                id: wsHover
            }

            TapHandler {
                onTapped: ws.modelData.activate()
            }
        }
    }
}
