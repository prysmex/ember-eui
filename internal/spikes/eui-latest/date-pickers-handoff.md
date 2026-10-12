# Date pickers family migration handoff (SuperDatePicker, DatePickerRange, RefreshInterval)

Branch `eui-wave/date-pickers`. Target EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated**. Full core suite 898/898 in Chromium 130, parity 217/217, types and lint pass.

## Scope

EuiSuperDatePicker and its private pieces (update button, range, quick select popover, quick select, commonly used, recently used, date popover button/content, absolute/relative/now tabs, the absolute tab calendar `datetime-picker.gts`), EuiDatePickerRange and EuiRefreshInterval. Behavior (date math, drafts, auto refresh, `onTimeChange`/`onRefresh`/`onRefreshChange` payloads) is unchanged. The calendar engines (`ember-flatpickr`/`ember-pikaday`, `packages/flatpickr`, `packages/pikaday`) were not touched; EuiDatePickerRange only lays them out.

## Files

- Components (`packages/core/src/components/`), all style-computing pieces are Glimmer classes with `@cached` class getters and factories read through `useEuiBorealisStyles`:
  - `eui-super-date-picker.gts`, `eui-date-picker-range.gts`, `eui-refresh-interval.gts`
  - `eui-super-date-picker/eui-super-update-button.gts`, `eui-date-picker-range.gts` (private), `eui-quick-select-popover.gts`
  - `eui-super-date-picker/eui-quick-select-popover/{eui-quick-select,eui-commonly-used-time-ranges,eui-recently-used}.gts`, **new** `eui-quick-select-panel.gts` (upstream `EuiQuickSelectPanel`, private)
  - `eui-super-date-picker/date-popover/{eui-date-popover-button,eui-date-popover-content,absolute-tab,relative-tab,now-tab,datetime-picker}.gts`
