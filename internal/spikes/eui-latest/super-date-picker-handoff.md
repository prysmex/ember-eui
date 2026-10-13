# EuiSuperDatePicker / EuiDatePickerRange upstream gaps handoff

Branch `eui-wave/super-date-picker`, based on `7d42c225`. Target EUI 123.1.0. This closes the docs audit gaps for EuiSuperDatePicker and EuiDatePickerRange. Every gap listed in the audit exists in 123.1.0, so none were skipped. No dependencies were added. Date math still uses `moment` and `@elastic/datemath`. The absolute tab keeps its Ember calendar.

## Files

- `src/components/eui-super-date-picker.gts`: new args and a new block (see API). It also has an `appliedStart`/`appliedEnd` pair, which is upstream's props as opposed to the draft.
- New private components:
  - `eui-super-date-picker/eui-time-window-buttons.gts`: upstream `EuiTimeWindowButtons`, a segmented `EuiButtonGroup` with tooltips.
  - `eui-super-date-picker/date-popover/eui-time-zone-display.gts`: `EuiTimeZoneDisplay` and `useEuiUTCOffsetDisplay`.
- New `eui-super-date-picker/utils/time-window.ts`: a port of `useEuiTimeWindow`. It takes the i18n service as its first argument and exports `ZOOM_FACTOR_DEFAULT` and `ZOOM_DELTA_FALLBACK_MS`.
- `utils/index.ts`:
  - `isRangeInvalid(start, end, minDate?, maxDate?)` (upstream).
  - `isRelativeToNow`.
  - `useFormatTimeString(..., canRoundRelativeUnits)` (upstream).
- `types/global.d.ts`: `RefreshUnitsOptions`, `QuickSelectPanel`, and `OnRefreshChangeArgs.intervalUnits?`.
- Wiring through the popover pieces:
  - `eui-quick-select-popover.gts`: custom panels, the render block, `onRefreshChange`, `refreshMinInterval` and `intervalUnits`.
  - `eui-date-popover-button.gts` and `eui-date-popover-content.gts`: `minDate`, `maxDate`, `canRoundRelativeUnits`, `timeZoneDisplayProps` and `onFocus`.
  - `absolute-tab.gts` and `relative-tab.gts`: the time zone display, and the min/max calendar.
- `datetime-picker.gts`: days outside `minDate`..`maxDate` get `react-datepicker__day--disabled` and `aria-disabled="true"`, and clicking them does nothing.
- `eui-super-update-button.gts`: new `@color`, `@iconType`, `@label` (upstream `children`) and `@minWidth`. The 118px min width is now applied through `@css` instead of an inline `style`.
- `src/components/eui-date-picker-range.gts`: `@inline` and `@shadow`.
- `packages/core/package.json`: 3 app-js entries from rollup (time zone display, time window buttons, time-window util). An unrelated reordering of `eui-in-memory-table` that rollup produced was reverted.
- Tests: new `tests/integration/components/eui-super-date-picker-upstream-props-test.gts`, with 30 tests in 2 modules. No existing test was modified.
- Docs:
  - Super date picker demos were renumbered to follow upstream's order. New: `d04-custom-rendering`, `d08-time-window-buttons`, `d11-time-zone-display`, `d12-restricted-range`. Updated: `d02` (`updateButtonProps` fill switch), `d03` (custom panel), `d06` (refresh units with the render block).
  - Date picker range: new `d02-inline-display`; the later demos were renumbered.
  - Both API tables regenerated. The fixed rows were removed from `docs-audit-gaps.md`, which now has one row listing what is still missing.

## API (Ember shape)

