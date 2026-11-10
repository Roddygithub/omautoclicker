import QtQuick
import qs.Ui as Ui
import qs.Commons
import qs.Commons as Commons

Ui.BarWidget {
    id: root
    moduleName: "roddy.omautoclicker"
    readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
    readonly property bool opened: panel.opened
    readonly property bool popoutSwitchClosing: panel.popoutSwitchClosing
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    function open() { panel.open(); }
    function close() { panel.close(); }
    function toggle() { panel.toggle(); }
    function closeForPopoutSwitch() { panel.closeForPopoutSwitch(); }
    Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
    Ui.WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        labelVisible: false
        hasVisualContent: true
        fixedWidth: Style.bar.iconSlot
        MouseMark {
            anchors.centerIn: parent
            width: Math.min(Style.bar.iconCanvas, Style.bar.iconSize + Style.space(2)); height: width
            ink: root.service && root.service.active ? Commons.Color.accent : button.foreground
            active: root.service && root.service.active
        }
        tooltipText: strings.t("title")
        onPressed: function(code) {
            if (code === Qt.RightButton && root.service) root.service.stop();
            else root.toggle();
        }
    }
    ClickPanel {
        id: panel
        bar: root.bar
        anchorItem: button
        hostWidget: root
        service: root.service
    }
}
