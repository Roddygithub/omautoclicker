import QtQuick
import Quickshell
import Quickshell.Io
import "." as Plugin

ShellRoot {
    Plugin.Service { id: backend; executable: Quickshell.env("OMAUTOC_TEST_EXEC") }
    property int stage: 0
    property int ticks: 0
    property int stoppedCount: 0
    function check(ok, message) {
        if (!ok) { console.error("FAIL: " + message + " " + backend.status()); Qt.quit(); }
        return ok;
    }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            ticks++;
            if (ticks > 250) { check(false, "test timeout"); return; }
            if (stage === 0) {
                if (!check(!backend.active, "initial idle")) return;
                if (!check(!backend.configure(0, "left", 3, 1), "reject bad interval")) return;
                backend.configure(10, "left", 3, 1);
                backend.start(); backend.stop();
                stage = 1;
            } else if (stage === 1 && ticks > 25) {
                if (!check(backend.count === 0 && !backend.active, "cancel countdown")) return;
                backend.start();
                if (!check(!backend.configure(100, "right", 1, 1), "freeze active settings")) return;
                stage = 2;
            } else if (stage === 2 && backend.count === 3 && !backend.active) {
                stage = 3; ticks = 0;
            } else if (stage === 3 && ticks > 10) {
                if (!check(backend.count === 3, "finite limit no overshoot")) return;
                backend.configure(10, "left", 0, 1); backend.start(); stage = 4;
            } else if (stage === 4 && backend.count >= 2) {
                backend.stop(); stoppedCount = backend.count; stage = 5; ticks = 0;
            } else if (stage === 5 && ticks > 10) {
                if (!check(!backend.active && backend.count <= stoppedCount + 1, "stop at most one in-flight pair")) return;
                backend.executable = "/does/not/exist/ydotool";
                backend.start(); stage = 6;
            } else if (stage === 6 && backend.error !== "") {
                if (!check(!backend.active && backend.count === 0, "missing backend stops")) return;
                backend.executable = "/bin/false"; backend.start(); stage = 7;
            } else if (stage === 7 && backend.error !== "") {
                if (!check(!backend.active && backend.count === 0, "backend nonzero stops")) return;
                console.log("SERVICE TESTS PASS"); Qt.quit();
            }
        }
    }
}
