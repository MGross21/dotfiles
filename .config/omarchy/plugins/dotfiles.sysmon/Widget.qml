pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "services"

Panel {
    id: root
    moduleName: "dotfiles.sysmon"

    readonly property color fg: root.barForeground
    readonly property color crit: bar ? bar.urgent : Commons.Color.urgent
    readonly property color dim: Qt.alpha(root.fg, 0.6)

    readonly property var metrics: ({
            cpu: {
                name: "CPU",
                glyph: "",
                unit: "%",
                level: Sensors.cpu,
                history: Sensors.cpuHistory,
                min: 0,
                max: 100,
                critAt: 90,
                detail: `load  ${Sensors.loadAvg}`,
                live: true
            },
            mem: {
                name: "Memory",
                glyph: "",
                unit: "%",
                level: Sensors.mem,
                history: Sensors.memHistory,
                min: 0,
                max: 100,
                critAt: 92,
                detail: `${Sensors.memUsedGib.toFixed(1)} / ${Sensors.memTotalGib.toFixed(1)} GiB` + (Sensors.swapUsedGib >= 0.1 ? `  ·  swap ${Sensors.swapUsedGib.toFixed(1)} GiB` : ""),
                live: true
            },
            temp: {
                name: "Temperature",
                glyph: "",
                unit: "°C",
                level: Sensors.temp,
                history: Sensors.tempHistory,
                min: 30,
                max: 100,
                critAt: 85,
                detail: "CPU package",
                live: true
            },
            gpu: {
                name: "GPU",
                glyph: "󰢮",
                unit: "%",
                level: Sensors.gpu,
                history: Sensors.gpuHistory,
                min: 0,
                max: 100,
                critAt: 95,
                detail: !Sensors.gpuAwake ? "asleep" : `${Sensors.gpuTemp}°C  ·  ${Sensors.vramUsedGib.toFixed(1)} / ${Sensors.vramTotalGib.toFixed(1)} GiB` + (isNaN(Sensors.gpuWatts) ? "" : `  ·  ${Sensors.gpuWatts.toFixed(0)} W`),
                live: Sensors.gpuAwake
            }
        })

    readonly property var panelKeys: ["cpu", "mem", "temp"].concat(Sensors.dgpu !== "" ? ["gpu"] : [])

    function tone(m: var): color {
        if (!m.live)
            return root.dim;
        if (m.level >= m.critAt)
            return root.crit;
        return root.fg;
    }

    onOpenedChanged: Sensors.viewers += opened ? 1 : -1
    Component.onDestruction: if (opened)
        Sensors.viewers -= 1

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "󰐰"
        tooltipText: ""
        onPressed: b => b === Qt.RightButton ? root.bar.run("uwsm app -- ghostty -e btop") : root.toggle()
    }

    KeyboardPanel {
        id: panel
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: panel.loadedContent
        contentWidth: panel.fittedContentWidth(Style.space(300))
        contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

        content: PanelKeyCatcher {
            anchors.fill: parent
            implicitHeight: column.implicitHeight
            onCloseRequested: root.close()
            onTabRequested: direction => root.switchPanel(direction)

            Column {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Style.space(14)

                Repeater {
                    model: root.panelKeys

                    Column {
                        id: stat
                        required property string modelData
                        readonly property var m: root.metrics[modelData]
                        readonly property color tone: root.tone(m)
                        width: column.width
                        spacing: Style.space(4)

                        Item {
                            width: parent.width
                            height: value.implicitHeight

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Style.space(6)

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: stat.m.glyph
                                    color: stat.tone
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.title
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: stat.m.name
                                    color: root.fg
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.body
                                }
                            }

                            Text {
                                id: value
                                anchors.right: parent.right
                                text: stat.m.live ? `${stat.m.level}${stat.m.unit}` : "—"
                                color: stat.tone
                                font.family: Style.font.family
                                font.pixelSize: Style.font.title
                                font.bold: true
                            }
                        }

                        Sparkline {
                            width: parent.width
                            height: Style.space(26)
                            visible: stat.m.live
                            values: stat.m.history
                            capacity: Sensors.historyLength
                            min: stat.m.min
                            max: stat.m.max
                            color: stat.tone
                        }

                        Row {
                            visible: stat.modelData === "cpu" && Sensors.cores.length > 0
                            width: parent.width
                            height: Style.space(14)
                            spacing: Style.space(2)

                            Repeater {
                                model: Sensors.cores

                                Item {
                                    id: core
                                    required property int modelData
                                    width: (parent.width - parent.spacing * (Sensors.cores.length - 1)) / Sensors.cores.length
                                    height: parent.height

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Style.space(1)
                                        color: Qt.alpha(root.fg, 0.08)
                                    }

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: Math.max(1, parent.height * core.modelData / 100)
                                        radius: Style.space(1)
                                        color: root.tone(Object.assign({}, root.metrics.cpu, {
                                            level: core.modelData
                                        }))
                                    }
                                }
                            }
                        }

                        Text {
                            text: stat.m.detail
                            color: root.dim
                            font.family: Style.font.family
                            font.pixelSize: Style.font.caption
                        }
                    }
                }
            }
        }
    }
}
