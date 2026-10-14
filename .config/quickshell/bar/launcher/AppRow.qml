import QtQuick
import Quickshell
import Quickshell.Widgets
import "../config"

MouseArea {
    id: root

    required property DesktopEntry modelData
    required property int index
    property Scheme scheme
    readonly property bool selected: ListView.isCurrentItem
    readonly property string subtitle: root.modelData.genericName || root.modelData.comment

    signal activated
    signal hovered

    implicitHeight: Theme.launcherRowHeight
    hoverEnabled: true
    onPositionChanged: hovered()
    onClicked: activated()

    IconImage {
        id: icon

        anchors {
            left: parent.left
            leftMargin: Theme.launcherPadding
            verticalCenter: parent.verticalCenter
        }
        implicitSize: Theme.launcherIconSize
        source: Icons.desktopEntry(root.modelData.icon)
        asynchronous: true
    }

    Column {
        anchors {
            left: icon.right
            leftMargin: Theme.launcherPadding
            right: parent.right
            rightMargin: Theme.launcherPadding
            verticalCenter: parent.verticalCenter
        }

        Text {
            width: parent.width
            text: root.modelData.name
            color: root.selected ? root.scheme.inkStrong : root.scheme.ink
            font.family: Theme.font
            font.pixelSize: Theme.fontSizeLarge
            font.weight: root.selected ? Font.Bold : Font.Normal
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: root.scheme.inkDim
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
        }
    }
}
