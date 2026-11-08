import QtQuick

Canvas {
    id: root
    property color ink: "white"
    property bool active: false
    property bool compact: false
    onInkChanged: requestPaint()
    onActiveChanged: requestPaint()
    onCompactChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var c = getContext("2d");
        c.reset();
        c.scale(width / 24, height / 24);
        c.strokeStyle = ink; c.lineWidth = compact ? 2.4 : 1.8; c.lineCap = "round";
        c.beginPath();
        var left = compact ? 3 : 5, right = compact ? 21 : 19;
        c.moveTo(left, 9); c.bezierCurveTo(left, 0, right, 0, right, 9);
        c.lineTo(right, 15); c.bezierCurveTo(right, 24, left, 24, left, 15);
        c.closePath(); c.stroke();
        c.beginPath(); c.moveTo(12, 3); c.lineTo(12, 9); c.stroke();
        if (active) {
            c.fillStyle = ink;
            c.beginPath(); c.arc(12, 15, 2.5, 0, Math.PI * 2); c.fill();
        }
    }
}
