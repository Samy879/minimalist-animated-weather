.pragma library

// RowWidthSync.js
//
// Shared width-alignment logic used by both SettingGroup.qml and
// SettingsCard.qml to keep their SettingRow children's label columns
// visually aligned. Factored out of SettingGroup.qml (the original,
// working implementation) so both containers share a single source of
// truth instead of maintaining two copies of the same ~25 lines.
//
// Contract expected from each child (see SettingRow.qml):
//   - naturalLabelWidth   (real, readonly)
//   - naturalContentWidth (real, readonly)
//   - labelWidth          (real, writable)
//   - visible             (bool)
//
// Optionally, for aligning a trailing InfoIcon across rows (see
// SettingRow.qml's _findTrailingIcon/_computeNaturalPreIconWidth):
//   - naturalPreIconWidth (real, readonly) — 0 if the row has no InfoIcon
//   - iconAreaWidth       (real, writable)
//
// Children that don't expose this contract (e.g. plain Items, spacers) are
// silently skipped, exactly as before. Children that expose naturalLabelWidth
// but not naturalPreIconWidth just don't participate in icon alignment.

function computeMaxWidths(children) {
    let maxLabelWidth = 0;
    let maxContentWidth = 0;
    let maxIconAreaWidth = 0;

    for (let i = 0; i < children.length; i++) {
        let child = children[i];
        // Intentionally NOT filtering on child.visible here: a row that is
        // temporarily hidden (e.g. "Coordinates:" in Automatic mode, or
        // "API Key:" for providers that don't need one) must still count
        // towards the shared label column width. Otherwise the column width
        // — and therefore every visible row's alignment — changes the moment
        // a conditional row is shown/hidden, causing the whole group to
        // visibly shift/recentre. Including hidden rows keeps the column
        // width constant regardless of which rows currently happen to be
        // shown, so toggling visibility only adds/removes vertical space,
        // never moves anything already on screen.
        if (child && typeof child.naturalLabelWidth !== "undefined") {
            maxLabelWidth = Math.max(maxLabelWidth, child.naturalLabelWidth);
            maxContentWidth = Math.max(maxContentWidth, child.naturalContentWidth);
            if (typeof child.naturalPreIconWidth !== "undefined") {
                maxIconAreaWidth = Math.max(maxIconAreaWidth, child.naturalPreIconWidth);
            }
        }
    }

    return { maxLabelWidth: maxLabelWidth, maxContentWidth: maxContentWidth, maxIconAreaWidth: maxIconAreaWidth };
}

// `getEffectiveLabelWidth` / `getEffectiveIconAreaWidth` are functions (not
// values) so the Qt.binding below stays live: they re-read the container's
// effective*Width property every time it changes, instead of freezing it at
// call time. `getEffectiveIconAreaWidth` is optional — SettingsCard/
// SettingGroup callers that don't care about icon alignment can omit it.
function bindLabelWidths(children, getEffectiveLabelWidth, getEffectiveIconAreaWidth) {
    for (let i = 0; i < children.length; i++) {
        let child = children[i];
        if (child && typeof child.labelWidth !== "undefined") {
            child.labelWidth = Qt.binding(getEffectiveLabelWidth);
        }
        if (getEffectiveIconAreaWidth && child && typeof child.iconAreaWidth !== "undefined") {
            child.iconAreaWidth = Qt.binding(getEffectiveIconAreaWidth);
        }
    }
}
