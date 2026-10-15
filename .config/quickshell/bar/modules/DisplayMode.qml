import QtQuick
import "../components"
import "../config"
import "../services"

StatusPill {
    visible: Displays.count > 1
    icon: Displays.mirrored ? Icons.displayMirror : Icons.displayExtend
    tone: Displays.mirrored ? Theme.accent : Theme.fg
    active: Displays.mirrored
    onClicked: Displays.toggle()

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: Displays.arrange()
    }
}
