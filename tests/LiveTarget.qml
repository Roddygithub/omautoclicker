import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    property var presses: ({left: 0, right: 0, middle: 0})
    property var releases: ({left: 0, right: 0, middle: 0})
    function record(button, release) {
        var name = button === Qt.LeftButton ? "left" : button === Qt.RightButton ? "right" : "middle";
        var next = Object.assign({}, release ? releases : presses);
        next[name]++;
        if (release) releases = next; else presses = next;
    }
    FloatingWindow {
        id: window
        title: "Omautoclicker Live Test"
        visible: true
        implicitWidth: 900
        implicitHeight: 650
        color: "#101315"
        Text {
            anchors.centerIn: parent
            width: parent.width - 60
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            color: "#ffffff"
            font.pixelSize: 26
            wrapMode: Text.WordWrap
            text: "Omautoclicker — test réel\n\nZone de clic sans action\n\nAppuis : " + JSON.stringify(root.presses)
                + "\nRelâchements : " + JSON.stringify(root.releases)
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onPressed: function(event) { root.record(event.button, false); }
            onReleased: function(event) { root.record(event.button, true); }
            onContainsMouseChanged: if (!containsMouse) emergency.running = true
        }
        onVisibleChanged: if (!visible) emergency.running = true
    }
    Process {
        id: emergency
        command: ["omarchy-shell", "omautoclicker", "stop"]
    }
    IpcHandler {
        target: "liveTarget"
        function status(): string {
            return JSON.stringify({presses: root.presses, releases: root.releases, inside: mouse.containsMouse});
        }
        function reset(): void {
            root.presses = {left: 0, right: 0, middle: 0};
            root.releases = {left: 0, right: 0, middle: 0};
        }
        function close(): void { Qt.quit(); }
    }
    // The target cannot outlive a failed test runner indefinitely.
    Timer { interval: 90000; running: true; onTriggered: { emergency.running = true; Qt.quit(); } }
}
