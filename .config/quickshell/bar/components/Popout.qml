import QtQuick
import Quickshell
import "../config"

// Base dropdown. grabFocus is quickshell's xdg-popup grab: dismisses on an
// outside click, and that click is consumed -- so opening a different pill's
// popout takes a second click.
PopupWindow {
    id: root

    required property Item anchorItem
    default property alias content: holder.data
    property int padding: 12

    // The anchor rect spans the invoking item's full width, so the popup centers
    // under it instead of under its left edge -- without the width the anchor
    // point is a zero-width box at x=0 and a wide popup hangs off to the right.
    // SlideX then pulls the right-hand popouts back on screen when centering
    // would overflow the edge.
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
    grabFocus: true

    function toggle(): void {
        root.visible = !root.visible;
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

        // Opaque backing: popouts float over app windows, where the bar's
        // translucent wash is unreadable. Glass supplies the edge on top.
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
