//@ pragma IconTheme Adwaita

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "components"
import "config"
import "launcher"
import "modules"
import "services"

ShellRoot {
    id: shell

    property bool barVisible: true

    IpcHandler {
        target: "bar"

        function toggle(): void {
            shell.barVisible = !shell.barVisible;
        }

        // `show` collides with the `qs ipc show` subcommand.
        function reveal(): void {
            shell.barVisible = true;
        }

        function hide(): void {
            shell.barVisible = false;
        }
    }

    Launcher {}

    // Popout click-away. Normal exclusion keeps it out of the bar's zone.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            visible: Popouts.current !== null
            color: Theme.transparent

            WlrLayershell.namespace: "quickshell-popout-scrim"
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: Popouts.close()
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property ShellScreen modelData

            screen: modelData
            visible: shell.barVisible

            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Theme.barHeight + Theme.barMargin
            exclusiveZone: Theme.barHeight + Theme.barMargin
            color: Theme.transparent

            Island {
                anchors {
                    left: parent.left
                    leftMargin: Theme.barMargin
                    top: parent.top
                    topMargin: Theme.barMargin / 2
                }

                Row {
                    spacing: Theme.gap * 2

                    PluginSlot {
                        section: "left"
                    }

                    Workspaces {
                        anchors.verticalCenter: parent.verticalCenter
                        monitor: Hyprland.monitorFor(bar.modelData)
                    }

                    Separator {
                        visible: activeWindow.appId !== ""
                    }

                    ActiveWindow {
                        id: activeWindow

                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Island {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: Theme.barMargin / 2
                }

                Row {
                    spacing: Theme.gap

                    PluginSlot {
                        section: "center"
                    }

                    Clock {}
                }
            }

            Island {
                anchors {
                    right: parent.right
                    rightMargin: Theme.barMargin
                    top: parent.top
                    topMargin: Theme.barMargin / 2
                }

                Row {
                    spacing: Theme.gap

                    PluginSlot {
                        section: "right"
                    }

                    Tray {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Separator {}

                    SystemStats {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Separator {}

                    Caffeine {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Volume {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    NetworkStatus {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Battery {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Power {
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
