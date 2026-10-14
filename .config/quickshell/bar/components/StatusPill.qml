import QtQuick
import "../config"
import "../services"

Item {
    id: root

    property string icon: ""
    property string text: ""
    property color tone: Theme.fg
    property bool alwaysShowText: false
    property bool active: false
    // Popout opened by Popouts.handoff when hovered.
    property var menu: null

    readonly property bool showText: text !== "" && alwaysShowText

    signal clicked
    signal wheel(int delta)

    implicitHeight: Theme.contentHeight
    implicitWidth: content.implicitWidth + (showText ? 12 : 8)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.durBase
            easing.type: Theme.easeStandard
        }
    }

    Glass {
        anchors.fill: parent
        radius: height / 2
        alpha: root.active ? Theme.surfaceActiveAlpha : hover.hovered ? Theme.surfaceHoverAlpha : 0.0
        rim: root.active || hover.hovered
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: root.showText ? 5 : 0

        Behavior on spacing {
            NumberAnimation {
                duration: Theme.durBase
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            source: root.icon
            color: root.tone
            visible: root.icon !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.tone
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            width: root.showText ? implicitWidth : 0
            clip: true
            opacity: root.showText ? 1 : 0

            Behavior on width {
                NumberAnimation {
                    duration: Theme.durBase
                    easing.type: Theme.easeStandard
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durFast
                }
            }
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: if (hovered)
            Popouts.handoff(root.menu)
    }

    TapHandler {
        onTapped: root.clicked()
    }

    WheelHandler {
        onWheel: event => root.wheel(event.angleDelta.y)
    }
}
