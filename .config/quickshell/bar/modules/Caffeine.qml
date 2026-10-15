import QtQuick
import "../components"
import "../config"
import "../services"

StatusPill {
    icon: Icons.caffeine
    tone: IdleInhibit.enabled ? Theme.accent : Theme.fgDim
    active: IdleInhibit.enabled
    onClicked: IdleInhibit.enabled = !IdleInhibit.enabled
}
