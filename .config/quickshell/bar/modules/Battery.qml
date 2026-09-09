import QtQuick
import Quickshell.Services.UPower
import "../components"
import "../config"
import "../popouts"

StatusPill {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    // quickshell reports percentage on a 0..1 scale, unlike UPower's own 0..100.
    readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
    // Charge state, not AC presence: with TLP charge thresholds the machine
    // sits on AC reporting FullyCharged, which is not "charging".
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
    readonly property bool low: device?.state === UPowerDeviceState.Discharging && percent <= 15

    visible: device?.isLaptopBattery ?? false
    icon: Icons.battery(percent, charging)
    text: `${percent}%`
    tone: low ? Theme.urgent : Theme.fg
    active: popout.visible
    onClicked: popout.toggle()

    BatteryPopout {
        id: popout
        anchorItem: root
    }
}
