import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import qs.Ui
import qs.Commons
import qs.Commons as Commons

Panel {
    id: root
    moduleName: "roddy.omautocliker"
    manageIpc: false
    property var anchorItem: null
    property var hostWidget: null
    property var service: null
    readonly property color accent: Commons.Color.accent
    readonly property color muted: Qt.rgba(barForeground.r, barForeground.g, barForeground.b, 0.58)
    function tint(alpha) { return Qt.rgba(accent.r, accent.g, accent.b, alpha); }
    function contrast(color) {
        function linear(v) { return v <= .04045 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); }
        return .2126 * linear(color.r) + .7152 * linear(color.g) + .0722 * linear(color.b) > .179 ? "#101315" : "white";
    }
    Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
    onOpenedChanged: if (opened && service) service.stop()
    function switchPanel(direction) {
        return bar && typeof bar.switchPanelFrom === "function" ? bar.switchPanelFrom(hostWidget || root, direction) : false;
    }
    function save(interval, button, limit, delay) {
        if (service) service.configure(interval, button, limit, delay);
    }
    component Label: Text {
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        horizontalAlignment: Commons.I18n.rightToLeft ? Text.AlignRight : Text.AlignLeft
        color: root.barForeground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
    }
    component Numeric: Column {
        id: numeric
        property alias label: caption.text
        property alias value: input.value
        property alias from: input.from
        property alias to: input.to
        property alias stepSize: input.stepSize
        signal modified(int value)
        spacing: Style.space(7)
        Label {
            id: caption
            width: parent.width
            color: root.muted
            font.pixelSize: Style.font.bodySmall
        }
        NumberField {
            id: input
            width: parent.width
            fieldWidth: width
            field.palette.buttonText: root.barForeground
            foreground: root.barForeground
            onModified: function(value) { numeric.modified(value); }
        }
    }
    KeyboardPanel {
        id: surface
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keys
        contentWidth: surface.fittedContentWidth(Style.space(380))
        contentHeight: surface.fittedContentHeight(content.implicitHeight)
        FocusScope {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.close()
            Column {
                id: content
                objectName: "omautocliker-panel-content"
                width: parent.width
                spacing: Style.space(18)
                RowLayout {
                    width: parent.width
                    spacing: Style.space(12)
                    Rectangle {
                        width: Style.space(42); height: width
                        radius: Style.cornerRadius
                        color: root.tint(0.13)
                        MouseMark { anchors.centerIn: parent; width: 26; height: 26; ink: root.accent }
                    }
                    Column {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: Style.space(4)
                        Label { width: parent.width; text: strings.t("title"); font.pixelSize: Style.space(19); font.bold: true; fontSizeMode: Text.HorizontalFit; minimumPixelSize: Style.space(14) }
                        Label { width: parent.width; text: strings.t("tagline"); color: root.muted; font.pixelSize: Style.font.bodySmall }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: rate.implicitHeight + Style.space(32)
                    color: root.tint(0.065)
                    border.color: root.tint(0.28)
                    radius: Style.cornerRadius
                    Column {
                        id: rate
                        x: Style.space(16); y: x
                        width: parent.width - 2 * x
                        spacing: Style.space(12)
                        Label { width: parent.width; objectName: "rateHeading"; text: strings.t("rate"); color: root.muted; font.pixelSize: Style.font.bodySmall; font.letterSpacing: Commons.I18n.rightToLeft ? 0 : 1 }
                        RowLayout {
                            width: parent.width
                            spacing: Style.space(16)
                            RowLayout {
                                spacing: Style.space(7)
                                Layout.fillWidth: true
                                Label {
                                    Layout.maximumWidth: Style.space(130)
                                    fontSizeMode: Text.HorizontalFit
                                    minimumPixelSize: Style.space(24)
                                    text: Commons.I18n.formatNumber(root.service ? 1000 / root.service.intervalMs : 10, 1)
                                    color: root.accent
                                    font.pixelSize: Style.space(38)
                                    font.bold: true
                                }
                                Label { Layout.fillWidth: true; Layout.minimumWidth: 0; text: strings.t("cpsUnit"); color: root.muted }
                            }
                            Numeric {
                                Layout.preferredWidth: Style.space(105)
                                label: strings.t("interval").arg("ms")
                                from: 10; to: 3600000; stepSize: 10
                                value: root.service ? root.service.intervalMs : 100
                                enabled: root.service && !root.service.active
                                onModified: function(v) { root.save(v, root.service.button, root.service.limit, root.service.delaySeconds); }
                            }
                        }
                        RowLayout {
                            width: parent.width
                            spacing: Style.space(5)
                            Repeater {
                                model: [50, 100, 250, 1000]
                                Button {
                                    required property int modelData
                                    objectName: "ratePreset" + modelData
                                    Layout.fillWidth: true
                                    text: Commons.I18n.formatNumber(1000 / modelData) + " /s"
                                    selected: root.service && root.service.intervalMs === modelData
                                    bordered: true
                                    focusable: true
                                    enabled: root.service && !root.service.active
                                    onClicked: root.save(modelData, root.service.button, root.service.limit, root.service.delaySeconds)
                                }
                            }
                        }
                    }
                }
                Column {
                    width: parent.width
                    spacing: Style.space(10)
                    enabled: root.service && !root.service.active
                    Label { text: strings.t("button"); color: root.muted; font.pixelSize: Style.font.bodySmall }
                    RowLayout {
                        width: parent.width
                        spacing: Style.space(6)
                        Repeater {
                            model: ["left", "middle", "right"]
                            Button {
                                required property string modelData
                                objectName: "mouseButton" + modelData
                                Layout.fillWidth: true
                                text: strings.t(modelData)
                                focusable: true; bordered: true
                                selected: root.service && root.service.button === modelData
                                onClicked: root.save(root.service.intervalMs, modelData, root.service.limit, root.service.delaySeconds)
                            }
                        }
                    }
                }
                RowLayout {
                    width: parent.width
                    spacing: Style.space(16)
                    enabled: root.service && !root.service.active
                    Column {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (content.width - Style.space(16)) / 2
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignTop
                        spacing: Style.space(7)
                        Numeric {
                            width: parent.width
                            label: strings.t("repeat")
                            from: 0; to: 1000000
                            value: root.service ? root.service.limit : 0
                            onModified: function(v) { root.save(root.service.intervalMs, root.service.button, v, root.service.delaySeconds); }
                        }
                        Label { width: parent.width; text: strings.t("unlimited"); color: root.muted; font.pixelSize: Style.font.bodySmall }
                    }
                    Column {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (content.width - Style.space(16)) / 2
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignTop
                        spacing: Style.space(7)
                        Numeric {
                            width: parent.width
                            label: strings.t("delayShort").arg("s")
                            from: 1; to: 10
                            value: root.service ? root.service.delaySeconds : 3
                            onModified: function(v) { root.save(root.service.intervalMs, root.service.button, root.service.limit, v); }
                        }
                        Label { width: parent.width; text: strings.t("positionHint"); color: root.muted; font.pixelSize: Style.font.bodySmall }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.12) }
                Label {
                    width: parent.width
                    text: !root.service ? strings.t("unavailable")
                        : root.service.error !== "" ? strings.t(root.service.error)
                        : root.service.phase === "countdown" ? strings.t("countdown").arg(Commons.I18n.formatNumber(root.service.remaining) + " s")
                        : strings.t("count").arg(Commons.I18n.formatNumber(root.service.count))
                    color: root.service && root.service.error !== "" ? Commons.Color.urgent : root.muted
                    font.pixelSize: Style.font.bodySmall
                }
                Controls.Button {
                    id: start
                    objectName: "startButton"
                    width: parent.width
                    height: Style.space(46)
                    enabled: root.service !== null
                    text: root.service && root.service.active ? strings.t("stop") : strings.t("startShort")
                    contentItem: Label {
                        text: start.text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        color: root.contrast(root.accent)
                    }
                    background: Rectangle {
                        radius: Style.cornerRadius
                        color: start.down ? Qt.darker(root.accent, 1.15) : start.hovered ? Qt.lighter(root.accent, 1.12) : root.accent
                        border.width: start.activeFocus ? 2 : 0
                        border.color: root.barForeground
                        opacity: start.enabled ? 1 : 0.4
                    }
                    onClicked: {
                        if (root.service.active) root.service.stop();
                        else if (root.service.start()) root.close();
                    }
                }
                RowLayout {
                    width: parent.width
                    Label { text: strings.t("safeHint"); color: root.muted; font.pixelSize: Style.font.bodySmall; Layout.fillWidth: true }
                    Label { text: "F8  /  F9"; color: root.accent; font.pixelSize: Style.font.bodySmall }
                }
            }
        }
    }
}
