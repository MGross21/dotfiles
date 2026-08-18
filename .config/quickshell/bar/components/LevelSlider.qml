import QtQuick
import "../config"

// Hand-rolled rather than QtQuick.Controls.Slider: Controls needs a style
// backend to look like anything, and this shell paints its own surfaces.
Item {
    id: root

    property real value: 0        // 0..1
    property color tone: Theme.accent
    signal moved(real value)

    implicitWidth: 160
    implicitHeight: 20

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surface(0.18)

        Rectangle {
            id: fill
            width: Math.max(height, track.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: parent.radius
            color: root.tone

            Behavior on width {
                enabled: !drag.active
                NumberAnimation {
                    duration: Theme.durFast
                }
            }
        }
    }

    Rectangle {
        id: handle
        x: fill.width - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: hover.hovered || drag.active ? 14 : 10
        height: width
        radius: width / 2
        color: Theme.fg
        border.width: 2
        border.color: root.tone

        Behavior on width {
            NumberAnimation {
                duration: Theme.durFast
            }
        }
    }

    HoverHandler {
        id: hover
    }

    DragHandler {
        id: drag
        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        onCentroidChanged: if (active)
            root.moved(Math.max(0, Math.min(1, centroid.position.x / root.width)))
    }

    TapHandler {
        onTapped: event => root.moved(Math.max(0, Math.min(1, event.position.x / root.width)))
    }
}
