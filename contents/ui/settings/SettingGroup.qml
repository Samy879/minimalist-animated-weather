import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "RowWidthSync.js" as RowWidthSync

ColumnLayout {
    id: group

    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing * 0.8

    property real externalLabelWidth: -1
    // Same idea as externalLabelWidth, but for the column of trailing
    // InfoIcons: when set (e.g. to a value shared across several
    // cards/groups in the same visual column), every row's "i" icon in this
    // group lines up with that shared position instead of just the rows
    // within this one group.
    property real externalIconAreaWidth: -1

    property real _internalMaxLabelWidth: 0
    property real _internalMaxContentWidth: 0
    property real _internalMaxIconAreaWidth: 0

    readonly property real maxLabelWidth: _internalMaxLabelWidth
    readonly property real maxContentWidth: _internalMaxContentWidth
    readonly property real maxIconAreaWidth: _internalMaxIconAreaWidth

    readonly property real effectiveLabelWidth: externalLabelWidth > 0 ? externalLabelWidth : maxLabelWidth
    readonly property real effectiveIconAreaWidth: externalIconAreaWidth > 0 ? externalIconAreaWidth : maxIconAreaWidth

    // See SettingsCard.qml for why updateWidths() and syncRowWidths() stay
    // as two separate functions (SettingRow.notifyParent() looks up
    // updateWidths() specifically by name on whichever ancestor has it).
    function updateWidths() {
        let widths = RowWidthSync.computeMaxWidths(group.children);
        group._internalMaxLabelWidth = widths.maxLabelWidth;
        group._internalMaxContentWidth = widths.maxContentWidth;
        group._internalMaxIconAreaWidth = widths.maxIconAreaWidth;
    }

    function syncRowWidths() {
        group.updateWidths();
        RowWidthSync.bindLabelWidths(group.children, function () { return group.effectiveLabelWidth; }, function () { return group.effectiveIconAreaWidth; });
    }

    // Synchronous on purpose — see SettingsCard.qml for the full explanation.
    // This is the component actually responsible for aligning label columns,
    // so this is where the pre-fix "jump on page switch" was most visible.
    Component.onCompleted: syncRowWidths()
    onChildrenChanged: Qt.callLater(group.syncRowWidths)
}