**EuiSuperDatePicker**
- `@updateButtonProps`: `{ fill, color, size, iconType, iconOnly, className, children, minWidth, 'data-test-subj' }`. These win over the picker's own values, as upstream spreads them last.
- `@customQuickSelectPanels`: `[{ title, content }]`, where `content` is a component rendered with `@applyTime`. Panels render last, in an `EuiQuickSelectPanel`. Calling `@applyTime` makes a quick selection and closes the popover.
- `<:customQuickSelectRender as |panels|>` block. It yields `quickSelect`, `commonlyUsedRanges`, `recentlyUsedRanges`, `refreshInterval` and `customQuickSelectPanels` as components with no arguments. `refreshInterval` and `customQuickSelectPanels` render nothing when the picker lacks `@onRefreshChange` / `@customQuickSelectPanels`. Upstream passes `undefined` instead, but a component is safe to invoke.
- `@refreshIntervalUnits` and `@refreshMinInterval`, passed to EuiRefreshInterval (and to EuiAutoRefresh).
- `@showTimeWindowButtons`: `true`, or `{ showZoomOut, showZoomIn, showShiftArrows, zoomFactor }` (a number or `'25%'`).
  - It renders between the range and the update button, and not with `@isAutoRefreshOnly`.
  - It is disabled while the picker is disabled or the range is invalid.
  - It works on the applied `@start`/`@end`, like upstream's props.
- `@timeZoneDisplayProps`: `{ timeZone, date, customRender }`. `customRender` is a component that gets `@nameDisplay` (a component), `@utcOffset` and `@timeZoneName`. The display shows in the absolute and relative tabs.
- `@minDate` / `@maxDate` (moments): they invalidate the range and disable calendar days outside them.
- Extras that were not in the audit but are in upstream's props: `@canRoundRelativeUnits` and `@onFocus`.

**EuiDatePickerRange**
- `@inline` applies:
  - upstream `euiDatePickerRangeInlineStyles` and `responsive`;
  - no icon;
  - `@fullWidth` and `@compressed` ignored;
  - `formLayout` background, unless disabled. Here it is nested, because Ember's `EuiFormControlLayoutDelimited` has no `@css`.
- `@shadow` defaults to `true`.

## Deliberate behaviour changes (old → new, upstream ref)

1. **`@isAutoRefreshOnly` with `@onRefreshChange`**
   - Old: the full range, with only the width rule applied.
   - New: `EuiAutoRefresh`, as in `super_date_picker.tsx` `render()`.
   - Without `@onRefreshChange` it is unchanged, as upstream.
2. **`intervalUnits` in `@onRefreshChange`'s payload**
   - Upstream always sends it.
   - Here it is added only when the picker is given `@refreshIntervalUnits`, even as `undefined` (checked with `'refreshIntervalUnits' in this.args`). This is the upstream demo pattern.
   - Reason: the existing test "with @onRefreshChange the quick select shows the refresh interval" `deepEqual`s `{ refreshInterval, isPaused }`, and it must pass unmodified. **Decision for the coordinator:** always send it (upstream) and update that one assertion?
3. The update button's min width moved from an inline `style` to its class. The computed value is the same, and the existing 118px test passes.

## Ember differences / not ported

- **Not in the audit, still missing:**
  - `isDisabled={ display }` and the pretty duration button (`showPrettyDuration`). The second would change the default look, because upstream shows "Last 15 minutes" instead of the start/end buttons.
  - `quickSelectButtonProps`.
- **Auto refresh append button and the needs-updating `checkCircle` icon.** Both need `EuiFormControlLayoutDelimited` changes (form-controls family):
  - an `@isAppendProvided` override, because a conditional append block would otherwise remount the range and close the quick select popover;
  - `@iconSide`.
- **`updateButtonProps`:** `showTooltip`, `toolTipProps` and `responsive` are not ported, since the update button has no tooltip yet.
- **Time zone display:**
  - The inputs get `aria-describedby` only while a zone is shown. Upstream always sets it, even when the target is missing.
  - The label is an `EuiText` `div`; upstream uses a `span`.
  - The `s` padding is a two-property inline style (`paddingInline`, `paddingBlockEnd`) rather than a generated factory, to avoid churn in `styles.generated.ts`.
- **EuiDatePickerRange `@inline`:** it always uses the 268px container query. Upstream switches to `responsiveWithTimeSelect` when a child has `showTimeSelect`, which can't be detected from blocks.

## Checks (worktree, Chromium 130, CI=true)

