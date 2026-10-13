# Form controls migration handoff (FieldText/Number/Password/Search, TextArea, Select, FormControlLayout family)

Status: **Migrated**. The full core suite passes in Chromium 130 (672/672), along with upstream parity, types, lint and the API docs check.

## Files

- Components, all now Glimmer classes on extracted factories, resolving their context with `getEuiThemeContext`:
  - `eui-field-text.gts`, `eui-field-number.gts`, `eui-field-password.gts`, `eui-field-search.gts`, `eui-text-area.gts`, `eui-select.gts`
  - `eui-form-control-layout.gts`, `eui-form-control-layout-icons.gts`, `eui-form-control-layout-custom-icon.gts`, `eui-form-control-layout-clear-button.gts`, `eui-form-control-layout-delimited.gts`
- `packages/core/src/utils/eui/form-controls.ts` (new, upstream license header): hand ports of the two pieces that live in React component modules: the custom icon's module-level `styles` and `getIconAffordanceStyles` (`_num_icons.js`). It also holds the scoped resets (control box sizing/margin, layout box sizing, button reset).
- `scripts/generate-eui-styles.mjs`, in a `// form controls` block: `euiFormVariables`, `euiFormControlStyles` (form.styles), `euiFieldTextStyles`, `euiFieldNumberStyles`, `euiFieldPasswordStyles`, `euiFieldSearchStyles`, `euiTextAreaStyles`, `euiSelectStyles`, `euiFormControlLayoutStyles`, `euiFormControlLayoutSideNodeStyles`, `euiFormControlLayoutIconsStyles`, `EuiFormControlLayoutClearButtonStyles`, `euiFormControlLayoutDelimitedStyles`, `euiFormControlLayoutDelimited__delimiter`, `euiFormControlLayoutDelimited__input`. The generator now extracts 50 factories. `styles.generated.ts` and `upstream-sources.json` were regenerated, not hand-edited. The only diffs to existing factories are esbuild `_refN` renames and the worktree's `node_modules` path comments.
- `scripts/eui-upstream-parity.test.mjs`:
  - All new function factories go through the existing 12-configuration matrix.
  - New static test for `euiFormControlLayoutDelimited__input`.
  - New test running upstream's `EuiFormControlLayoutCustomIcon` and `getIconAffordanceStyles` with React/Emotion stubbed. It checks the hand port's styles and every icon-count combination (16 flag masks × 3 icon sides).
- `packages/core/tests/integration/components/eui-form-controls-test.gts`: new, 15 computed-style/behavior tests.
- Existing tests updated, with the reason for each change:
  - `eui-field-text-test.gts`: `euiFieldText--withIcon/--fullWidth/--compressed/--isLoading/--inGroup`, `euiFieldNumber--withIcon` and `euiFieldPassword--withToggle` were legacy modifiers. They are replaced by structural checks (icon, spinner, toggle in `__append`, `--group` layout) and computed max-width/padding.
  - `eui-select-test.gts`: `euiSelect--fullWidth/--compressed/--isLoading/--inGroup` are replaced by computed max-width/line-height, the spinner, `aria-invalid`, `--group` and the in-group `box-shadow: none`.
  - `eui-text-area-test.gts`: `euiTextArea--resize*/--compressed/--fullWidth` are replaced by computed `resize`, padding and max-width.
  - `eui-field-search-test.gts`: `euiFieldSearch--isClearable` is replaced by the presence/absence of the clear button. The latter was already asserted next to it.
  - `eui-form-control-layout-test.gts`:
    - Removed classes: `--fullWidth/--compressed`, which are now computed styles. `--readOnly/--isDisabled` became upstream's `-readOnly/-isDisabled`.
    - `euiFormControlLayoutIcons--right` is gone, so the test selects icon groups by order.
    - `euiFormControlLayoutCustomIcon--clickable` is gone, so it selects the `button.euiFormControlLayoutCustomIcon`.
    - The misspelled `__delimeter` became upstream's `__delimiter`.
    - Added assertions that each side is wrapped in its `__prepend`/`__append` div.
    - The first test rendered a `@disabled` layout and then clicked its clear button. Upstream disables the clear button in a disabled layout, so that test now asserts the button is disabled. Clicking clear moved to a new, non-disabled test, "the clear button calls @clear".
