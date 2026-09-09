import QtQuick
import Quickshell
import "../components"
import "../config"
import "../popouts"

StatusPill {
    id: root

    icon: Icons.calendar
    alwaysShowText: true
    active: popout.visible
    // `h` with AP is 12-hour; bare `hh` renders 24-hour.
    text: Qt.formatDateTime(clock.date, "h:mm AP  ·  ddd d MMM")
    onClicked: popout.toggle()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ClockPopout {
        id: popout
        anchorItem: root
    }
}
