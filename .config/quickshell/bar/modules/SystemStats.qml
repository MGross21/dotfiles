pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../config"
import "../popouts"
import "../services"

Item {
    id: root

    readonly property var metrics: [
        {
            key: "cpu",
            name: "CPU",
            glyph: "",
            unit: "%",
            min: 0,
            max: 100,
            warnAt: 70,
            critAt: 90
        },
        {
            key: "mem",
            name: "Memory",
            glyph: "",
            unit: "%",
            min: 0,
            max: 100,
            warnAt: 75,
            critAt: 92
        },
        {
            key: "temp",
            name: "Temperature",
            glyph: "",
            unit: "°C",
            min: 30,
            max: 100,
            warnAt: 70,
            critAt: 85
        }
    ]
    readonly property var levels: ({
            cpu: Sensors.cpuUsage,
            mem: Sensors.memUsage,
            temp: Sensors.tempC
        })

    implicitWidth: gauges.implicitWidth + 8
    implicitHeight: Theme.contentHeight

    Glass {
        anchors.fill: parent
        radius: height / 2
        alpha: popout.visible ? Theme.surfaceActiveAlpha : hover.hovered ? Theme.surfaceHoverAlpha : 0.0
        rim: popout.visible || hover.hovered
    }

    Row {
        id: gauges

        anchors.centerIn: parent
        spacing: Theme.gap

        Repeater {
            model: root.metrics

            delegate: Gauge {
                id: gauge

                required property var modelData

                value: root.levels[gauge.modelData.key]
                glyph: gauge.modelData.glyph
                min: gauge.modelData.min
                max: gauge.modelData.max
                warnAt: gauge.modelData.warnAt
                critAt: gauge.modelData.critAt
            }
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: if (hovered)
            Popouts.handoff(popout)
    }

    TapHandler {
        onTapped: popout.toggle()
    }

    SystemPopout {
        id: popout
        anchorItem: root
        metrics: root.metrics
        levels: root.levels
    }
}
