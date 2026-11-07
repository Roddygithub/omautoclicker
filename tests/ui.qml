import QtQuick
import Quickshell
import qs.Commons as Commons
import Quickshell.Wayland
import qs.Commons
import "." as Plugin

ShellRoot {
    Plugin.Service { id: backend; executable: Quickshell.env("OMAUTOC_TEST_EXEC") }
    Plugin.BarWidget { id: widget }
    Plugin.ClickPanel { id: panel; service: backend }
    function findContent(object, seen, name) {
        if (!object || seen.indexOf(object) !== -1) return null;
        seen.push(object);
        if (object.objectName === (name || "omautocliker-panel-content")) return object;
        var lists = [object.children, object.data, object.contentItem];
        for (var i = 0; i < lists.length; i++) {
            var list = lists[i];
            if (!list) continue;
            if (list.length === undefined) list = [list];
            for (var j = 0; j < list.length; j++) {
                var found = findContent(list[j], seen, name);
                if (found) return found;
            }
        }
        return null;
    }
    Translations { id: expectedStrings; directory: Qt.resolvedUrl("i18n") }
    function checkTextLayout(object, seen) {
        if (!object || seen.indexOf(object) !== -1) return true;
        seen.push(object);
        if (object.visible && object.text && "paintedWidth" in object && "textFormat" in object) {
            var content = findContent(panel, []);
            var point = object.mapToItem(content, 0, 0);
            if (point.x < -2 || point.x + object.width > content.width + 2) {
                console.error("FAIL: text outside panel: " + object.text + " at " + point.x + " width " + object.width);
                return false;
            }
            if (object.paintedWidth > object.width + 2) {
                console.error("FAIL: clipped text: " + object.text);
                return false;
            }
        }
        var lists = [object.children, object.data, object.contentItem];
        for (var i = 0; i < lists.length; i++) {
            var list = lists[i];
            if (!list) continue;
            if (list.length === undefined) list = [list];
            for (var j = 0; j < list.length; j++) if (!checkTextLayout(list[j], seen)) return false;
        }
        return true;
    }
    property int stage: 0
    Timer {
        interval: 500; repeat: true; running: true
        onTriggered: {
            if (stage === 0) {
                backend.configure(100, "left", 0, 3); backend.start(); panel.open();
                if (backend.active || !panel.opened) { console.error("FAIL: open stops countdown"); Qt.quit(); return; }
                stage = 1;
            } else if (stage === 1) {
                var expected = expectedStrings.t("rate");
                var alignment = Commons.I18n.rightToLeft ? Text.AlignRight : Text.AlignLeft;
                if (findContent(panel, [], "rateHeading").effectiveHorizontalAlignment !== alignment) { console.error("FAIL: text direction"); Qt.quit(); return; }
                if (Commons.I18n.language !== Quickshell.env("OMAUTOC_TEST_LANG")) { console.error("FAIL: automatic language selection"); Qt.quit(); return; }
                if (findContent(panel, [], "rateHeading").text !== expected) { console.error("FAIL: selected language"); Qt.quit(); return; }
                findContent(panel, [], "ratePreset50").clicked();
                if (backend.intervalMs !== 50) { console.error("FAIL: rate preset"); Qt.quit(); return; }
                findContent(panel, [], "mouseButtonright").clicked();
                if (backend.button !== "right") { console.error("FAIL: mouse selection"); Qt.quit(); return; }
                findContent(panel, [], "startButton").clicked();
                if (!backend.active || panel.opened) { console.error("FAIL: start closes panel"); Qt.quit(); return; }
                panel.open();
                if (backend.active) { console.error("FAIL: reopen stops sequence"); Qt.quit(); return; }
                backend.configure(100, "left", 0, 3);
                stage = 2;
            } else if (stage === 2) {
                if (!checkTextLayout(findContent(panel, []), [])) { Qt.quit(); return; }
                if (Quickshell.env("OMAUTOC_SCREENSHOT")) {
                    var content = findContent(panel, []);
                    if (!content) { console.error("FAIL: panel content missing"); Qt.quit(); return; }
                    // Include the card background when capturing just its content.
                    var backdrop = Qt.createQmlObject('import QtQuick; Rectangle { anchors.fill: parent; z: -1 }', content.parent);
                    backdrop.color = Commons.Color.background;
                    content.parent.grabToImage(function(result) {
                        if (!result.saveToFile(Quickshell.env("OMAUTOC_SCREENSHOT"))) console.error("FAIL: screenshot");
                    });
                }
                stage = 3;
            } else {
                panel.close();
                if (panel.opened) console.error("FAIL: panel close");
                else console.log("UI TESTS PASS");
                Qt.quit();
            }
        }
    }
}
