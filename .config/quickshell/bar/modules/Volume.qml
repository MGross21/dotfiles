import QtQuick
import Quickshell.Services.Pipewire
import "../components"
import "../config"
import "../popouts"

StatusPill {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    icon: Icons.volume(volume, muted)
    text: `${Math.round(volume * 100)}%`
    tone: muted ? Theme.urgent : Theme.fg
    active: popout.visible
    menu: popout

    onClicked: popout.toggle()
    onWheel: delta => {
        if (!root.sink?.audio)
            return;
        root.sink.audio.volume = Math.max(0, Math.min(1, root.volume + (delta > 0 ? 0.02 : -0.02)));
    }

    // Unbound Pipewire nodes never populate volume or muted.
    PwObjectTracker {
        objects: [root.sink]
    }

    AudioPopout {
        id: popout
        anchorItem: root
    }
}