- Full core suite: **1363/1363** (main 1333 + 30 new).
- `ember-tsc --noEmit`: pass.
- ESLint on the changed `.gts`/`.ts` files: pass.
- Parity `node --test scripts/eui-upstream-parity.test.mjs`: **349/349**.
- `generate-api-docs`: 2 pages updated; `--check` is clean.
- Rollup: run.
- **Not run**, per the brief: `sync-injected`, companion packages, the site build. The new demos, in particular the inline flatpickr demo for the date picker range, are **unverified in a site build**.

---

# Remaining gaps (branch `eui-wave/sdp-rest`, based on `00814a0a`)

This closes the row the first pass left in `docs-audit-gaps.md` (now removed): `isDisabled={ display }`, the pretty duration display, `quickSelectButtonProps`, the auto refresh append button, the update button's tooltip and `responsive`, and the needs-updating `checkCircle` icon. Every item exists in 123.1.0. Note that upstream has no `showPrettyDuration` prop: the pretty duration is internal state, on by default.

## What changed

- **Pretty duration** (`super_date_picker.tsx` `renderDatePickerRange`).
  - It shows when the range matches a commonly used range or is relative to now, and no date popover is open.
  - It renders an `EuiFormControlLayout`, not the delimited range, with the same prepend and append. Inside is an `EuiFormControlButton.euiSuperDatePicker__prettyFormat` (`data-test-subj="superDatePickerShowDatesButton"`) in a block `EuiToolTip`. The tooltip shows the full range, `start – end` in `@dateFormat`, with offset `base / 2`.
  - Clicking the button hides the pretty duration and opens the start popover, which mounts open, so the focus moves into it.
  - A quick selection recomputes the pretty duration, and so do new `@start`/`@end` (upstream `getDerivedStateFromProps`). With `@isQuickSelectOnly`, only the quick select shows. `@onFocus` fires on this button too.
  - New `prettyDuration(euiI18n, { timeFrom, timeTo, quickRanges, dateFormat })` in `utils/pretty-duration.ts` ports `usePrettyDuration`: quick range label, "Last/Next N units", "… rounded to the unit", then "{from} to {to}".
- **Focus.** `EuiDatePopoverButton` can now be controlled (`@isOpen`, `@onPopoverToggle`, `@onPopoverClose`), and the picker owns both popovers' open state, as upstream does.
  - Upstream EuiPopover's `handleStrandedFocus` is ported in the button: 250ms after it closes, a focus left on the body or in the closing panel moves to the button. This is how Escape from the start popover (opened from the pretty duration) returns to the start button.
  - Focus traps are untouched; popovers still join their trap through the registry.
- **`@isDisabled={{hash display=…}}`**: a string or a component. It replaces the dates, for any range, with a disabled pretty-format button (`euiSuperDatePicker__prettyFormat--disabled`). The type is `boolean | { display: string | ComponentLike }`.
- **`@quickSelectButtonProps`** (upstream `buttonProps` spread over `EuiFormPrepend`):
  - `label`, `iconLeft`, `iconRight` and `css` go to EuiFormPrepend. `aria-label` and `data-test-subj` replace the defaults, and `className` is added.
  - `onClick` runs after the popover toggles.
  - Other `on*` functions become event listeners, and any other key becomes an attribute (a private modifier).
- **Auto refresh append**: while `!isPaused` (upstream does not require `@onRefreshChange`), an `EuiAutoRefreshButton @shortHand` sits in the field's append, in both the pretty and the range layouts.
  - The block is always passed and switched with `@isAppendProvided`, so the quick select and an open quick select popover survive pausing and unpausing.
- **Needs-updating icon**: while the range has changed and is valid, the range gets `checkCircle` on the right (upstream `iconType` / `iconSide`).
- **`EuiFormControlLayoutDelimited`** (allowed for this task):
  - new `@iconSide`, `@isPrependProvided` and `@isAppendProvided`. The last two default to the block being passed, so existing users are unchanged.
  - The private SDP range forwards `<:append>`, `@iconSide` and `@isAppendProvided`.
