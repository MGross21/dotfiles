import QtQuick
import "../components"
import "../config"
import "../services"

MouseArea {
    id: root

    required property var modelData
    required property int index
    property int badge: 0 // Alt+N label; 0 hides it
    property bool reveal: false
    readonly property bool selected: ListView.isCurrentItem
    readonly property bool danger: root.modelData.danger ?? false

    signal activated(string mode)
    signal hovered(point pointer)
    signal menu

    implicitHeight: Theme.launcherRowHeight
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onPositionChanged: mouse => hovered(mapToGlobal(mouse.x, mouse.y))
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            root.menu();
        else if (mouse.button === Qt.MiddleButton || mouse.modifiers & Qt.ShiftModifier)
            root.activated("alt");
        else if (mouse.modifiers & Qt.ControlModifier)
            root.activated("keep");
        else
            root.activated("default");
    }

    opacity: root.reveal ? 0 : 1
    Component.onCompleted: {
        if (root.reveal)
            intro.start();
    }

    SequentialAnimation {
        id: intro

        PauseAnimation {
            duration: root.index * Theme.launcherStagger
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: Theme.durBase
                easing.type: Theme.easeStandard
            }

            NumberAnimation {
                target: content
                property: "x"
                from: 8
                to: 0
                duration: Theme.durBase
                easing.type: Theme.easeStandard
            }
        }
    }

    Item {
        id: content

        width: parent.width
        height: parent.height

        Rectangle {
            x: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 4
            height: root.selected ? 16 : 4
            radius: 2
            visible: root.modelData.running ?? false
            color: Theme.accent

            Behavior on height {
                NumberAnimation {
                    duration: Theme.durFast
                }
            }
        }

        ItemIcon {
            id: icon

            anchors {
                left: parent.left
                leftMargin: Theme.launcherPadding
                verticalCenter: parent.verticalCenter
            }
            item: root.modelData
            size: Theme.launcherIconSize
            color: root.danger ? Theme.accent : Theme.fg
        }

        Column {
            anchors {
                left: icon.right
                leftMargin: Theme.launcherPadding
                right: trail.left
                rightMargin: Theme.launcherPadding
                verticalCenter: parent.verticalCenter
            }

            Text {
                width: parent.width
                text: Fuzzy.highlight(root.modelData.title ?? "", root.modelData.positions, `${Theme.accent}`)
                textFormat: Text.StyledText
                color: root.danger ? Theme.accent : root.selected ? Theme.hi : Theme.fg
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSizeLarge
                font.weight: root.selected ? Font.Bold : Font.Normal
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.modelData.subtitle ?? ""
                color: Theme.inkDim
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Row {
            id: trail

            anchors {
                right: parent.right
                rightMargin: Theme.launcherPadding
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.gap * 2

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.modelData.pinned ?? false
                source: Icons.star
                color: Theme.accent
            }

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.selected && (root.modelData.actions?.length ?? 0) > 0
                source: Icons.next
                color: Theme.inkDim
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.badge > 0
                text: root.badge
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }
        }
    }
}
