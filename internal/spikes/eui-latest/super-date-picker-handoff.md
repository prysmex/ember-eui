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