- `packages/core/docs/forms/form-controls/*/index.md` (8 pages): only the generated API sections were regenerated.
- Not touched:
  - FormRow/FormLabel, checkables, EuiIcon, providers and shared utilities, the showcase, and other families' callers (ComboBox trigger, SuperSelect control, SuperDatePicker, DualRange, ColorPicker, Suggest).
  - `utils/css-mappings/eui-text-area.ts` and `eui-form-control-layout-clear-button.ts`: `css-mappings/index.ts` still imports them, but the components no longer do. The coordinator can delete them together with their registry entries.

## API and default changes (latest-only)

- **Legacy classes removed:**
  - Every `euiFieldText--*`, `euiFieldNumber--*`, `euiFieldPassword--*`, `euiFieldSearch--*`, `euiSelect--*` and `euiTextArea--*` modifier.
  - `euiFormControlLayout--fullWidth/--compressed/--readOnly/--isDisabled`, `euiFormControlLayoutIcons--right`, `euiFormControlLayoutCustomIcon--clickable`, `euiFormControlLayoutClearButton--small`.
  - `euiFormControlLayoutDelimited__delimeter`, now upstream's spelling `__delimiter`.
- **Classes kept or added (upstream):**
  - Root classes: `euiFieldText`, `euiFieldNumber`, `euiFieldPassword`, `euiFieldSearch`, `euiTextArea`, `euiSelect`, `euiFormControlLayout`, `euiFormControlLayout__childrenWrapper`, `euiFormControlLayoutIcons`, `euiFormControlLayoutCustomIcon(__icon)`, `euiFormControlLayoutClearButton(__icon)`, `euiFormControlLayoutDelimited(__input)`.
  - Upstream state classes: `euiFormControlLayout--group`, `-isDisabled`, `-readOnly`, `euiFormControlLayoutDelimited--isInvalid`.
- **Sizes:**
  - Controls are 40px tall (compressed 32px), with 12px (compressed 8px) inline padding plus 24px per icon on that side, through upstream's `--euiFormControlLeft/RightIconsCount`. Border radius is 8px.
  - Width is `max-width: 400px; width: 100%` (form width), and fullWidth is 100%.
  - The font is the Borealis `s` size.
  - The border is an inset 1px `box-shadow` in the `forms.border` color. Focus is a 2px `forms.borderFocused` outline. Invalid is a 1px `forms.borderInvalid` outline (2px in preferred high contrast). Disabled and read-only use the forms background/color tokens. The placeholder uses `forms.colorDisabled`.
- **Icons and layout:**
  - Icons are absolutely positioned per side (`inset-inline-start/end`), so they flip in RTL.
  - Upstream order on the end side: clear, spinner, invalid icon, custom icon, dropdown arrow.
  - Icons are always size `m`; compressed controls used `s` before.
  - The clear button is a 16px circle in `forms.clearButtonBackground` with the cross icon scaled to 0.5. Its default `aria-label` is "Clear input" (i18n token `euiFormControlLayoutClearButton.label`).
- **Prepend/append:** each block is now wrapped in an upstream `.euiFormControlLayout__prepend` / `__append` side node with dividers, padding and button sizing. The block still yields the same class string, so existing callers and the `Blocks` types are unchanged; the yielded class is now unstyled. Side wrappers render only when the caller passes the block.
- **New layout args:**
  - Public: `@isInvalid` (warning icon), `@isDropdown` (arrow, hidden while disabled/read-only, as upstream), `@iconsPosition` (`absolute`/`static`) and `@clearLabel`.
  - Private: `@isPrependProvided`/`@isAppendProvided`, `@isDelimited`, `@css`/`@wrapperCss`, used in place of the fields' old `@useGroup` workaround.
- **Invalid state:** every control sets `aria-invalid="true"` with `@isInvalid` (upstream `EuiValidatableControl`), and the fields pass `@isInvalid` to the layout, which adds upstream's danger warning icon. `...attributes` can still override `aria-invalid`, except on EuiFieldNumber (below).
- **EuiFieldNumber:**
  - Default `@step` is now `'any'` (upstream; it was the browser default `1`), so decimals are not natively `:invalid`.
  - Native invalidity (out of range, etc.) sets `aria-invalid`, re-checked when value/min/max/step change and on key up. Unlike upstream, it does not add the warning icon.