- `packages/core/src/utils/eui/date-pickers.ts` (new, upstream license header): hand port of `react_date_picker.styles.js` (`euiDatePickerVariables`, `euiReactDatePickerStyles`), the module-level styles of `quick_select.js` (`euiQuickSelectStyles`), and the scoped `fieldset`/`legend`/list resets.
- `scripts/generate-eui-styles.mjs`, `// date pickers` block: `euiDatePickerStyles`; `euiDatePickerRangeStyles`, `euiDatePickerRangeInlineStyles`; `euiSuperDatePickerStyles`; `euiDatePopoverButtonStyles`; `euiDatePopoverContentStyles`; `euiAbsoluteTabDateFormStyles`; `euiQuickSelectPanelStyles`; `euiQuickSelectPopoverStyles`; `euiFormAppendPrependStyles` (upstream `EuiFormPrepend`). Helpers for the hand port: `global_styling/index.js` → `euiButtonColor`, `euiButtonEmptyColor`, `euiButtonFillColor`, `euiCanAnimate`, `mathWithUnits`; and `components/form/form.styles` (extension-less key, so the form-controls entry is not edited) → `euiFormControlText`, `euiFormControlDefaultShadow`. The generator now extracts 251 factories/helpers. `styles.generated.ts` and `upstream-sources.json` regenerated (worktree `../../Users/...` provenance comments normalized back to `// node_modules/...` with sed); the rest of the diff is esbuild `_refN` renumbering.
- `scripts/eui-upstream-parity.test.mjs`: the 10 new factories plus `euiFormControlText`/`euiFormControlDefaultShadow` join the 12-configuration matrix; new tests "date picker hand ports match upstream react-datepicker and quick select styles" (registered `@emotion/css` class name + styles compared byte for byte in 12 configurations; `quick_select.js` static names/styles read from upstream's compiled source) and "date picker style helpers match upstream button colors, animation and math".
- Tests: new `packages/core/tests/integration/components/eui-date-pickers-test.gts` (module `Borealis date pickers`, 12 tests); legacy assertions updated in `eui-super-date-picker-test.gts` and `eui-date-picker-range-test.gts` (below).
- Docs: regenerated API sections of `docs/forms/{super-date-picker,date-picker-range}/index.md`.

## Why the react-datepicker styles are a hand port

Upstream builds `euiReactDatePickerStyles` with vanilla `@emotion/css` (it hands a class name to react-datepicker). The generator only adapts `@emotion/react`; bundling `@emotion/css` would register classes in Emotion's global cache at call time. Per the brief the adapters were not patched: the port is upstream's code with `css` serializing instead (nested helpers return the serialized string so the outer interpolation is identical to upstream's registered-class lookup). Parity proves `css-${port.name} === upstream` and identical registered styles in every mode/contrast/override combination.

## API and default changes (latest-only)

### EuiSuperDatePicker
- **Root is now upstream's `div.euiSuperDatePicker`** (flex, `gap: s`), carrying `...attributes` (new `Element: HTMLDivElement`; the signature is now `{ Element, Args }`, `EuiSuperDatePickerArgs` is still exported). Before: an EuiFlexGroup `.euiSuperDatePicker__flexWrapper` with the `euiSuperDatePicker` class on the inner layout.
- **Widths are upstream's:** restricted = `30 × base + gap + 7 × base` (600px), without the update button 480px; `full` 100%; `auto` inline-flex with `min-width: min(320px, 100%)` (200px without button); `@isQuickSelectOnly` forces auto, hides the start/end buttons and the delimiter. Below the `m` breakpoint width is 100% (upstream).
- Removed legacy classes: `euiSuperDatePicker__flexWrapper(--noUpdateButton|--isAutoRefreshOnly|--isQuickSelectOnly|--fullWidth|--autoWidth)`, `euiDatePickerRange--inGroup`, `euiDatePickerRange--isInvalid/--isDisabled/--readOnly/--fullWidth`, `euiDatePickerRange__delimeter`, `euiQuickSelectPopover__content`, `euiQuickSelectPopover__section`. Kept/added (upstream): `euiSuperDatePicker`, `euiSuperDatePicker--needsUpdating`, `euiDatePickerRange`, `euiDatePopoverButton(--start|--end|--compressed|-isSelected|-isInvalid|-needsUpdating|-disabled)`, `euiSuperDatePicker__startPopoverButton`, `euiSuperUpdateButton`, `euiQuickSelectPopover`, `euiQuickSelectPopover__anchor`, `euiQuickSelectPopover__sectionItem`.
- The range is upstream `EuiDatePickerRange isCustom` → `EuiFormControlLayoutDelimited` (fullWidth, compressed, disabled, invalid with warning icon, loading spinner only when `@showUpdateButton={{false}}`), with the super date picker state styles composed onto the range wrapper: **default / disabled / invalid (danger text and outline) / needs updating (success outline and text)**. Open or focused date buttons get the 2px focus outline.
- Start/end buttons: upstream `euiDatePopoverButton` styles (fill the cell, `s` font, `s` inline padding, ellipsis), `now` popover narrower (`flex-grow: 0.5`), `data-test-subj="superDatePicker{start|end}DatePopoverButton"`. **Title** is upstream's: `Invalid date: …` / `Update needed: …` / the date (i18n `euiDatePopoverButton.invalidTitle/outdatedTitle`). The end button now gets `euiSuperDatePicker__endPopoverButton` (it wrongly carried `__startPopoverButton`).
- Quick select button: upstream `EuiFormPrepend element="button"` (calendar + arrow icons, `aria-label` "Date quick select" via `euiQuickSelectPopover.buttonLabel`, `data-test-subj="superDatePickerToggleQuickMenuButton"`, tooltip without screen reader output). Was an EuiButtonEmpty with only the icons (no accessible name).
- New args: `@recentlyUsedRanges` (was commented out; shows the "Recently used date ranges" panel), and `@timeFormat`/`@utcOffset` are now forwarded to the date buttons (they were declared but dropped).
- Not ported (no Ember counterpart, unchanged): pretty duration display (`showPrettyDuration`), `isAutoRefreshOnly` rendering (`EuiAutoRefresh`), auto refresh append button, time window buttons, `customQuickSelectPanels/Render`, `minDate/maxDate`, timezone display, `canRoundRelativeUnits`, `updateButtonProps`, `onFocus`. `@isAutoRefreshOnly` still only applies upstream's width rule.
- **The needs-updating check icon is not shown**: upstream puts `checkCircle` on the right of the delimited layout, but `EuiFormControlLayoutDelimited` has no `@iconSide` (form-controls family; see Unresolved).

### EuiSuperUpdateButton (private)
- Upstream labels via i18n (`euiSuperUpdateButton.refreshButtonLabel/updateButtonLabel/updatingButtonLabel`), icon `push` while an update is pending/loading (was `kqlFunction`), `data-test-subj="superDatePickerApplyTimeButton"`, `min-inline-size: 118px`, **`@fill` defaults to `true`** (upstream), size defaults to `m`.
- `iconOnly`: still an EuiButtonIcon (filled when `@fill`), now with the label as `aria-label` (it had no accessible name) and `@isLoading`. Upstream renders an EuiButton with screen-reader-only text; the box is the same 40/32px square.
- Not ported: the "Click to apply"/"Cannot update" tooltip, responsive icon-only breakpoints.

### Quick select popover
- Content: `div.euiQuickSelectPopover` (form max width 400px, `data-test-subj="superDatePickerQuickMenu"`) with upstream **panels**: each is an `EuiQuickSelectPanel` (fieldset, divider/padding/margin between panels, `xxxs` title as the `<legend>`, scrollable section 12 × `m` max height with the `s` font). The `EuiHorizontalRule`s between sections were removed (the panels draw the dividers).
- Quick select: previous/next buttons positioned above the inputs (upstream absolute styles; the wrapper div carries them because EuiFlexGroup has no `@css`), tooltips with `@disableScreenReaderOutput`, **Enter in any field applies** (upstream), value input sanitized to an integer (empty → 0, which disables Apply), `aria-describedby` with the upstream screen-reader summary ("Currently set to last 15 Minutes."), `data-test-subj="superDatePickerQuickSelectApplyButton"`. Kept the Ember ±1ms step offsets and `arrowLeft/arrowRight` icons (upstream `chevronSingle*` are not in the bundled set).
- Commonly used: upstream `data-test-subj="superDatePickerCommonlyUsed_<label>"`, titles from i18n.
- Recently used: renders nothing when empty (upstream); one column; shows `range.label`, or `start → end` (upstream shows a pretty duration, which Ember does not have).

### Date popover
- Content: `euiDatePopoverContent` width 400px (284px below `s`). Tab-level `data-test-subj`/`aria-label` (upstream `superDatePickerAbsoluteTab` etc.) are **not** set: EuiTabbedContent does not forward per-tab attributes (navigation family). Switching tabs does not call `onChange` (upstream converts the value on tab click; Ember kept its behavior).
- Absolute tab: the calendar keeps the Ember-built markup (`react-datepicker__*` classes) and now gets upstream `euiReactDatePickerStyles` (32px days with control radius, medium weight, today primary/bold, outside-month subdued, selected = filled primary button colors, time list on `backgroundBaseSubdued` with selected filled item, absolute month/year header) and upstream `EuiDatePicker inline shadow={false}` styles (no frame). Month navigation buttons are now `EuiButtonIcon`s (`sortLeft/sortRight`, size s, color text) with the same `aria-label`s; month/year selects are full-width compressed EuiSelects with `aria-label` "Month"/"Year" (the extra legacy `read-view` wrappers were removed). `@iconClasses` of the private DatetimePicker is deprecated (no effect). The text input sits in upstream's `euiAbsoluteTabDateForm` padding, labelled by the prepend label (`aria-labelledby`), `data-test-subj="superDatePickerAbsoluteDateInput"`.
- Relative tab: padding `s` (upstream `useEuiPaddingCSS().s`), number/unit inputs get upstream `aria-label`s ("Time span amount", "Relative time span"), `aria-describedby` screen-reader text, `data-test-subj`s, `@isInvalid` on an empty/negative count; the read-only preview is labelled by its prepend label; the round switch gets `superDatePickerRelativeDateRoundSwitch`.
- Now tab: padding `m`, button `data-test-subj="superDatePickerNowButton"`. Now a Glimmer class (was template-only).

### EuiDatePickerRange (public)
- Upstream structure: `div.euiDatePickerRange` → `EuiFormControlLayoutDelimited`. Blocks and yielded classes are unchanged in shape: `<:start>`/`<:end>` still yield `euiDatePicker euiDatePickerRange__start|__end`, now plus the delimited input class (centered, borderless, full height).
- **Default `@iconType` is `true` → a `calendar` icon at the start (upstream).** Pass `@iconType={{false}}` for the old look, or an icon name.
- New args (upstream): `@compressed`, `@disabled`, `@isInvalid`, `@isLoading`, `@iconType`, `@delimiter`. `@fullWidth`/`@readOnly` now style the delimited layout; `--fullWidth`/`--readOnly` classes and `__delimeter` removed (delimiter is upstream `.euiFormControlLayoutDelimited__delimiter`). The default block still replaces the whole layout.
- Not ported: `inline`/`shadow` (the Ember calendars render their own popups), `prepend`/`append`, `onFocus/onBlur` forwarding.

### EuiRefreshInterval
- Rendered as an `EuiQuickSelectPanel` fieldset (class `euiRefreshInterval`), so inside the quick select it gets the panel divider. Fields are compressed **full width** with upstream `min-width` 60/100px flex items, `wrap`, `alignItems: center`; the value is `aria-invalid` while running with an empty/≤0 value (upstream). Labels via i18n tokens (`euiRefreshInterval.valueAriaLabel/unitsAriaLabel`, same English text).
- **Kept the Ember Start/Stop button** (and its `data-test-subj="superDatePickerToggleRefreshButton"`), the legend "Refresh every" and the screen-reader text. Upstream 123 replaced them with an `EuiSwitch` labelled "Refresh every" and disables the fields while paused; adopting that would change the control's role and the documented interaction, so it is left for a decision.

### Scoped resets
No React global reset: date/quick select buttons use the shared form-controls `buttonReset` plus the Borealis font; panels reset `fieldset`/`legend`; the calendar resets `ul` and box sizing via `:where()` so upstream rules win.

## Existing test changes
- `eui-super-date-picker-test.gts`: `__flexWrapper--noUpdateButton` class → computed root width 480px (upstream restricted width without the button).
- `eui-date-picker-range-test.gts`: `--fullWidth` → computed `max-width: 100%` on the delimited layout; `input:first-child/:last-child` → the inputs by label (a calendar icon now comes first) and the delimited input class; `__delimeter` → upstream `__delimiter`; `--readOnly` with a default block → the default block replaces the layout (no delimited layout/delimiter rendered), which is what that test exercises.
- No other assertion was weakened; the refresh interval and remaining super date picker tests pass unchanged.

## New coverage (`Borealis date pickers`, 12 tests)
Widths (restricted/no button/full/auto/quick select only, measured), layout height/radius/compressed, popover button geometry/typography/padding/now growth/test subjects, delimiter color, quick select prepend button (label, icons, padding normal/compressed, color); disabled/invalid/loading states (tokens, outline, warning icon, spinner placement); selected outline and needs-updating (success outline/text, titles, update colors, apply then refresh); update button variants (fill/base/icon only/needs update/loading/disabled, reactive without replacement); quick select panels (dividers, legends, title typography, section scroll), Enter applies, aria-describedby summary, commonly/recently used; refresh interval panel/fieldset reset/full-width compressed fields/invalid while running; date popover tabs, calendar computed styles (days, selected, outside month, time list, navigation), absolute input labelling, picking a day, relative inputs/labels/invalid, now tab; keyboard/aria (DOM tab order, `aria-expanded`/`aria-controls`, Escape closes, tab ArrowRight); reactive args in place; light/dark nearest provider, light island, sibling isolation, JS-object overrides (radius, mode-specific `textSubdued`), dark popover dividers; RTL ordering; preferred high contrast (group border, thicker invalid); EuiDatePickerRange (icon default/none, compressed, invalid, disabled, read-only, custom delimiter, full width, centered inputs).

## Checks (worktree, Chromium 130, CI=true, Node 22; pnpm unavailable, binaries run directly)
- Family filtered run (`/date.picker|refresh-interval|super-date|Borealis date/`): 27/27.
- Full core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **898 tests, 898 pass, 0 fail**.
- `node --test scripts/eui-upstream-parity.test.mjs`: **217/217** (14 new).
- `node scripts/generate-eui-styles.mjs --check`: expected worktree-only failure (symlinked `node_modules` provenance paths); regenerated and normalized.
- `ember-tsc --noEmit`: pass. ESLint on all changed sources/tests: pass.
- `node scripts/generate-api-docs.mjs --check`: my two pages regenerated; it still reports `docs/display/list-group/index.md` out of date — **pre-existing on the base** (`@externalIconClass` → `@externalIconCss` from the lists/@css work), not touched here.
- Not run (coordinator): rollup build, site build/acceptance, showcase screenshots.

## Unresolved / for the coordinator
1. **EuiFormControlLayoutDelimited needs `@iconSide`** (form-controls family) to show upstream's needs-updating `checkCircle` icon on the right of the super date picker.
2. **EuiTabbedContent per-tab attributes** (navigation family): upstream gives each date popover tab `data-test-subj` and `aria-label` ("Start date: Absolute").
3. **EuiFlexGroup/EuiTitle/EuiText/EuiFormRow lack `@css`**: the quick select time-window positioning sits on a wrapper div, the panel title composes EuiTitle styles itself (single class, `euiTitle` kept), and the now/relative/absolute paddings sit on wrappers/EuiForm. Visually equivalent.
4. **Refresh interval toggle**: upstream switched to an `EuiSwitch` and disables the fields while paused. Decide whether to follow (behavior/a11y change) — kept Start/Stop here.
5. **Icons**: `chevronSingleDown`, `chevronSingleLeft/Right`, `checkCircle` are not in the bundled set (`arrowDown`, `arrowLeft/Right` used).
6. **Escape focus return**: after Escape on a date popover the trigger's `aria-expanded` resets, but focus did not reliably return to the button within 2s in tests (EuiPopover returns focus only while `isOpenStable`); overlays family to check.
7. Calendar a11y (days as `div role=button` without keyboard support) is unchanged Ember behavior; upstream's react-datepicker keyboard grid is not ported.
8. Upstream recently-used labels use `PrettyDuration`, absent in Ember.
