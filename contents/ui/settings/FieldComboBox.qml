import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

// Lightweight ComboBox wrapper used throughout the settings pages.
// We keep the native KDE left-alignment to prevent Breeze theme text overlapping bugs.

ComboBox {
    id: control

    implicitHeight: Kirigami.Units.gridUnit * 1.9

    property real minimumContentWidth: 0
    property real extraPadding: Kirigami.Units.gridUnit * 2.4

    TextMetrics {
        id: metrics
        font: control.font
    }

    // Gestion manuelle de la largeur pour éviter les Binding Loops
    property real widestItemWidth: 0

    function updateWidest() {
        let max = 0;
        for (let i = 0; i < control.count; i++) {
            metrics.text = control.textAt(i);
            max = Math.max(max, metrics.advanceWidth);
        }
        widestItemWidth = max;
    }

    // Déclencheurs de mise à jour sécurisés
    onModelChanged: updateWidest()
    onCountChanged: updateWidest()
    Component.onCompleted: updateWidest()

    implicitWidth: Math.max(minimumContentWidth, widestItemWidth + extraPadding)

    popup.width: control.width
}
