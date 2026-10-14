import QtQuick
import Quickshell
import Quickshell.Wayland

// Emits the mean linear luminance of `region` (screen coordinates).
Item {
    id: root

    required property ShellScreen screen
    required property rect region
    readonly property size probeSize: Qt.size(64, 36)
    property var grab

    signal measured(real luminance)

    function _linear(v: int): real {
        const c = v / 255;
        return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    }

    x: -width
    width: probeSize.width
    height: probeSize.height

    ScreencopyView {
        id: capture

        anchors.fill: parent
        captureSource: root.screen
        onHasContentChanged: {
            if (capture.hasContent)
                capture.grabToImage(result => root.grab = result, root.probeSize);
        }
    }

    Image {
        id: snapshot

        anchors.fill: parent
        source: root.grab?.url ?? ""
        cache: false
        onStatusChanged: {
            if (status === Image.Ready)
                canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        renderTarget: Canvas.Image
        onPaint: {
            if (snapshot.status !== Image.Ready)
                return;
            const ctx = getContext("2d");
            ctx.drawImage(snapshot, 0, 0, width, height);

            const sx = width / root.screen.width;
            const sy = height / root.screen.height;
            const px = ctx.getImageData(Math.floor(root.region.x * sx), Math.floor(root.region.y * sy), Math.max(1, Math.ceil(root.region.width * sx)), Math.max(1, Math.ceil(root.region.height * sy))).data;

            let sum = 0;
            for (let i = 0; i < px.length; i += 4)
                sum += 0.2126 * root._linear(px[i]) + 0.7152 * root._linear(px[i + 1]) + 0.0722 * root._linear(px[i + 2]);
            root.measured(sum / (px.length / 4));
        }
    }
}
