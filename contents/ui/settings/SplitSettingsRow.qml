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
//      under its own two margins. If there truly isn't enough total width
//      for both sides' margins, the remaining space is split in proportion
//      to how much each side needs, as the best available compromise (this
//      can only happen if the whole card no longer fits the window at all).
//
// This collapses into one rule: center each block within its available
// zone (outer margin <-> separator's inner margin). Nothing changes in the
// common case; everything above is just what "center, then give ground"
// means as things get tight.
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

    readonly property real leftNaturalWidth: leftItem ? leftItem.implicitWidth : 0
    readonly property real rightNaturalWidth: rightItem ? rightItem.implicitWidth : 0

    // Each side needs its own two margins accounted for: one against the
    // card's outer edge, one against the separator. Counting only one (as
    // the previous version did) let the separator creep in until content
    // touched it directly, with zero breathing room on that side.
    readonly property real _leftNeed: leftNaturalWidth + edgeMargin * 2
    readonly property real _rightNeed: rightNaturalWidth + edgeMargin * 2

    // Where the separator sits, in local x coordinates. See the file
    // header above for the reasoning.
    readonly property real separatorX: {
        if (width <= 0) return 0;
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
        // letting one side win arbitrarily.
        let total = _leftNeed + _rightNeed;
        return total > 0 ? width * (_leftNeed / total) : ideal;
    }

    readonly property real _contentHeight: Math.max(
        leftItem ? leftItem.implicitHeight : 0,
        rightItem ? rightItem.implicitHeight : 0)

    implicitHeight: _contentHeight
    Layout.minimumWidth: _leftNeed + _rightNeed + separatorThickness
    Layout.preferredWidth: 2 * Math.max(_leftNeed, _rightNeed)

    // Left zone runs from the outer margin to the separator's inner margin.
    // Center leftItem in that zone; Math.max(0, ...) means: if the zone is
    // ever narrower than the content (only possible in the degraded
    // proportional-split branch above, when the card is too small for
    // everything), fall back to flush-left instead of a negative offset.
    readonly property real _leftZoneWidth: root.separatorX - root.edgeMargin * 2
    readonly property real _rightZoneWidth: root.width - root.separatorX - root.edgeMargin * 2

    Binding {
        target: leftItem; property: "x"
        value: root.edgeMargin + Math.max(0, (root._leftZoneWidth - root.leftNaturalWidth) / 2)
        when: leftItem !== null
    }
    Binding { target: leftItem; property: "y"; value: leftItem ? (root.height - leftItem.implicitHeight) / 2 : 0; when: leftItem !== null }
    Binding { target: leftItem; property: "width"; value: root.leftNaturalWidth; when: leftItem !== null }

    Binding {
        target: rightItem; property: "x"
        value: root.separatorX + root.edgeMargin + Math.max(0, (root._rightZoneWidth - root.rightNaturalWidth) / 2)
        when: rightItem !== null
    }
    Binding { target: rightItem; property: "y"; value: rightItem ? (root.height - rightItem.implicitHeight) / 2 : 0; when: rightItem !== null }
    Binding { target: rightItem; property: "width"; value: root.rightNaturalWidth; when: rightItem !== null }

    Kirigami.Separator {
        x: root.separatorX
        y: 0
        width: root.separatorThickness
        height: root.height
        opacity: root.separatorOpacity
    }
}
