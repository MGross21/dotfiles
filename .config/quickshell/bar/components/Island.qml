import QtQuick
import Quickshell.Widgets
import "../config"

// Glass stays outside WrapperItem: it adopts its first child as the content.
Item {
    id: root

    default property alias content: wrapper.data
    property real alpha: Theme.surfaceAlpha

    implicitWidth: wrapper.implicitWidth
    implicitHeight: wrapper.implicitHeight

    Glass {
        anchors.fill: parent
        radius: Theme.islandRadius
        alpha: root.alpha
    }

    WrapperItem {
        id: wrapper

        anchors.fill: parent
        margin: Theme.islandPadding
    }
}
