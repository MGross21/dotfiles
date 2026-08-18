import QtQuick
import "../config"

// Icon-first module. The text label is collapsed by default and expands on
// hover, so the bar stays dense but nothing is hidden.
Item {
    id: root

    property string icon: ""
    property string text: ""
    property color tone: Theme.fg
    property bool expanded: false
    property bool alwaysShowText: false
    property bool active: false

    readonly property bool showText: text !== "" && (alwaysShowText || expanded || hover.hovered || active)

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
            // Width animates rather than visibility toggling, so the island
            // morphs instead of snapping.
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
    }

    TapHandler {
        onTapped: root.clicked()
    }

    WheelHandler {
        onWheel: event => root.wheel(event.angleDelta.y)
    }
}
