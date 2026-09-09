import QtQuick
import Quickshell.Services.SystemTray
import "../components"
import "../config"
import "../popouts"

Row {
    id: root

    spacing: 2

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry
            required property SystemTrayItem modelData

            width: 22
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            Glass {
                anchors.fill: parent
                radius: 7
                alpha: trayHover.hovered ? Theme.surfaceHoverAlpha : 0.0
                rim: trayHover.hovered
            }

            Icon {
                anchors.centerIn: parent
                size: 15
                source: entry.modelData.icon
                // Application icons carry their own color.
                recolor: false
                opacity: trayHover.hovered ? 1.0 : 0.9
            }

            // Right-click (or left-click on menu-only items) opens the real
            // application menu, styled by the shell instead of Qt's platform popup.
            TrayMenu {
                id: menu
                anchorItem: entry
                menuHandle: entry.modelData.menu
            }

            HoverHandler {
                id: trayHover
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onTapped: event => {
                    const item = entry.modelData;
                    if (event.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (event.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu)
                            menu.toggle();
                    } else {
                        item.activate();
                    }
                }
            }

            WheelHandler {
                onWheel: event => entry.modelData.scroll(event.angleDelta.y, false)
            }
        }
    }
}
