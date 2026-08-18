import QtQuick
import Quickshell
import "../components"
import "../config"

// Native StatusNotifierItem menu, rendered with the shell's own surfaces.
// QsMenuOpener exposes the remote menu's children as a live model, so this is
// the real application menu -- not a reimplementation, and not the platform
// popup that item.display() would spawn with unstyled Qt chrome.
Popout {
    id: root

    property var menuHandle: null
    padding: 6

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    Column {
        spacing: 1

        Repeater {
            model: opener.children

            delegate: Item {
                id: entry
                required property QsMenuEntry modelData

                width: Theme.menuWidth
                height: modelData.isSeparator ? 7 : 28

                // Separator
                Rectangle {
                    visible: entry.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 12
                    height: 1
                    color: Theme.surface(Theme.rimAlpha)
                }

                Glass {
                    anchors.fill: parent
                    visible: !entry.modelData.isSeparator
                    radius: 7
                    alpha: entryHover.hovered && entry.modelData.enabled ? Theme.surfaceHoverAlpha : 0.0
                    rim: entryHover.hovered && entry.modelData.enabled
                }

                Row {
                    visible: !entry.modelData.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 9
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    spacing: 8

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 14
                        source: entry.modelData.icon
                        visible: entry.modelData.icon !== ""
                        // App-supplied menu icons are usually already colored.
                        recolor: false
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 40
                        elide: Text.ElideRight
                        text: entry.modelData.text
                        color: entry.modelData.enabled ? Theme.fg : Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                }

                // Checkbox / radio state, when the entry reports one.
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    visible: entry.modelData.buttonType !== QsMenuButtonType.None
                    width: 12
                    height: 12
                    radius: entry.modelData.buttonType === QsMenuButtonType.RadioButton ? 6 : 3
                    color: entry.modelData.checkState === Qt.Checked ? Theme.accent : Theme.transparent
                    border.width: 1
                    border.color: entry.modelData.checkState === Qt.Checked ? Theme.accent : Theme.fgDim
                }

                HoverHandler {
                    id: entryHover
                    enabled: !entry.modelData.isSeparator && entry.modelData.enabled
                }

                TapHandler {
                    enabled: !entry.modelData.isSeparator && entry.modelData.enabled
                    onTapped: {
                        entry.modelData.triggered();
                        root.visible = false;
                    }
                }
            }
        }
    }
}
