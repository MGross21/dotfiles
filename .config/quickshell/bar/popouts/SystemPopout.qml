pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../config"
import "../services"

Popout {
    id: root

    required property var metrics
    required property var levels

    readonly property var histories: ({
            cpu: Sensors.cpuHistory,
            mem: Sensors.memHistory,
            temp: Sensors.tempHistory
        })
    readonly property var details: ({
            cpu: `load  ${Sensors.loadAvg}`,
            mem: `${Sensors.memUsedGb.toFixed(1)} / ${Sensors.memTotalGb.toFixed(1)} GB`,
            temp: Sensors.tempSensor
        })

    Column {
        spacing: 12

        Repeater {
            model: root.metrics

            delegate: Column {
                id: stat

                required property var modelData
                readonly property real level: root.levels[stat.modelData.key]
                readonly property color tone: Theme.severity(stat.level, stat.modelData.warnAt, stat.modelData.critAt)

                spacing: 3

                Item {
                    width: Theme.popoutWidth
                    height: valueText.implicitHeight

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: stat.modelData.glyph
                            color: stat.tone
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSizeLarge
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: stat.modelData.name
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    Text {
                        id: valueText
                        anchors.right: parent.right
                        text: `${stat.level}${stat.modelData.unit}`
                        color: stat.tone
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                    }
                }

                Sparkline {
                    width: Theme.popoutWidth
                    height: 26
                    values: root.histories[stat.modelData.key]
                    capacity: Sensors.historyLength
                    min: stat.modelData.min
                    max: stat.modelData.max
                    color: stat.tone
                }

                Text {
                    text: root.details[stat.modelData.key]
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSizeSmall
                    visible: text !== ""
                }
            }
        }
    }
}
