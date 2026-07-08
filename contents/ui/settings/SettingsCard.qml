import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "RowWidthSync.js" as RowWidthSync

Item {
    id: card

    default property alias content: inner.data
        property alias radius: surface.radius

        property real externalLabelWidth: -1
        property real externalIconAreaWidth: -1

        property real _internalMaxLabelWidth: 0
        property real _internalMaxContentWidth: 0
        property real _internalMaxIconAreaWidth: 0

        readonly property real maxLabelWidth: _internalMaxLabelWidth
        readonly property real maxContentWidth: _internalMaxContentWidth
        readonly property real maxIconAreaWidth: _internalMaxIconAreaWidth

        readonly property real effectiveLabelWidth: externalLabelWidth > 0 ? externalLabelWidth : maxLabelWidth
        readonly property real effectiveIconAreaWidth: externalIconAreaWidth > 0 ? externalIconAreaWidth : maxIconAreaWidth

        Layout.fillWidth: true
        Layout.preferredHeight: inner.implicitHeight + Kirigami.Units.largeSpacing * 2
        // Propagate the card's true minimum required width upward, exactly
        // like Layout.preferredHeight already does for height. Without this,
        // SettingsCard (a plain Item with only Layout.fillWidth: true) never
        // tells its parent ColumnLayout that it needs more horizontal room —
        // so a translated string that's naturally wider than the page's
        // fixed cap (see ConfigAppearance's contentMaxWidth) has nowhere to
        // go but to overflow past the card's edge instead of the page
        // growing to accommodate it.
        implicitWidth: inner.implicitWidth + Kirigami.Units.largeSpacing * 2

        // See SettingGroup.qml for why updateWidths() and syncRowWidths() stay
        // as two separate functions (SettingRow.notifyParent() looks up
        // updateWidths() specifically by name on whichever ancestor has it).
        function updateWidths() {
            let widths = RowWidthSync.computeMaxWidths(inner.children);
            card._internalMaxLabelWidth = widths.maxLabelWidth;
            card._internalMaxContentWidth = widths.maxContentWidth;
            card._internalMaxIconAreaWidth = widths.maxIconAreaWidth;
        }

        function syncRowWidths() {
            card.updateWidths();
            RowWidthSync.bindLabelWidths(inner.children, function () { return card.effectiveLabelWidth; }, function () { return card.effectiveIconAreaWidth; });
        }

        // Synchronous on purpose: QML completes children before their parent,
        // so by the time this runs every row's natural width is already known.
        // Deferring this with Qt.callLater() let the first frame paint with
        // unaligned rows, then snap into place a tick later — that visible
        // "jump" when switching pages is exactly what this avoids.
        Component.onCompleted: syncRowWidths()

        Rectangle {
            anchors.fill: surface
            anchors.topMargin: 2
            radius: surface.radius
            color: Kirigami.Theme.textColor
            opacity: 0.06
        }

        Rectangle {
            id: surface
            anchors.fill: parent
            radius: Kirigami.Units.smallSpacing * 1.9
            color: Kirigami.Theme.alternateBackgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07)
        }

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing * 0.8

            // Dynamic additions/removals after the initial paint (e.g. a row
            // becoming visible) still need a re-sync; callLater is fine here
            // since there's no "first frame" to protect anymore.
            onChildrenChanged: Qt.callLater(card.syncRowWidths)
        }
}
