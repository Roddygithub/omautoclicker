import QtQuick

Canvas {
    id: root
    property color ink: "white"
    property bool active: false
    onInkChanged: requestPaint()
    onActiveChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var c = getContext("2d");
        c.reset();
        c.scale(width / 24, height / 24);
        c.strokeStyle = ink; c.lineWidth = 1.8; c.lineCap = "round";
        c.beginPath();
        c.moveTo(5, 9); c.bezierCurveTo(5, 0, 19, 0, 19, 9);
        c.lineTo(19, 15); c.bezierCurveTo(19, 24, 5, 24, 5, 15);
        c.closePath(); c.stroke();
        c.beginPath(); c.moveTo(12, 3); c.lineTo(12, 9); c.stroke();
        if (active) {
            c.fillStyle = ink;
            c.beginPath(); c.arc(12, 15, 2.5, 0, Math.PI * 2); c.fill();
        }
    }
}
