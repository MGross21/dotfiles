import QtQuick
import "../config"

// Plots against the fixed min..max scale, not one fitted to the samples.
Canvas {
    id: root

    property var values: []
    // Sample slots across the width; newest sample sits at the right edge.
    property int capacity: values.length
    property real min: 0
    property real max: 100
    property color color: Theme.accent

    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const n = values.length;
        if (n < 2)
            return;

        const step = width / (Math.max(capacity, n) - 1);
        const x0 = width - (n - 1) * step;
        const y = v => height - 1 - Math.max(0, Math.min(1, (v - min) / (max - min))) * (height - 2);

        ctx.beginPath();
        ctx.moveTo(x0, y(values[0]));
        for (let i = 1; i < n; i++)
            ctx.lineTo(x0 + i * step, y(values[i]));
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.strokeStyle = root.color;
        ctx.stroke();

        ctx.lineTo(width, height);
        ctx.lineTo(x0, height);
        ctx.closePath();
        ctx.fillStyle = Qt.alpha(root.color, 0.15);
        ctx.fill();
    }
}
