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

    // Opt-in: when true, contentRow's children are allowed to reflow onto
    // additional lines instead of being held to their natural single-line
    // width no matter what. Off by default, which preserves the exact
    // existing behaviour (and the "never wrap" floor described below) for
    // every row that doesn't set it. This exists for rows with several
    // independent, same-weight items (e.g. a handful of checkboxes) where
    // wrapping to a second line reads fine — unlike a label+spinbox pair,
    // where splitting the two apart would look broken, so those rows should
    // simply keep allowWrap at its default.
    property bool allowWrap: false

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
        //
        // When allowWrap is set, "its own size" for the content side no
        // longer means the whole unwrapped row — it means whichever single
        // child is widest, since anything wider than that can safely drop
        // to the next line instead of forcing the row (and everything
        // above it, up to the page's window) to stay that wide.
        readonly property real _contentMinWidth: !root.allowWrap ? contentRow.implicitWidth : root._widestContentChild()
        function _widestContentChild() {
            let m = 0;
            for (let i = 0; i < contentRow.children.length; i++) {
                let c = contentRow.children[i];
                if (c && c.visible !== false) m = Math.max(m, c.implicitWidth);
            }
            return m;
        }
        Layout.minimumWidth: root._contentMinWidth + (root.label.length > 0 ? (labelItem.implicitWidth + root.spacing) : 0)

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

        // Flow (the positioner behind contentRow) is supposed to reposition
        // its children on its own whenever a child's `visible` changes, but
        // in practice that isn't reliable when the toggling child sits in
        // the middle of the row (e.g. a ComboBox whose visibility depends on
        // a sibling CheckBox) rather than at the very end: Flow can leave
        // the following sibling(s) at their previous x, overlapping the
        // child that just became visible again. Qt.callLater is not enough
        // here since nothing actually changed on the properties it batches
        // on (width/height/spacing) — only visible did. forceLayout() is the
        // API Flow (and Row/Column/Grid) expose specifically for "content
        // changed in a way I might not have detected, recompute now".
        // Exposed publicly as a manual escape hatch for whatever the
        // automatic path (_watchChildVisibility/_onContentChildVisibilityChanged
        // below, which already re-centers and re-syncs on any content child's
        // visibleChanged) doesn't catch. Not currently called anywhere: the
        // one row that used to need this (ConfigAppearance.qml's "Condition:"
        // row) now sidesteps the whole issue by nesting the toggling
        // CheckBox+ComboBox pair inside their own RowLayout instead of
        // exposing them as direct Flow children — Flow then only ever sees
        // that one fixed-composition child, so it has nothing to reposition
        // when the inner ComboBox shows/hides. Kept available for a future
        // row that can't use that same trick.
        function forceRelayout() {
            contentRow.forceLayout();
            Qt.callLater(root._centerFlowChildren);
            // contentRow settling is only the innermost layer: this row sits
            // inside a SettingGroup (ColumnLayout) which, for a SplitSettingsRow,
            // has its own width pinned by a manual Binding to its
            // implicitWidth (see SplitSettingsRow.qml) rather than being
            // managed by an outer Layout. That's one more hop for the
            // now-visible child's extra width to propagate through before
            // everything on screen agrees. Nudging the parent group the same
            // way a natural width change already does (via notifyParent)
            // makes sure that hop happens too, instead of leaving it to
            // whatever unrelated change would otherwise trigger it next.
            Qt.callLater(notifyParent);
        }

        // Children whose visibleChanged/heightChanged we've already connected
        // to, so a repeated call (e.g. from onChildrenChanged, if a row's
        // content is ever mutated dynamically) doesn't double-connect the
        // same child.
        property var _visibilityWatchedChildren: []

        function _watchChildVisibility() {
            for (let i = 0; i < contentRow.children.length; i++) {
                let child = contentRow.children[i];
                if (child && root._visibilityWatchedChildren.indexOf(child) === -1) {
                    root._visibilityWatchedChildren.push(child);
                    child.visibleChanged.connect(root._onContentChildVisibilityChanged);
                    // contentRow.onHeightChanged only fires when the TALLEST
                    // child's height changes. On a config page's very first
                    // load (styles/fonts not fully warmed up yet), a non-tallest
                    // child — e.g. a SpinBox — can settle into its real height
                    // just after Component.onCompleted without ever changing
                    // the row's overall height, so it never gets re-centered
                    // and stays at the stale y from the first (too-early) pass.
                    // Reopening the page later works because everything is
                    // already warm by then. Watching each child's own
                    // heightChanged directly closes that gap, exactly like
                    // visibleChanged above.
                    if (child.heightChanged) {
                        child.heightChanged.connect(root._onContentChildVisibilityChanged);
                    }
                }
            }
        }

        // The actual gap left by _centerFlowChildren()/_refreshPreIconWidth():
        // both only re-run on contentRow.onChildrenChanged (a child added/
        // removed) or contentRow.onHeightChanged (the TALLEST child's height
        // changing). Two things fall through that net:
        //   1. Toggling `visible` on an EXISTING child: Flow may reposition
        //      it without ever changing contentRow's own height (e.g. if
        //      another, still-visible sibling was already the tallest).
        //   2. A non-tallest child settling into its real height slightly
        //      after Component.onCompleted (e.g. a SpinBox on a config
        //      page's cold first load, before styles/fonts are warmed up):
        //      contentRow's overall height doesn't move, so nothing re-runs
        //      and that child is left at the stale y from the first,
        //      too-early centering pass.
        // Watching each child's visibleChanged AND heightChanged directly
        // (see _watchChildVisibility above) closes both gaps regardless of
        // whether contentRow's own height happens to change as a side effect.
        function _onContentChildVisibilityChanged() {
            Qt.callLater(root._refreshPreIconWidth);
            Qt.callLater(root._centerFlowChildren);
            Qt.callLater(notifyParent);
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

        // contentRow is a Flow, not a RowLayout — a plain QtQuick positioner
        // that has no idea what the QtQuick.Layouts attached properties
        // (Layout.preferredWidth/Height) mean. It sizes children from their
        // own real width/height only. Every content child across the config
        // pages was written assuming a RowLayout parent though: several are
        // plain Items that set ONLY Layout.preferredWidth/Height (relying on
        // the old RowLayout to turn that into an actual size), e.g. the
        // Location-mode combo container or the API key field container in
        // ConfigSource.qml. Under Flow those Items silently stayed at their
        // default width/height of 0 — and anything anchored inside them
        // (anchors.fill: parent) disappeared entirely.
        //
        // Rather than hunting down and fixing every such Item at every call
        // site (and every future one), mirror Layout.preferredWidth/Height
        // onto real width/height for every content child that sets them —
        // live, via Qt.binding, so it keeps tracking values like
        // `locationModeCombo.implicitWidth` that change afterwards (e.g. on
        // a translation switch). This restores exactly the sizing contract
        // RowLayout used to provide, without touching every page.
        function _syncFlowChildSizes() {
            for (let i = 0; i < contentRow.children.length; i++) {
                let child = contentRow.children[i];
                if (!child || !child.Layout) continue;
                if (child.Layout.preferredWidth > 0) {
                    child.width = Qt.binding(function () { return child.Layout.preferredWidth; });
                }
                if (child.Layout.preferredHeight > 0) {
                    child.height = Qt.binding(function () { return child.Layout.preferredHeight; });
                }
            }
        }

        // Flow (a plain positioner, not a Layout) always top-aligns the
        // children of a row instead of centering them on the row's height —
        // it has no equivalent of RowLayout's Layout.alignment: AlignVCenter.
        // With mixed-height siblings (e.g. a small InfoIcon next to a taller
        // SpinBox/ComboBox/CheckBox), that means the shorter item stays
        // pinned to the top instead of being centered, which reads as the
        // icon being "raised" relative to the label and the control next to
        // it. This corrects it by re-centering every child after each Flow
        // layout pass, the same reactive way _syncFlowChildSizes already
        // corrects width: Flow owns x/y outright and will silently discard
        // any binding placed on them, so instead of fighting it once we
        // reapply a plain value every time something that can change the
        // row's height fires (children added/removed, a child's own height
        // changing, or the row's height itself changing).
        //
        // Only handled for the single-line case (allowWrap: false, which is
        // every pre-existing row): with one Flow row, that row's own top is
        // always y=0, so a child's centered position is simply
        // (rowHeight - childHeight) / 2, with no ambiguity about which row
        // it belongs to. allowWrap rows are documented as groups of
        // same-weight items (e.g. several checkboxes), where this raised-icon
        // symptom doesn't occur, so multi-row centering isn't needed here.
        function _centerFlowChildren() {
            if (root.allowWrap) return;
            let h = contentRow.height;
            for (let i = 0; i < contentRow.children.length; i++) {
                let c = contentRow.children[i];
                if (!c || c.visible === false) continue;
                c.y = (h - c.height) / 2;
            }
        }

        Component.onCompleted: { root._syncFlowChildSizes(); root._refreshPreIconWidth(); root._centerFlowChildren(); root._watchChildVisibility(); }

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

        // Flow instead of RowLayout: when allowWrap is false (the default,
        // and every pre-existing row), Flow given Layout.fillWidth: false
        // is sized to its own implicit (natural, single-line) width by its
        // RowLayout parent — identical to the previous RowLayout's
        // behaviour, so nothing changes for those rows. When allowWrap is
        // true, Layout.fillWidth: true instead hands it the row's actual
        // available width, and Flow reflows children onto additional lines
        // once they no longer fit on one — instead of RowLayout's old
        // behaviour of always demanding its full natural width regardless
        // of what's actually available.
        Flow {
            id: contentRow
            Layout.fillWidth: root.allowWrap
            spacing: root.contentSpacing
            onChildrenChanged: { root._syncFlowChildSizes(); Qt.callLater(root._refreshPreIconWidth); Qt.callLater(root._centerFlowChildren); root._watchChildVisibility(); }
            onHeightChanged: Qt.callLater(root._centerFlowChildren)
        }
}
