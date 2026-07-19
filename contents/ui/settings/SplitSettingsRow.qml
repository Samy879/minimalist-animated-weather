import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// SplitSettingsRow.qml
//
// Two content blocks (typically a SettingGroup) placed side by side and
// separated by a vertical Kirigami.Separator. Exists to handle translated
// strings of very different lengths gracefully:
//
//   1. By default, the separator sits dead-center and each side is
//      CENTERED within its own zone (from the card's outer margin to the
//      separator's inner margin) — the familiar look of a two-column grid.
//   2. As a side's content grows, its own centering margin shrinks first.
//      Once that margin hits zero, the content sits flush against whichever
//      edge it's closest to (its outer margin, or the separator) — it
//      never gets truncated or pushed past that edge.
//   3. Only once a side is genuinely too wide for the centered half it
//      would get — natural width plus its two margins (outer edge AND
//      separator side) exceeds half the row — does the separator itself
//      shift away from the middle to hand that side the room it needs. It
//      only takes as much as necessary, and never pushes the other side
//      under its own two margins.
//   4. If there STILL isn't enough total width for both sides side by side
//      (natural width + margins, summed) — e.g. the window has been
//      narrowed below what a two-column layout can honor without shrinking
//      either side below its own natural size — the row switches to a
//      STACKED layout: leftItem on top, rightItem below, each centered at
//      its own full natural width. This is what actually prevents
//      overflow/clipping in that case; previously the row kept demanding
//      full double-column width no matter what, which let the page's
//      window be resized narrower than the content could actually fit,
//      silently clipping the right-hand column against the page's
//      non-scrolling ScrollView.
//
// This collapses into one rule: center each block within its available
// zone (outer margin <-> separator's inner margin), and fall back to
// stacking the two zones vertically if there isn't room for both at once.
//
//   5. If only ONE side is actually visible (the other's `visible` is
//      false — e.g. it's still locked/hidden), there's nothing to share a
//      separator with: that lone side is centered across the ENTIRE row
//      instead of just its usual half, and the separator itself is hidden.
//      As soon as the other side becomes visible too, the layout falls
//      back to the normal two-column split above.
//
// Usage:
//   SplitSettingsRow {
//       leftItem: SettingGroup { id: someGroup; ... }
//       rightItem: SettingGroup { id: otherGroup; ... }
//   }
// `someGroup`/`otherGroup` keep their ids and can still be referenced
// elsewhere in the file (e.g. someGroup.maxLabelWidth) exactly as before.
Item {
    id: root

    Layout.fillWidth: true

    // Minimum breathing room kept between content and the card's outer
    // edge, and between content and the separator. Deliberately NOT zero:
    // per the request, we never let anything touch the edges outright.
    property real edgeMargin: Kirigami.Units.largeSpacing
    property real separatorThickness: 1
    property real separatorOpacity: 0.3
    // Vertical gap between leftItem and rightItem when stacked (see
    // `stacked` below).
    property real stackedSpacing: Kirigami.Units.largeSpacing

    property Item leftItem
    property Item rightItem

    // leftItem/rightItem are plain properties, not the default property, so
    // QML never auto-parents them into root's visual tree — without this,
    // they exist (their x/y/width bindings below still apply) but are never
    // actually part of the scene graph, hence invisible.
    onLeftItemChanged: if (leftItem) leftItem.parent = root
    onRightItemChanged: if (rightItem) rightItem.parent = root
    Component.onCompleted: {
        if (leftItem) leftItem.parent = root;
        if (rightItem) rightItem.parent = root;
    }

    readonly property real leftNaturalWidth: (leftItem && leftItem.visible) ? leftItem.implicitWidth : 0
    readonly property real rightNaturalWidth: (rightItem && rightItem.visible) ? rightItem.implicitWidth : 0

    readonly property bool leftVisible: !!(leftItem && leftItem.visible)
    readonly property bool rightVisible: !!(rightItem && rightItem.visible)
    // Vrai quand un seul des deux côtés a effectivement quelque chose à montrer (ex : l'un
    // des deux Loader de ConfigSupport.qml est encore verrouillé, donc invisible). Dans ce
    // cas il n'y a rien à partager avec un séparateur : l'unique élément visible doit
    // occuper — et être centré dans — TOUTE la largeur de la rangée, pas seulement dans la
    // "moitié" qui lui serait normalement réservée face à un second élément qui, lui,
    // n'affiche encore rien.
    readonly property bool singleSideVisible: leftVisible !== rightVisible

    // Each side needs its own two margins accounted for: one against the
    // card's outer edge, one against the separator (or, when stacked, one
    // against the outer edge on each side of that single column).
    readonly property real _leftNeed: leftNaturalWidth + edgeMargin * 2
    readonly property real _rightNeed: rightNaturalWidth + edgeMargin * 2

    // True once the width actually assigned to this row is less than what
    // both columns need side by side. Neither column is ever shrunk below
    // its own natural size (see SettingRow.qml's floor), so when there
    // isn't room to honor that AND keep both on one line, we stack them
    // instead of letting the second column overflow past the card's edge.
    //
    // This only reads root.width (the width the parent layout actually
    // handed us), never the other way around — Layout.minimumWidth below
    // is deliberately independent of `stacked`, so there's no feedback loop
    // between "how much width we ask for" and "how we lay out once we get
    // it".
    readonly property bool stacked: root.width > 0 && root.width < (_leftNeed + _rightNeed + separatorThickness)

    // Only ask the parent layout for enough room to fit the WIDER of the
    // two columns, not both at once. Requiring the full side-by-side width
    // unconditionally (the old behaviour) is what let this row's actual
    // content-minimum silently exceed the page's hardcoded
    // Layout.minimumWidth — nothing kept the two in sync, so the window
    // could be resized narrower than the row could actually accommodate,
    // and the excess got clipped instead of reflowed. Preferring, rather
    // than requiring, the side-by-side layout keeps the "two columns when
    // there's room" look without that mismatch.
    Layout.minimumWidth: Math.max(_leftNeed, _rightNeed)
    Layout.preferredWidth: 2 * Math.max(_leftNeed, _rightNeed)

    // Where the separator sits, in local x coordinates (side-by-side mode
    // only). See the file header above for the reasoning.
    readonly property real separatorX: {
        if (width <= 0 || stacked) return 0;
        let minSep = _leftNeed;
        let maxSep = width - _rightNeed;
        let ideal = width / 2;
        if (minSep <= maxSep) {
            // Both sides fit within a centered split (with margin to
            // spare, or exactly enough): keep the separator centered,
            // only nudging it toward whichever side actually needs it.
            return Math.max(minSep, Math.min(maxSep, ideal));
        }
        // Not enough total width for both margins at once: hand out what's
        // available in proportion to each side's actual need rather than
        // letting one side win arbitrarily. In practice `stacked` will
        // already be true before this branch is reachable, but it's kept
        // as a safety net for the transition frame.
        let total = _leftNeed + _rightNeed;
        return total > 0 ? width * (_leftNeed / total) : ideal;
    }

    readonly property real _sideBySideHeight: Math.max(
        leftVisible ? leftItem.implicitHeight : 0,
        rightVisible ? rightItem.implicitHeight : 0)
    readonly property real _stackedHeight:
    (leftItem ? leftItem.implicitHeight : 0)
    + (rightItem ? rightItem.implicitHeight : 0)
    + ((leftItem && rightItem) ? stackedSpacing : 0)

    implicitHeight: stacked ? _stackedHeight : _sideBySideHeight

    // Left/right zone widths, side-by-side mode only.
    readonly property real _leftZoneWidth: root.separatorX - root.edgeMargin * 2
    readonly property real _rightZoneWidth: root.width - root.separatorX - root.edgeMargin * 2

    Binding {
        target: leftItem; property: "x"
        value: (root.stacked || (root.singleSideVisible && root.leftVisible))
        ? root.edgeMargin + Math.max(0, (root.width - root.edgeMargin * 2 - root.leftNaturalWidth) / 2)
        : root.edgeMargin + Math.max(0, (root._leftZoneWidth - root.leftNaturalWidth) / 2)
        when: leftItem !== null
    }
    Binding {
        target: leftItem; property: "y"
        value: !leftItem ? 0 : ((root.stacked && !root.singleSideVisible) ? 0 : (root.height - leftItem.implicitHeight) / 2)
        when: leftItem !== null
    }
    Binding { target: leftItem; property: "width"; value: root.leftNaturalWidth; when: leftItem !== null }

    Binding {
        target: rightItem; property: "x"
        value: (root.stacked || (root.singleSideVisible && root.rightVisible))
        ? root.edgeMargin + Math.max(0, (root.width - root.edgeMargin * 2 - root.rightNaturalWidth) / 2)
        : root.separatorX + root.edgeMargin + Math.max(0, (root._rightZoneWidth - root.rightNaturalWidth) / 2)
        when: rightItem !== null
    }
    Binding {
        target: rightItem; property: "y"
        value: !rightItem
        ? 0
        : ((root.stacked && !root.singleSideVisible)
        ? (leftItem ? leftItem.implicitHeight + root.stackedSpacing : 0)
        : (root.height - rightItem.implicitHeight) / 2)
        when: rightItem !== null
    }
    Binding { target: rightItem; property: "width"; value: root.rightNaturalWidth; when: rightItem !== null }

    Kirigami.Separator {
        // Inutile de séparer un élément visible de rien du tout : masqué aussi tant qu'un
        // seul des deux côtés a quelque chose à montrer (voir singleSideVisible).
        visible: !root.stacked && !root.singleSideVisible && root.leftVisible
        x: root.separatorX
        y: 0
        width: root.separatorThickness
        height: root.height
        opacity: root.separatorOpacity
    }

    // Horizontal counterpart shown between the two stacked columns instead
    // of the vertical separator.
    Kirigami.Separator {
        visible: root.stacked && !root.singleSideVisible && leftItem !== null && rightItem !== null
        x: root.edgeMargin
        y: leftItem ? leftItem.implicitHeight + root.stackedSpacing / 2 : 0
        width: Math.max(0, root.width - root.edgeMargin * 2)
        height: root.separatorThickness
        opacity: root.separatorOpacity
    }
}