- **EuiFieldPassword:**
  - The default `@type` stays `'dual'` (upstream: `'password'`). This keeps Ember's documented default.
  - The toggle is focusable now; it was `tabindex="-1"`.
  - The toggle has upstream's i18n `aria-label`/`title` ("Show password as plain text…" / "Mask password"), is disabled with `@disabled`, and returns focus to the input after toggling.
  - `@readOnly` now sets `readonly` on the input. It was only applied as styling before.
  - The toggle uses `eye`/`eyeClosed`, because the bundled icon set has no `eyeSlash`.
- **EuiFieldSearch:**
  - Renders `type="search"` (upstream). It was `type="text"`.
  - Clear label: "Clear search input".
  - Enter fires both `search` and `change`; `@onSearch` is called once per value (the last searched value resets on input).
  - The icon is still `search`, because the bundled set has no `magnify`.
- **EuiSelect:** the arrow comes from `@isDropdown` (`arrowDown`; the bundled set has no `chevronSingleDown`) and is hidden while disabled. It uses `appearance: none`, zero block padding and a line height equal to the control height (38/30px in a group).
- **EuiTextArea:**
  - `@resize` is typed as the literal union.
  - Uses upstream `display: block`, `height: auto`, 12/8px padding and the theme line-height multiplier.
  - Still no layout wrapper. Upstream's `icon`/`isLoading`/`isClearable` props are not ported, and the Ember component never had them.
- **EuiFormControlLayoutDelimited:**
  - Now has `Element: HTMLDivElement` and forwards `...attributes`.
  - New `@isInvalid` (danger delimiter, invalid wrapper, warning icon) and `@isDisabled`.
  - `@useGroup` is deprecated and has no effect: it is always a group, as upstream.
  - Icons are `static`.
  - The yielded control class now includes upstream's delimited input styles (centered text, no border/shadow).
  - The delimiter is an EuiText-styled div (size s, subdued or danger) with upstream delimiter styles composed last. The default text `→` is kept; upstream uses a `sortRight` icon.
- **EuiFormControlLayoutCustomIcon:** adds `@disabled` and `@color`. Decorative icons get `pointer-events: none` and clickable ones `all`, as upstream.
- **EuiFormControlLayoutIcons** (private): one instance per side (`@side`), with `Element: HTMLDivElement`. `@iconSide` is deprecated in favor of `@side`.
- **Scoped resets:** there is no React global reset, so the following are scoped locally.
  - Controls: `box-sizing: border-box; margin: 0`.
  - Layout: border-box for itself and its descendants, through `:where()`.
  - Icon and clear buttons: the React `button` reset.
- **Not ported:** EuiForm `defaultFullWidth` context, `EuiFormAppend`/`EuiFormPrepend` string prepends, `dualToggleProps`, and the password toggle's EuiToolTip (a native `title` is used). Also not ported: autofill-specific tests (styles are present but need real autofill) and hover outlines (need trusted pointer).

## Checks run (2026-10-12, in this worktree)

Environment: Node 22.22.1. pnpm is unavailable, so binaries were run directly. Chromium 130 came from the scratchpad `bin` with `CI=true`.

