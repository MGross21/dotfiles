import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../components"
import "../config"

Popout {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // Unbound pipewire objects expose only a subset of their properties;
    // tracking them is what makes volume and muted readable and writable.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    Column {
        spacing: 12

        Repeater {
            model: [
                {
                    isSink: true
                },
                {
                    isSink: false
                }
            ]

            delegate: Column {
                id: chan
                required property var modelData

                readonly property PwNode node: modelData.isSink ? root.sink : root.source
                readonly property real vol: node?.audio?.volume ?? 0
                readonly property bool muted: node?.audio?.muted ?? false

                spacing: 6
                visible: node !== null

                Row {
                    spacing: 8

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: chan.modelData.isSink ? Icons.volume(chan.vol, chan.muted) : Quickshell.iconPath(chan.muted ? "microphone-disabled-symbolic" : "audio-input-microphone-symbolic")
                        color: chan.muted ? Theme.urgent : Theme.fg

                        TapHandler {
                            onTapped: if (chan.node?.audio)
                                chan.node.audio.muted = !chan.node.audio.muted
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 150
                        elide: Text.ElideRight
                        text: chan.node?.description ?? chan.node?.name ?? ""
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${Math.round(chan.vol * 100)}%`
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                }

                LevelSlider {
                    value: chan.vol
                    tone: chan.muted ? Theme.fgDim : Theme.accent
                    onMoved: v => {
                        if (chan.node?.audio)
                            chan.node.audio.volume = v;
                    }
                }
            }
        }
    }
}