- **`EuiSuperUpdateButton`**:
  - It is always wrapped in an `EuiToolTip` with position `bottom`. The content is "Cannot update" while disabled and "Click to apply" while an update is pending.
  - `showTooltip`: the tooltip shows on updates while an update is pending, and hides after 2s. The picker passes `true` while no date popover is open, and `updateButtonProps.showTooltip` overrides it.
  - `toolTipProps` is forwarded: `position`, `content`, `delay`, `display`, `anchorClassName`, `anchorCss`, `className`, `css`, `id`, `offset`, `title`, `disableScreenReaderOutput` and `repositionOnScroll`.
  - `responsive` defaults to `['xs', 's']`: on those sizes (`EuiShowFor`/`EuiHideFor`) the button collapses to its icon, as in upstream. `false` turns it off, and `iconOnly` forces `'all'`.
- **Recently used ranges** now show upstream's `PrettyDuration` ("Last 2 days") instead of `label ?? 'start → end'`. Upstream ignores `label` there.
- **`hasChanged`** compares a draft with the applied `@start`/`@end` (upstream `prevProps`), not with the previous draft. Setting a date back to the applied value clears "needs updating".
- `@isQuickSelectOnly` × `@isAutoRefreshOnly` was already upstream's `render()`, and it is now tested:
  - with `@onRefreshChange`, `EuiAutoRefresh` alone, in auto width;
  - without it, the quick select alone, with the update button, without the time window buttons.

## Deliberate behaviour changes (old → new, upstream ref)

1. **Relative and commonly used ranges render "Last 15 minutes"** in place of the start/end buttons until clicked (`renderDatePickerRange`, `showPrettyDuration`). This is the default look.
2. **The collapsed update button is an `EuiButton` with screen-reader-only text**, as in upstream's `EuiShowFor` branch (`minWidth={false}`, `textProps.className='euiScreenReaderOnly'`). It used to be an `EuiButtonIcon` with `aria-label`.
   - The full button's 118px minimum is an inline `min-inline-size` again, through `EuiButton @minWidth`, as in upstream's snapshot.
3. **Recently used labels**: from `'now-1y → now'` to "Last 1 year", from upstream `recently_used.tsx`.
4. **Focus after closing a date popover** returns to its button. Before, it could be stranded on the body.

## Existing tests changed

- **The setup clicks the pretty duration first**, as upstream's tests do ("renders an EuiDatePickerRange", "canRoundRelativeUnits"). The assertions are the same.
  - `eui-date-pickers-test`: a `showDates(key)` helper is used in widths, layout, states (`invalid`), needs-updating, keyboard, reactive, light/dark and RTL.
  - `upstream-props-test`: a `showDates()` helper is used in the time zone (Browser, customRender) and canRoundRelativeUnits tests.
- **Setups switched to absolute ranges**, to keep the assertions on the date buttons:
  - in `eui-date-pickers-test`, the states test's `disabled` picker (a disabled pretty button can't be clicked) and the widths test's `quick` picker (the delimiter assertion);
  - in the reactive test, the invalid range: `now`/`now-1h` → two absolute dates, because a relative one shows the pretty duration again.
- **Assertions changed:**
  - In `eui-date-pickers-test`:
    - **Needs-updating test:** it blurs before reading the state outline. The focus now returns to the start button, whose focus styles replace the outline, as upstream's `:has(:focus)` rule does.
    - **Update button variants and reactive (`iconOnly`):** before, `aria-label` was "Refresh" / "Update". Now `.euiScreenReaderOnly` has that text and the element is `.euiButton`.
    - **Recently used:** `['Last two days', 'now-1y → now']` → `['Last 2 days', 'Last 1 year']`.
  - In `upstream-props-test`:
    - **iconOnly:** before, `aria-label` was "Refresh" with no text. Now `.euiScreenReaderOnly` has "Refresh".
    - **`@isAutoRefreshOnly` without `@onRefreshChange`:** it asserts the pretty button, then shows the dates.
    - **`@onFocus`:** it also expects the pretty button's focus, as in upstream's test.
  - In `eui-super-date-picker-test`:
    - **"it renders" and "inverted range":** they click the pretty duration first.
    - **`@isDisabled` + no update button:** "start button disabled" → "pretty button disabled".
    - **"follows changes" and "selection is kept":** the start button titles became pretty duration texts:
      - "Last 15 minutes", "Last 3 hours", "Last 1 hour" (invalid, update disabled) and "Next 1 hour";
      - "This week" (kept across re-renders), then "Last 2 hours".
