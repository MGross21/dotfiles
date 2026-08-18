import QtQuick
import "../components"
import "../config"
import "../services"

// cpu / memory / temperature as arc gauges. Adwaita ships no symbolic icons for
// any of the three, and the value carries more than a glyph would.
Row {
    id: root

    spacing: Theme.gap

    Gauge {
        anchors.verticalCenter: parent.verticalCenter
        value: Sensors.cpuUsage
        warnAt: 70
        critAt: 90
    }

    Gauge {
        anchors.verticalCenter: parent.verticalCenter
        value: Sensors.memUsage
        warnAt: 75
        critAt: 92
    }

    Gauge {
        anchors.verticalCenter: parent.verticalCenter
        value: Sensors.tempC
        warnAt: 70
        critAt: 85
    }
}
