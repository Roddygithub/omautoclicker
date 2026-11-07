import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.Commons
import "Model.js" as Model

Item {
    id: root
    property var shell: null
    property alias intervalMs: preferences.intervalMs
    property alias button: preferences.button
    property alias limit: preferences.limit
    property alias delaySeconds: preferences.delaySeconds
    property string phase: "idle"
    readonly property bool active: phase !== "idle"
    property int count: 0
    property int remaining: 0
    // Errors are keys, never raw process output interpreted as rich text.
    property string error: ""
    property string diagnostic: ""
    property string executable: "ydotool"

    Settings {
        id: preferences
        location: "file://" + (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omautocliker.ini"
        property int intervalMs: 100
        property string button: "left"
        property int limit: 0
        property int delaySeconds: 3
    }

    function configure(interval, mouseButton, clicks, delay) {
        if (active || click.running || !Model.valid(interval, mouseButton, clicks, delay)) return false;
        intervalMs = interval; button = mouseButton; limit = clicks; delaySeconds = delay;
        preferences.sync();
        return true;
    }
    function stop() {
        phase = "idle";
        remaining = 0;
        countdown.stop(); cadence.stop();
        // Let the single in-flight down/up pair finish, rather than killing
        // ydotool between its press and release. No subsequent click is queued.
    }
    function start() {
        if (active || click.running) return false;
        error = ""; diagnostic = "";
        if (!Model.valid(intervalMs, button, limit, delaySeconds)) {
            error = "invalid"; return false;
        }
        count = 0; remaining = delaySeconds; phase = "countdown";
        countdown.start();
        return true;
    }
    function toggle() { if (active) stop(); else start(); }
    function sendClick() {
        if (phase !== "running" || click.running) return;
        var args = Model.command(button);
        args[0] = executable;
        // The shell also turns an absent executable into a normal exit 127.
        // Arguments remain separate; no user value is evaluated as shell code.
        click.command = ["/bin/sh", "-c", 'exec "$@"', "omautocliker"].concat(args);
        click.running = true;
    }
    function status() {
        return JSON.stringify({phase: phase, count: count, remaining: remaining,
            intervalMs: intervalMs, button: button, limit: limit, delaySeconds: delaySeconds,
            error: error, diagnostic: diagnostic});
    }
    Timer {
        id: countdown
        interval: 1000; repeat: true
        onTriggered: {
            root.remaining--;
            if (root.remaining <= 0) {
                stop(); root.phase = "running"; cadence.start(); root.sendClick();
            }
        }
    }
    Timer {
        id: cadence
        interval: root.intervalMs; repeat: true
        onTriggered: root.sendClick()
    }
    Process {
        id: click
        stderr: StdioCollector { onStreamFinished: root.diagnostic = text.slice(0, 1000) }
        onExited: function(code, status) {
            watchdog.stop();
            if (code !== 0 || status !== 0) { root.stop(); root.error = "backend"; return; }
            root.count++;
            if (root.limit > 0 && root.count >= root.limit) root.stop();
        }
        onRunningChanged: if (running) watchdog.restart()
    }
    Timer {
        id: watchdog
        interval: 2000
        // Stop scheduling if the backend hangs. Keep the process alive so it
        // can complete its release; start remains blocked until it exits.
        onTriggered: { root.stop(); root.error = "backend"; }
    }
    Component.onDestruction: stop()
    ShellIpc {
        target: "omautocliker"
        function toggle(): void { root.toggle(); }
        function stop(): void { root.stop(); }
        function start(): bool { return root.start(); }
        function status(): string { return root.status(); }
        function configure(interval: int, button: string, limit: int, delay: int): bool {
            return root.configure(interval, button, limit, delay);
        }
    }
}
