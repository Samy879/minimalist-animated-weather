import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: root

    property string label: ""
    property real labelWidth: 0
    property real contentSpacing: Kirigami.Units.smallSpacing

    // Shared alignment width for a trailing InfoIcon's position within this
    // row's content area. Like labelWidth, this is written from outside
    // (SettingGroup/SettingsCard, via RowWidthSync.js) so every row sharing
    // a column keeps its "i" icon at the same horizontal position, even
    // when one row's own content (e.g. a combo box) is naturally wider than
    // the others. Rows without a trailing InfoIcon simply ignore it.
    property real iconAreaWidth: 0

    // naturalLabelWidth is the label's own unconstrained width (text + colon,
    // since the colon is kept as part of the same string/item — no nested
    // layout involved, so this value is always the true intrinsic size).
    readonly property real naturalLabelWidth: root.label.length > 0 ? labelItem.implicitWidth : 0
    readonly property real naturalContentWidth: contentRow.implicitWidth

    // Natural width of everything in contentRow BEFORE a trailing InfoIcon
    // (0 if this row has no InfoIcon). Computed independently from
    // naturalContentWidth/contentRow.implicitWidth on purpose: once we start
    // pushing the icon over with Layout.leftMargin (see _applyIconMargin),
    // contentRow.implicitWidth grows to include that margin too, and
    // deriving "the natural part" back out of an already-inflated value
    // would feed the margin back into itself and grow without bound.
    property real naturalPreIconWidth: 0

    property var _trailingIcon: null

    default property alias content: contentRow.data

        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        // Floor for this row: the label can give up the extra padding it
        // picked up from being aligned with other rows/cards, but it can
        // never go narrower than its own natural text width — so this floor
        // is the row's true minimum, i.e. label at its own size + content at
        // its own size, never truncated and never spilling past whatever
        // boundary (e.g. the vertical separator between two columns) the
        // outer layout is trying to enforce.
        Layout.minimumWidth: contentRow.implicitWidth + (root.label.length > 0 ? (labelItem.implicitWidth + root.spacing) : 0)

        // Prévient le parent que la taille a changé pour forcer le réalignement global
        onNaturalLabelWidthChanged: Qt.callLater(notifyParent)
        // _refreshPreIconWidth MUST run before notifyParent: naturalContentWidth
        // changes whenever a sibling inside contentRow (e.g. the alignment
        // combo box) shows/hides, and notifyParent() is what asks the parent
        // group to recompute its shared maxIconAreaWidth by reading every
        // row's naturalPreIconWidth. If notifyParent ran first, the group
        // would recompute using THIS row's stale (pre-toggle) naturalPreIconWidth,
        // and — since nothing else re-triggers that recompute on its own —
        // the icon column would stay pinned to an outdated width until some
        // unrelated row happened to change and drag it back in sync. That's
        // the "icon jumps around / lines up with the wrong row" symptom.
        onNaturalContentWidthChanged: { Qt.callLater(root._refreshPreIconWidth); Qt.callLater(notifyParent); }
        onVisibleChanged: Qt.callLater(notifyParent)
        onIconAreaWidthChanged: Qt.callLater(root._applyIconMargin)
        // Also notify on naturalPreIconWidth itself: it can change without
        // naturalContentWidth changing in lockstep (e.g. if a future content
        // child's width changes but its own visibility doesn't), and the
        // group's shared icon-column width must stay derived from the
        // CURRENT value, not whatever it happened to be at the last
        // recompute.
        onNaturalPreIconWidthChanged: Qt.callLater(notifyParent)

        function notifyParent() {
            let p = root.parent;
            while (p) {
                if (typeof p.updateWidths === "function") {
                    p.updateWidths();
                    break;
                }
                p = p.parent;
            }
        }

        // Finds the trailing InfoIcon among contentRow's children, if any
        // (duck-typed via InfoIcon.isInfoIcon — see RowWidthSync.js).
        function _findTrailingIcon() {
            let n = contentRow.children.length;
            if (n === 0) return null;
            let last = contentRow.children[n - 1];
            return (last && typeof last.isInfoIcon !== "undefined") ? last : null;
        }

        // Measures "everything before the icon" directly from the visible
        // children, ignoring contentRow.implicitWidth entirely (see the
        // naturalPreIconWidth comment above for why).
        function _computeNaturalPreIconWidth(icon) {
            if (!icon) return 0;
            let sum = 0;
            let visibleCount = 0;
            for (let i = 0; i < contentRow.children.length; i++) {
                let c = contentRow.children[i];
                if (c === icon) continue;
                if (c.visible === false) continue;
                sum += c.implicitWidth;
                visibleCount++;
            }
            // One gap between each visible item, plus one more before the icon.
            if (visibleCount > 0) sum += contentRow.spacing * visibleCount;
            return sum;
        }

        function _refreshPreIconWidth() {
            root._trailingIcon = root._findTrailingIcon();
            root.naturalPreIconWidth = root._computeNaturalPreIconWidth(root._trailingIcon);
            root._applyIconMargin();
        }

        function _applyIconMargin() {
            if (!root._trailingIcon) return;
            let extra = root.iconAreaWidth - root.naturalPreIconWidth;
            root._trailingIcon.Layout.leftMargin = extra > 0 ? extra : 0;
        }

        Component.onCompleted: root._refreshPreIconWidth()

        // A single, non-layout Label (not a nested RowLayout) with an explicit
        // Layout.preferredWidth, capped with Layout.maximumWidth at that same
        // value so it never grows past it. This avoids the classic
        // QtQuick.Layouts pitfall where a layout nested inside another layout,
        // combined with a sibling fillWidth item, makes implicit-width
        // computation unreliable and pushes rows out of alignment. fillWidth
        // is still enabled here (unlike contentRow) so the label — and only
        // the label — is what gives ground when the row is narrower than
        // usual. It's only allowed to shrink down to its OWN natural width
        // though (never below implicitWidth, and no elide): losing the extra
        // alignment padding is fine, losing part of the word is not.
        Label {
            id: labelItem
            visible: root.label.length > 0
            text: root.label
            Layout.preferredWidth: root.labelWidth > 0 ? root.labelWidth : implicitWidth
            Layout.fillWidth: true
            Layout.minimumWidth: implicitWidth
            Layout.maximumWidth: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignRight
            opacity: 0.85
        }

        RowLayout {
            id: contentRow
            // Nested layouts default their own Layout.fillWidth to true in
            // QtQuick.Layouts, which is exactly what caused the misalignment:
            // this row (and the old label block) would silently compete for
            // the parent's leftover space. Force it off so contentRow always
            // stays at its natural size, right after the label.
            Layout.fillWidth: false
            spacing: root.contentSpacing
            onChildrenChanged: Qt.callLater(root._refreshPreIconWidth)
        }

        // No trailing spacer needed: root already has Layout.fillWidth set, so
        // once it's stretched to the column's width by its parent, any leftover
        // space after labelItem + contentRow simply stays empty at the end
        // (RowLayout packs children at the start by default).
}
