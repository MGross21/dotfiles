import QtQuick
import qs.Commons
import "services"

Item {
    id: root

    property var shell: null
    property var manifest: null

    ShellIpc {
        target: "caffeine"

        function toggle(): string {
            IdleInhibit.enabled = !IdleInhibit.enabled;
            return IdleInhibit.enabled ? "on" : "off";
        }

        function isOn(): string {
            return IdleInhibit.enabled ? "on" : "off";
        }
    }
}
