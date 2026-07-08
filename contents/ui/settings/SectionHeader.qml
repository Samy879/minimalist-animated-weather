import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Standalone section title, placed OUTSIDE Kirigami.FormLayout.
// Ensures consistent left-alignment across all settings pages,
// regardless of the label column width of the FormLayout that follows.
RowLayout {
    id: root

    property alias text: label.text
    property bool isFirst: false

    Layout.fillWidth: true
    Layout.topMargin: isFirst ? 0 : Kirigami.Units.gridUnit * 0.75
    spacing: 0

    Label {
        id: label
        font.bold: true
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
        color: Kirigami.Theme.textColor
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
}
