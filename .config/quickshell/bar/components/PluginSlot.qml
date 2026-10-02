import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "../config"
import "../services"

// Plugins can import qs.Ui / qs.Commons only because this file does.
Row {
    id: root

    required property string section

    spacing: Theme.gap

    Repeater {
        model: BarPlugins.entries.filter(e => e.section === root.section)

        Item {
            id: slot

            required property var modelData
            readonly property bool opened: loader.item?.opened === true

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: loader.implicitWidth
            implicitHeight: Theme.contentHeight

            Glass {
                anchors.fill: parent
                radius: height / 2
                alpha: slot.opened ? Theme.surfaceActiveAlpha : hover.hovered ? Theme.surfaceHoverAlpha : 0.0
                rim: slot.opened || hover.hovered
            }

            HoverHandler {
                id: hover
            }

            PluginBarApi {
                id: bar

                // Read by the patched KeyboardPanel.
                property string section: root.section

                pluginId: slot.modelData.id
                moduleName: slot.modelData.id
                foreground: Theme.fg
                barForeground: Theme.fg
                background: Theme.base
                urgent: Theme.urgent
                fontFamily: Theme.font
                barSize: Theme.contentHeight
                layoutConfig: slot.modelData.settings
                _moduleWidgets: id => loader.item ? [loader.item] : []
                _run: command => Quickshell.execDetached(["bash", "-lc", command])
            }

            Loader {
                id: loader

                anchors.verticalCenter: parent.verticalCenter
            }

            Component.onCompleted: loader.setSource(Qt.resolvedUrl(`../plugins/${modelData.id}/${modelData.entry}`), {
                bar: bar,
                moduleName: modelData.id,
                settings: modelData.settings
            })
        }
    }
}
