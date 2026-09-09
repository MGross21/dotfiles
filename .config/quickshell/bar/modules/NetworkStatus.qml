import QtQuick
import "../components"
import "../config"
import "../popouts"
import "../services"

StatusPill {
    id: root

    icon: Network.icon
    text: Network.label
    tone: Theme.fg
    // Dimming is opacity, never a darker tone: the icon recolor path saturates
    // lightness, so a dim color would come back out bright.
    opacity: Network.connected ? 1.0 : 0.55
    active: popout.visible
    onClicked: popout.toggle()

    NetworkPopout {
        id: popout
        anchorItem: root
    }
}
