import QtQuick
import "../components"
import "../config"
import "../services"

Popout {
    id: root

    property string pendingSsid: ""

    onVisibleChanged: {
        if (visible)
            Network.rescan();
        else
            pendingSsid = "";
    }

    Column {
        spacing: 8

        // ── header: current connection ─────────────────────────────────
        Row {
            spacing: 9

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                size: 22
                source: Network.icon
                color: Network.connected ? Theme.accent : Theme.fg
                opacity: Network.connected ? 1.0 : 0.5
            }

            Column {
                spacing: 0
                width: 150

                Text {
                    text: Network.label
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: Network.ipAddress || (Network.wifiEnabled ? "Not connected" : "Radio disabled")
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            // Radio toggle
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 18

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Network.wifiEnabled ? Theme.accent : Theme.surface(Theme.trackAlpha)

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durBase
                        }
                    }
                }

                Rectangle {
                    y: 3
                    x: Network.wifiEnabled ? parent.width - width - 3 : 3
                    width: 12
                    height: 12
                    radius: 6
                    color: Network.wifiEnabled ? Theme.base : Theme.fgDim

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.durBase
                            easing.type: Theme.easeStandard
                        }
                    }
                }

                TapHandler {
                    onTapped: Network.toggleWifi()
                }
            }
        }

        Rectangle {
            width: Theme.listWidth
            height: 1
            color: Theme.surface(Theme.rimAlpha)
        }

        // ── available networks ─────────────────────────────────────────
        Column {
            spacing: 1
            visible: Network.wifiEnabled

            Repeater {
                // Cap the list: a busy area can return dozens of APs and the
                // popup would run off the screen.
                model: Network.networks.slice(0, 8)

                delegate: Column {
                    id: netRow
                    required property var modelData

                    readonly property bool isPending: root.pendingSsid === modelData.ssid

                    spacing: 0

                    Item {
                        width: Theme.listWidth
                        height: 28

                        Glass {
                            anchors.fill: parent
                            radius: 7
                            alpha: netHover.hovered || netRow.modelData.active ? Theme.surfaceHoverAlpha : 0.0
                            rim: netHover.hovered
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            spacing: 8

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 14
                                source: Icons.wifi(netRow.modelData.signal, true, true)
                                color: netRow.modelData.active ? Theme.accent : Theme.fg
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 150
                                elide: Text.ElideRight
                                text: netRow.modelData.ssid
                                color: netRow.modelData.active ? Theme.accent : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.bold: netRow.modelData.active
                            }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            spacing: 5

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 10
                                source: Icons.locked
                                color: Theme.fg
                                opacity: 0.5
                                visible: netRow.modelData.security !== ""
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: `${netRow.modelData.signal}`
                                color: Theme.fgDim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }

                        HoverHandler {
                            id: netHover
                        }

                        TapHandler {
                            onTapped: {
                                const n = netRow.modelData;
                                if (n.active) {
                                    Network.disconnect(n.ssid);
                                } else if (n.saved || n.security === "") {
                                    Network.connect(n.ssid, "");
                                    root.visible = false;
                                } else {
                                    // Unsaved and secured: ask for the key inline
                                    // rather than silently failing.
                                    root.pendingSsid = root.pendingSsid === n.ssid ? "" : n.ssid;
                                }
                            }
                        }
                    }

                    // Inline password entry for unsaved secured networks.
                    Item {
                        width: Theme.listWidth
                        height: netRow.isPending ? 30 : 0
                        clip: true
                        visible: height > 0

                        Behavior on height {
                            NumberAnimation {
                                duration: Theme.durBase
                                easing.type: Theme.easeStandard
                            }
                        }

                        Glass {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 7
                            alpha: Theme.surfaceAlpha
                        }

                        TextInput {
                            id: pwInput
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 40
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            focus: netRow.isPending
                            onAccepted: {
                                Network.connect(netRow.modelData.ssid, text);
                                text = "";
                                root.pendingSsid = "";
                                root.visible = false;
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "password  ↵"
                                color: Theme.fgDim
                                font: parent.font
                                visible: pwInput.text === ""
                            }
                        }
                    }
                }
            }
        }
    }
}