- No test of other `EuiFormControlLayoutDelimited` users was touched. The date picker range, form control layout and form controls tests pass unmodified.

## New tests

`tests/integration/components/eui-super-date-picker-pretty-duration-test.gts` has 22 tests in 2 modules. They cover:
- the pretty DOM and the tooltip;
- the `prettyDuration` texts;
- click → start popover → Escape → focus on the start button;
- quick selections and new arguments;
- absolute ranges and quick select only;
- `isDisabled` as `true`, a string and a component;
- `quickSelectButtonProps`: attributes, mousedown, onClick, label and icons, and upstream's collapse/expand scenario, where the popover stays open and gets the focus;
- the append button: "1 m" and "60 m", the interval popover and `onRefreshChange`, no remount, an open quick select surviving;
- the `checkCircle` icon on the right and not while invalid;
- the update button tooltip: "Cannot update", "Click to apply" for 2s, `toolTipProps`, `showTooltip: false`, `responsive` (all sizes, default, `['xs']`, `false` with `iconOnly`);
- `@isQuickSelectOnly` × `@isAutoRefreshOnly`;
- the delimited `@iconSide`, `@isPrependProvided` and `@isAppendProvided`.

## Docs

- New demos:
  - `d18-disabled-display` ("All time" switch);
  - `d19-quick-select-button-props`, which collapses to the quick select from upstream's `QuickSelectOnly` story. Upstream's website has no example for these props.
- `d02` text: responsive collapse and the "Click to apply" tooltip.
- The existing upstream demos (d01, d03, the KQL pattern and others) now show the pretty duration, as upstream's do.
- API tables regenerated for the super date picker and the form control layout delimited pages; `--check` is clean.

## Not ported, with reasons

- **The time zone display's `aria-describedby`** is set only while the zone shows. Upstream always sets it, pointing at a missing id.
- **The time zone label is a `div`.** Upstream's is `EuiText component="span"`, but EuiText (another family) has no tag argument.
- **The time zone padding is inline style instead of a factory.** There is no visible difference.
- **EuiDatePickerRange `@inline`** can't detect `showTimeSelect` from blocks, so it can't pick `responsiveWithTimeSelect`.
- **`EuiDatePopoverButton` keeps the `title` attribute** instead of upstream's `EuiToolTip` with `disableScreenReaderOutput`. This was not in the gap list.
- **The delimiter is still the `→` text**, where upstream has `EuiIcon sortRight` with `aria-label="to"`. Other families' tests assert the text and must pass unmodified.
- The coordinator decision from the first pass (`intervalUnits` in `@onRefreshChange` from the quick select) is unchanged.

## Checks (worktree, Chromium 130, CI=true)

- Filtered `date`: 146/146. Filtered `form`: 125/125.
- Full core suite: **1775/1775**.
- `ember-tsc --noEmit`: pass.
- ESLint on the changed files: pass.
- Parity: 356/356.
- `generate-api-docs`: 2 pages; `--check` is clean.
- Rollup: run; `package.json` is unchanged (no new source files).
- **Not run**, per the brief: sync-injected, companion suites and the site build. The new demos are **unverified in a site build**.

## Pretty duration is opt-in (user decision, 2026-10-13)

Upstream always shows a commonly used or relative range as the "Last 15
minutes" summary button. Ember EUI gates it behind `@showPrettyDuration`
(default `false`), so existing pickers keep showing the start/end dates.
The pretty-duration tests pass `@showPrettyDuration={{true}}`; the other
date picker tests are back to their pre-pretty-duration form, keeping only
the deliberate changes (screen-reader update button labels, "Last 2 days"
recently used text, focus returning to the start button). Demo d20.
