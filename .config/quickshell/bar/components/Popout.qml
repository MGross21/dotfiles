import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../config"

// Base dropdown. Dismissal uses hyprland_focus_grab_v1 via HyprlandFocusGrab
// rather than a full-screen click-catcher layer -- the compositor tells us when
// the user clicked away, so the popup never has to steal input from the desktop.
PopupWindow {
    id: root

    required property Item anchorItem
    default property alias content: holder.data
    property int padding: 12

    anchor.item: anchorItem
    anchor.rect.y: (anchorItem?.height ?? 0) + 6
    anchor.gravity: Edges.Bottom

    implicitWidth: holder.implicitWidth + padding * 2
    implicitHeight: holder.implicitHeight + padding * 2
    color: Theme.transparent
    visible: false

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    Item {
        id: shell
        anchors.fill: parent

        // Grow-in from the anchor edge. The window itself cannot animate its
        // size, so the surface scales inside it.
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

        Glass {
            anchors.fill: parent
            radius: Theme.popoutRadius
            alpha: Theme.surfaceHoverAlpha
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
