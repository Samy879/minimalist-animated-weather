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

    // For the overwhelmingly common allowWrap:false case, children are
    // declared straight onto rowContainer below, parented synchronously at
    // construction time — identical to v0, with no extra tick before their
    // real size is known. That matters here specifically because rows
    // hosted inside SplitSettingsRow (e.g. every forecast-range row) or
    // sharing an icon column via SettingGroup have their surrounding layout
    // (leftItem/rightItem centering, the shared iconAreaWidth) driven
    // directly off this row's implicitWidth/naturalPreIconWidth. An extra
    // reparenting hop before those settle is exactly what used to cause
    // both the horizontal "settles after a jitter" flash in
    // SplitSettingsRow and a stale, too-wide iconAreaWidth locking in
    // before every row had reported its real content width.
    //
    // allowWrap:true rows (a handful of checkbox groups, never hosted in a
    // width-critical layout like SplitSettingsRow) are the one case that
    // still needs a real Flow instead of a RowLayout, and for those the
    // extra hop is harmless: their default alias below is retargeted onto
    // rowContainer at Component.onCompleted, and — for allowWrap rows
    // only — the children are moved on to flowContainer there instead.
    default property alias content: rowContainer.data

        // The positioner actually responsible for laying out this row's
        // content. allowWrap is fixed at creation (no call site toggles it
        // afterwards).
        readonly property Item contentRow: root.allowWrap ? flowContainer : rowContainer

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
        // A child's actual on-screen width is its own Layout.preferredWidth
        // when explicitly set — several content children here (e.g. every
        // SpinBox in a shared column, via Layout.preferredWidth:
        // dataPage.inputWidth * 0.4) pin one specifically so every sibling
        // in that column renders the same width regardless of its own
        // text. Raw implicitWidth doesn't capture that: it's the child's
        // OWN natural/intrinsic width from its current content (e.g. a
        // SpinBox's implicitWidth grows or shrinks with the text it
        // currently shows, "7" vs "Auto"), which can differ between rows
        // even when their actual rendered width is pinned identical by
        // Layout.preferredWidth. Feeding raw implicitWidth into the
        // icon-column math below fed that per-row difference straight
        // through, giving two rows a different "content width before the
        // icon" even though what was on screen was identical — which is
        // exactly what pushed one row's icon to the right of the other's.
        function _childEffectiveWidth(c) {
            if (c && c.Layout && c.Layout.preferredWidth > 0) return c.Layout.preferredWidth;
            return c ? c.implicitWidth : 0;
        }
        readonly property real _contentMinWidth: !root.allowWrap ? contentRow.implicitWidth : root._widestContentChild()
        function _widestContentChild() {
            let m = 0;
            for (let i = 0; i < contentRow.children.length; i++) {
                let c = contentRow.children[i];
                if (c && c.visible !== false) m = Math.max(m, root._childEffectiveWidth(c));
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
        // naturalPreIconWidth comment above for why). Uses each child's
        // effective (actually rendered) width via _childEffectiveWidth,
        // not raw implicitWidth — see that function's comment for why:
        // in short, a child's own implicitWidth can vary with its current
        // content (e.g. a SpinBox showing "7" vs "Auto") independently of
        // what's actually on screen once Layout.preferredWidth pins it,
        // and using implicitWidth here fed that phantom difference
        // straight into the icon's position.
        function _computeNaturalPreIconWidth(icon) {
            if (!icon) return 0;
            let sum = 0;
            let visibleCount = 0;
            for (let i = 0; i < contentRow.children.length; i++) {
                let c = contentRow.children[i];
                if (c === icon) continue;
                if (c.visible === false) continue;
                sum += root._childEffectiveWidth(c);
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

        // For allowWrap rows, contentRow is a Flow, not a RowLayout — a
        // plain QtQuick positioner that has no idea what the
        // QtQuick.Layouts attached properties (Layout.preferredWidth/
        // Height) mean. It sizes children from their own real width/height
        // only. Every content child across the config pages was written
        // assuming a RowLayout parent though (which is what non-wrap rows
        // actually get now, so they need none of this): several are
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
            // RowLayout (the !allowWrap branch) already understands
            // Layout.preferredWidth/Height natively; this mirroring hack
            // is only needed to compensate for Flow not understanding them.
            if (!root.allowWrap) return;
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

        // Historically this corrected Flow's lack of vertical centering
        // for allowWrap:false rows (Flow always top-aligns; RowLayout
        // doesn't). That correction ran a frame after Flow's own layout
        // pass (via Qt.callLater below), which is exactly what produced
        // the visible "icon starts high, then snaps down" flash: two
        // separate rendered frames instead of one.
        //
        // Now that allowWrap:false rows use a real RowLayout (see
        // contentRow above), that RowLayout centers its children natively,
        // in the same pass as its own layout — no JS, no second frame, no
        // flash. allowWrap:true rows still use Flow, but per the original
        // comment below they never needed this correction either (they're
        // groups of same-weight items, e.g. checkboxes, where the
        // raised-icon symptom doesn't occur). So this is intentionally a
        // no-op for both branches now; kept (rather than deleted) only so
        // forceRelayout() and Flow's onHeightChanged below still have a
        // safe, documented target to call.
        function _centerFlowChildren() {
            return;
        }

        Component.onCompleted: {
            // Only allowWrap rows need to move: their children were
            // declared onto rowContainer by the default alias above (like
            // every row), but actually belong on flowContainer. The
            // overwhelmingly common allowWrap:false case needs no move at
            // all — its children are already exactly where they belong,
            // parented there since construction, same as v0.
            if (root.allowWrap) {
                let kids = rowContainer.children.slice();
                for (let i = 0; i < kids.length; i++) {
                    kids[i].parent = flowContainer;
                }
            }
            root._syncFlowChildSizes();
            root._refreshPreIconWidth();
            root._centerFlowChildren();
            root._watchChildVisibility();
        }

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

        // The !allowWrap case (the default, and every pre-existing row,
        // including all the forecast-range rows): a real RowLayout, so
        // vertical centering of mixed-height children (e.g. a small
        // InfoIcon next to a taller SpinBox) is handled natively by the
        // Layouts engine in the same pass as everything else — identical
        // to the old v0 behaviour, and with no JS correction there's
        // nothing that can render one frame late (the "icon starts high,
        // then snaps down" flash this whole rewrite exists to fix).
        //
        // Also doubles as the parking spot for allowWrap:true rows' children
        // between construction and Component.onCompleted's move to
        // flowContainer (see above) — hence visible: false for that case,
        // which keeps it (and them) out of any layout computation in the
        // meantime, exactly like a dedicated neutral holder would.
        RowLayout {
            id: rowContainer
            visible: !root.allowWrap
            Layout.fillWidth: false
            spacing: root.contentSpacing
            onChildrenChanged: { Qt.callLater(root._refreshPreIconWidth); root._watchChildVisibility(); }
        }

        // The allowWrap:true case (e.g. a handful of checkboxes): Flow,
        // given Layout.fillWidth: true so it gets the row's actual
        // available width and can wrap children onto additional lines
        // once they no longer fit on one. Flow tops-aligns instead of
        // centering, but per _centerFlowChildren's comment above that was
        // never an issue for this same-weight-items use case, so it's
        // left uncorrected exactly as before.
        Flow {
            id: flowContainer
            visible: root.allowWrap
            Layout.fillWidth: root.allowWrap
            spacing: root.contentSpacing
            onChildrenChanged: { root._syncFlowChildSizes(); Qt.callLater(root._refreshPreIconWidth); Qt.callLater(root._centerFlowChildren); root._watchChildVisibility(); }
            onHeightChanged: Qt.callLater(root._centerFlowChildren)
        }
}
