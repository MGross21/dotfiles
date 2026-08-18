//@ pragma IconTheme Adwaita

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "components"
import "config"
import "modules"

// Adwaita rather than the desktop's Papirus: Papirus ships no *-symbolic
// variants, so every status icon would resolve to a missing texture.
ShellRoot {
    id: shell

    property bool barVisible: true

    IpcHandler {
        target: "bar"

        function toggle(): void {
            shell.barVisible = !shell.barVisible;
        }

        // Not `show` -- that collides with the `qs ipc show` subcommand.
        function reveal(): void {
            shell.barVisible = true;
        }

        function hide(): void {
            shell.barVisible = false;
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
            // OnDemand so the wifi password field can receive keys; with None
            // the layer surface never takes keyboard focus.
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                left: true
                right: true
            }

            // The bar floats: the window is taller than the visible islands and
            // fully transparent, so the islands read as detached from the edge.
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

                Clock {}
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

                    Tray {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Separator {}

                    SystemStats {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Separator {}

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
