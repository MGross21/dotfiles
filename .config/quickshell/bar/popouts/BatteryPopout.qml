import QtQuick
import Quickshell.Services.UPower
import "../components"
import "../config"

Popout {
    id: root

    // UPower's DisplayDevice is an aggregate: it carries percentage and state
    // but reports healthPercentage as 0. The real BAT* device has the health
    // and rate figures, so both are read.
    readonly property UPowerDevice device: UPower.displayDevice
    readonly property UPowerDevice cell: {
        for (const d of UPower.devices.values)
            if (d.isLaptopBattery)
                return d;
        return device;
    }

    // quickshell normalizes percentage to 0..1, unlike UPower's own 0..100.
    readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
    readonly property int state: device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging

    readonly property string status: {
        switch (state) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.Discharging:
            return "Discharging";
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.PendingCharge:
            return "Holding charge";
        case UPowerDeviceState.PendingDischarge:
            return "Pending discharge";
        case UPowerDeviceState.Empty:
            return "Empty";
        default:
            return "Unknown";
        }
    }

    function duration(secs: real): string {
        if (!secs || secs <= 0)
            return "—";
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    Column {
        spacing: 9

        Row {
            spacing: 9

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                size: 22
                source: Icons.battery(root.percent, root.charging)
                color: root.percent <= 15 && !root.charging ? Theme.urgent : root.charging ? Theme.good : Theme.fg
            }

            Column {
                spacing: 0

                Text {
                    text: `${root.percent}%`
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSizeHeading
                    font.bold: true
                }

                Text {
                    text: root.status
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        // Charge bar
        Rectangle {
            width: Theme.popoutWidth
            height: 5
            radius: 2.5
            color: Theme.surface(Theme.trackAlpha)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.percent / 100))
                height: parent.height
                radius: parent.radius
                color: root.percent <= 15 && !root.charging ? Theme.urgent : root.charging ? Theme.good : Theme.accent

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durSlow
                        easing.type: Theme.easeStandard
                    }
                }
            }
        }

        Column {
            spacing: 3

            Repeater {
                model: [
                    {
                        key: root.charging ? "Full in" : "Remaining",
                        value: root.duration(root.charging ? root.device?.timeToFull : root.device?.timeToEmpty)
                    },
                    {
                        key: "Health",
                        value: root.cell?.healthPercentage ? `${Math.round(root.cell.healthPercentage)}%` : "—"
                    },
                    {
                        key: "Draw",
                        value: root.cell?.changeRate ? `${root.cell.changeRate.toFixed(1)} W` : "—"
                    }
                ]

                delegate: Item {
                    id: statRow

                    required property var modelData

                    width: Theme.popoutWidth
                    height: 14

                    Text {
                        anchors.left: parent.left
                        text: statRow.modelData.key
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Text {
                        anchors.right: parent.right
                        text: statRow.modelData.value
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }
    }
}
