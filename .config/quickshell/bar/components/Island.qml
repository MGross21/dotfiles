import QtQuick
import Quickshell.Widgets
import "../config"

// A floating cluster of modules. Glass is a sibling of the content wrapper
// rather than the wrapper itself: WrapperItem adopts its first child as the
// content, so a background declared inside it would be taken for one.
Item {
    id: root

    default property alias content: wrapper.data
    property real alpha: Theme.surfaceAlpha

    // WrapperItem's implicit size comes from its content, not from the width it
    // is given, so this is not a loop.
    implicitWidth: wrapper.implicitWidth
    implicitHeight: wrapper.implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.durBase
            easing.type: Theme.easeStandard
        }
    }

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