- Core tests (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **672 tests, 672 pass, 0 fail**, including the 15 new tests.
- A first full run found 1 failure (the disabled-clear click above), fixed before the 672/672 run.
- `node --test scripts/eui-upstream-parity.test.mjs`: **46/46 pass**. That is 30 at base plus 16 new: 15 factories and 1 hand-port test. The base was 29 + 1 global, see the earlier handoffs.
- `node scripts/generate-eui-styles.mjs --check`: fails with "Stale generated artifact: styles.generated.ts" on the untouched base commit too. The cause is the worktree `node_modules` symlink path comments, as the brief expects. The coordinator should regenerate in the main checkout.
- `ember-tsc --noEmit`: pass. ESLint on all changed components, `form-controls.ts` and the six touched test files: pass.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating.
- Not run (root): the rollup core build, the site build/acceptance tests, and showcase/visual checks.

## What the new tests cover

- **Every input control** (text, number, password, search, select) × normal/compressed:
  - Measured height of the control and the layout.
  - Box sizing and reset margin.
  - Start/end padding including icon affordance.
  - Select line height, zero block padding and `appearance: none`.
  - Radius, Inter font, upstream font size (through a probe), paragraph color, background, and the inset border shadow.
  - 400px form width.
- **fullWidth:** text, select, textarea and delimited.
- **States:**
  - Invalid: `aria-invalid`, native validity, outline color/width/offset, warning icon and its affordance.
  - Focus, including focus winning over invalid.
  - Disabled: tokens, cursor and the state class.
  - Read-only: tokens, inset border and the state class.
  - Native `required` `:invalid`.
- **Placeholder color**, including disabled and dark mode.
- **Icons:**
  - Absolute positioning, logical insets and gap (normal and compressed), and the affordance CSS variables (zero counts omitted).
  - Pointer events.
  - Clear button: size, radius, colors, icon fill, label, click and disabled.
  - Disabled icon color.
  - RTL side flipping and padding.
- **Groups:**
  - Side wrappers, the group `::after` border, flex/overflow, and the in-group input without its own border.
  - Divider pseudo-elements (24/16px), the side text line height, and ordering.
  - Disabled group background, no empty side wrappers, and RTL order.
- **Password:** toggle in the append, sizing by the side node, type toggling without element replacement, focus return, labels, disabled, plain/text types and `inputRef`.
- **Search:**
  - `type="search"`, clear label, and the loading spinner's affordance (60px).
  - The clear button empties the field, keeps focus and searches `""`.
  - A single `@onSearch` per value across `search`+`change`, incremental keyup, and `appearance: textfield`.
- **Textarea:** rows 6/3, every resize value, padding, display, line-height multiplier, auto height, compressed in place, invalid, read-only and custom rows.
- **Select:** value, options, disabled option, arrow on the end side, change event, `hasNoInitialSelection`, no arrow while disabled, and in-group line heights.
- **Native events/attributes:** `name`/`aria-describedby`/data attributes on the real input, `inputRef`, input/change events, `step="any"` decimals, and number native invalidity on keyup.
- **Reactive args** (compressed/fullWidth/invalid/loading/readOnly/disabled) on text and select, without element replacement.
- **Providers:** nearest-provider light/dark, a light island, sibling isolation, and JS-object overrides (`size.xxl` drives control height; `border.radius.control`; the nearest override wins).
- **High contrast (preferred):** a real 1px border, the `emptyShade` background, 2px invalid, and borderless group inputs; standard contrast is isolated.
- **Delimited:** the group without the `--group` class, flex wrapper, static icons, centered borderless inputs, delimiter styles/colors (subdued, then danger when invalid), custom delimiter, the warning icon, and the read-only background.

## Unresolved / for the coordinator

1. **Icon names.** Upstream uses `magnify`, `eyeSlash`, `chevronSingleDown` and `warning` (for invalid). The bundled set lacks the first three, so `search`, `eyeClosed` and `arrowDown` are used. The icon family should switch them once it ships the current EUI icon set. No icon sizing was added here. The clear button's icon scale/fill/stroke is upstream clear-button styling, not EuiIcon sizing.
2. **Unmigrated callers of EuiFormControlLayout** now get Borealis layout styling: the ComboBox trigger, SuperSelect control, SuperDatePicker, DualRange (via Delimited), ColorPicker (via FieldText) and Suggest.
   - Their own inner controls still rely on legacy CSS. For example, the ComboBox `ul` and the SuperSelect button get no form-control styles, and the icon padding affordance only applies to controls using upstream styles.
   - SuperDatePicker passes a prepend block whose button carries the `euiFormControlLayout__prepend` class itself. It now also sits inside the styled side wrapper.
   - Audit these when those families migrate. The combo-box/super-select/date-picker/range/color-picker tests pass.
3. **Delimited input styles vs control styles.** Upstream clones the control with the delimited css placed *before* the control's own css. In Ember the yielded class is a separate Emotion class, so on conflicting properties (`height`, `box-shadow`) the winner depends on insertion order. The visual result is equivalent: the wrapper makes the state color transparent and the group sets heights to 100%.
4. **EuiFieldNumber native invalidity** owns `aria-invalid` through a modifier (a caller attribute is overridden). It does not drive the layout's warning icon, because that would need tracked state written from a modifier.
5. **Hover and autofill** styles are present (upstream factories) but untested: they need trusted pointer and real autofill browser checks (root).
6. **css-mappings** for the clear button and textarea are now unused by components (see Files).

## Next step

Root: merge, union the generator entries, and regenerate in the main checkout (`--check` should then pass). Re-run the full suite with the FormRow/FormLabel, checkables and icon families merged: labels inside prepend/append use `.euiFormLabel`, which the side-node styles target. Then run the core build and site checks, and visually audit the unmigrated layout callers listed above.
