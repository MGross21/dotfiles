import QtQuick
import "../config"

MouseArea {
    id: root

    required property var modelData
    required property int index
    readonly property bool selected: GridView.isCurrentItem

    signal activated(string mode)
    signal hovered(point pointer)
    signal menu

    width: Theme.launcherTileSize
    height: Theme.launcherTileSize
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onPositionChanged: mouse => hovered(mapToGlobal(mouse.x, mouse.y))
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            root.menu();
        else
            root.activated(mouse.button === Qt.MiddleButton || mouse.modifiers & Qt.ShiftModifier ? "alt" : "default");
    }

    ItemIcon {
        id: icon

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Theme.launcherPadding
        }
        item: root.modelData
        size: Theme.launcherTileIconSize
        color: Theme.fg
    }

    Rectangle {
        anchors {
            horizontalCenter: icon.horizontalCenter
            top: icon.bottom
            topMargin: 2
        }
        width: 4
        height: 4
        radius: 2
        visible: root.modelData.running ?? false
        color: Theme.accent
    }

    Text {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Theme.gap
        }
        text: root.modelData.title ?? ""
        color: root.selected ? Theme.hi : Theme.fg
        font.family: Theme.fontSans
        font.pixelSize: Theme.fontSize
        font.weight: root.selected ? Font.Bold : Font.Normal
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }
}
