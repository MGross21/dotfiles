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
    // Dim via opacity: icon recolor saturates lightness, undoing a darker tone.
    opacity: Network.connected ? 1.0 : 0.55
    active: popout.visible
    menu: popout
    onClicked: popout.toggle()

    NetworkPopout {
        id: popout
        anchorItem: root
    }
}
