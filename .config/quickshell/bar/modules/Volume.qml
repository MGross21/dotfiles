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

    onClicked: popout.toggle()
    onWheel: delta => {
        if (!root.sink?.audio)
            return;
        root.sink.audio.volume = Math.max(0, Math.min(1, root.volume + (delta > 0 ? 0.02 : -0.02)));
    }

    // Pipewire objects are unbound by default; without this the volume and
    // muted properties are never populated.
    PwObjectTracker {
        objects: [root.sink]
    }

    AudioPopout {
        id: popout
        anchorItem: root
    }
}
