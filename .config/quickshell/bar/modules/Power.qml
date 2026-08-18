import QtQuick
import "../components"
import "../config"
import "../popouts"

StatusPill {
    id: root

    icon: Icons.shutdown
    tone: popout.visible ? Theme.urgent : Theme.fg
    active: popout.visible
    onClicked: popout.visible = !popout.visible

    PowerPopout {
        id: popout
        anchorItem: root
    }
}
