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

        // implicitWidth above is the card's PREFERRED width (it mirrors
        // inner.implicitWidth, which QtQuick.Layouts derives from each
        // child's Layout.preferredWidth — for a SplitSettingsRow that's the
        // full side-by-side width). Left unchecked, that same value would
        // also become this card's effective Layout.minimumWidth (Qt falls
        // back to implicitWidth when Layout.minimumWidth isn't set
        // explicitly), which meant the card could never actually be
        // squeezed narrower than "both columns side by side" — so a
        // SplitSettingsRow's own stacking fallback could never kick in, no
        // matter how narrow the window got. Setting Layout.minimumWidth
        // explicitly, from each child's own Layout.minimumWidth (falling
        // back to implicitWidth for children that don't set one, e.g. a
        // single-column SettingGroup), lets the card actually shrink down
        // to what its content can genuinely still fit without clipping.
        // Only children with an EXPLICIT Layout.minimumWidth (e.g.
        // SplitSettingsRow, which sets its own based on its two columns'
        // true natural sizes) contribute a floor here. Falling back to
        // c.implicitWidth for everything else (the previous behaviour) was
        // wrong for any child whose implicitWidth is not actually its
        // minimum — a wrapping Label's implicitWidth is its full one-line
        // UNWRAPPED width (wrapMode doesn't shrink it), and a Column of
        // dynamically laid-out rows (e.g. ConfigData's metric lists)
        // reports its natural single-line-per-row width the same way. Using
        // either as a hard floor forced the card (and, when several such
        // cards sit side by side, the whole row) to demand more width than
        // the window actually had, so the excess — a paragraph's tail, or a
        // row's trailing arrows/badge — silently overflowed past the page's
        // ScrollView and got clipped. Falling back to 0 here matches
        // QtQuick.Layouts' own default (an unset Layout.minimumWidth means
        // "no floor, shrink/wrap as needed") and leaves it up to children
        // that genuinely need a floor to say so explicitly, same as
        // SplitSettingsRow already does.
        Layout.minimumWidth: {
            let m = 0;
            for (let i = 0; i < inner.children.length; i++) {
                let c = inner.children[i];
                if (!c || c.visible === false) continue;
                let cw = (c.Layout && c.Layout.minimumWidth > 0) ? c.Layout.minimumWidth : 0;
                m = Math.max(m, cw);
            }
            return m + Kirigami.Units.largeSpacing * 2;
        }

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
