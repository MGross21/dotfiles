import QtQuick
import Quickshell
import "../config"
import "../services"

// Click-away is the scrim in shell.qml; set grabFocus only for keyboard input.
PopupWindow {
    id: root

    required property Item anchorItem
    default property alias content: holder.data
    property int padding: 12
    // ms timestamp of the last hover-open; toggle() ignores a close right after.
    property real handoffAt: 0

    anchor.item: anchorItem
    anchor.rect.y: (anchorItem?.height ?? 0) + 6
    anchor.rect.width: anchorItem?.width ?? 0
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: holder.implicitWidth + padding * 2
    implicitHeight: holder.implicitHeight + padding * 2
    color: Theme.transparent
    visible: false
    grabFocus: false

    onVisibleChanged: {
        if (visible)
            Popouts.opened(root);
        else
            Popouts.closed(root);
    }

    function toggle(): void {
        if (root.visible && Date.now() - root.handoffAt < 400)
            return;
        root.visible = !root.visible;
    }

    Item {
        id: shell
        anchors.fill: parent

        transform: Scale {
            origin.x: shell.width / 2
            origin.y: 0
            xScale: root.visible ? 1 : 0.92
            yScale: root.visible ? 1 : 0.92

            Behavior on xScale {
                NumberAnimation {
                    duration: Theme.durBase
                    easing.type: Theme.easeStandard
                }
            }
            Behavior on yScale {
                NumberAnimation {
                    duration: Theme.durBase
                    easing.type: Theme.easeStandard
                }
            }
        }

        opacity: root.visible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durFast
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.popoutRadius
            color: Theme.tinted(Theme.base, Theme.popoutAlpha)
            antialiasing: true
        }

        Glass {
            anchors.fill: parent
            radius: Theme.popoutRadius
            alpha: Theme.surfaceAlpha
        }

        Item {
            id: holder
            anchors.fill: parent
            anchors.margins: root.padding
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
