import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.Icon {
    id: root

    property string text: ""

    // Marker used by SettingRow to find "the trailing info icon" among its
    // content children via duck-typing (see SettingRow._findTrailingIcon),
    // the same way SettingRow's own naturalLabelWidth is duck-typed by
    // RowWidthSync.js. Never read for its value, only its presence.
    readonly property bool isInfoIcon: true

    source: "help-about"
    implicitWidth: Kirigami.Units.iconSizes.small
    implicitHeight: Kirigami.Units.iconSizes.small

    opacity: ma.containsMouse ? 1.0 : 0.4
    Behavior on opacity { NumberAnimation { duration: 150 } }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
    }

    ToolTip.text: root.text
    ToolTip.visible: ma.containsMouse
    ToolTip.delay: Kirigami.Units.toolTipDelay
}
