# Control bar and file picker migration handoff (EuiControlBar, EuiFilePicker)

Status: **Migrated**. Branch `eui-wave/control-file`. Full core suite 1065/1065 in Chromium 130, parity 305/305, types, lint, generator `--check` and API docs `--check` pass.

## Upstream audit

- **EuiFilePicker**: EUI 123.1.0 `components/form/file_picker/file_picker.styles.js` (`euiFilePickerStyles`) and `file_picker.js` (behavior, i18n tokens, state classes).
- **EuiControlBar no longer exists upstream.** EUI 123.1.0 has no `components/control_bar`. Checked with npm tarballs: 91.3.1 is the last release that ships it (92.0.0 has none). It was never converted to Emotion: 91.3.1 only has `_control_bar.scss`/`_variables.scss` and a React class that wraps the bar in `EuiThemeProvider colorMode="dark"`. The styles are a hand translation to Borealis tokens (like EuiSuggest/EuiColorStops). No parity test is possible.
- **User decision (coordinator):** follow upstream, so EuiControlBar is now deprecated.

## Files

- `packages/core/src/components/eui-file-picker.gts`: rewritten on `euiFilePickerStyles`, with `@cached` class getters and the factory only through `useEuiBorealisStyles`.
- `packages/core/src/components/eui-control-bar.gts`: dark nested provider, a private `ControlBarSection` class (its `@cached` getters resolve the dark context) and the deprecation.
- `packages/core/src/utils/eui/control-bar.ts` (new, upstream license header): Borealis translation of the 91.3.1 Sass.
  - `euiControlBarVariables` and `euiControlBarStyles`: the bar, styled with the dark theme.
  - `euiControlBarPageStyles`: content area, active tab and the flicker-guard page color, styled with the surrounding theme.
  - The token mapping is documented in the file header.
- Generator: `scripts/generate-eui-styles.mjs` has a `// control bar and file picker` block with `'components/form/file_picker/file_picker.styles.js': ['euiFilePickerStyles']`. The matching entry is in the `factories` matrix of `scripts/eui-upstream-parity.test.mjs`. The generator now extracts 348 factories. `styles.generated.ts` and `upstream-sources.json` were regenerated; other diffs are only esbuild `_refN` renames.
- Tests:
  - new `packages/core/tests/integration/components/eui-control-file-test.gts` (14 tests);
  - updated `eui-file-picker-test.gts` (see below).
- Docs:
  - API docs regenerated for `docs/forms/form-controls/file-picker/index.md` and `docs/layout/control-bar/index.md`;
  - deprecation callout added at the top of the control bar page.
- Not touched: `utils/css-mappings/eui-file-picker.ts` is now unused by the component, but `css-mappings/index.ts` still registers it. The coordinator can delete both.

## API and default changes

### EuiFilePicker

- **Classes:**
  - Removed legacy modifiers: `euiFilePicker--compressed/--fullWidth/--isInvalid/--isLoading/--large/--hasFiles`, `euiFilePicker__showDrop`, and the `euiFilePicker__wrap` element.
  - Upstream state classes are used instead: `euiFilePicker-isDroppingFile`, `-isInvalid`, `-isLoading`, `-hasFiles`.
  - Kept: `euiFilePicker__input`, `__prompt`, `__icon`, `__promptText` (now a `<span>`, as upstream), `__clearButton` and `__loadingSpinner`.
- **`@display`:**
  - The type is now `'default' | 'large' | 'none'`; `'none'` is a deprecated alias of `default`.
  - **The default stays `default`**, as documented in Ember. Upstream's default is `large`. This was a deliberate choice.
  - Before, the legacy component defaulted to `''`. That rendered the control-height look but used the large-mode "Remove" button and progress branch. Now the default display uses upstream's default-mode children: a clear button, or a spinner while loading.
- **Clear button:**
  - The default display uses the upstream `EuiFormControlLayoutClearButton` (`s`/`m`).
  - The large display uses EuiButtonEmpty `xs` with the text "Remove".
  - Both use upstream's i18n `aria-label` "Remove selected files" (`euiFilePicker.removeSelectedAriaLabel`). Before, the label was "Clear selected files".
  - The button text token is now `euiFilePicker.removeSelected`; it was `removeFiles`.
  - The clear button is **hidden while disabled**, as upstream.
- **Prompt and icon:**
  - The default prompt uses the `euiFilePicker.promptText` token, and "N files selected" uses `euiFilePicker.filesSelected`.
  - The icon follows upstream: `warning` (danger) when invalid, a disabled icon, otherwise an upload icon. The bundled set lacks `minusCircle` and `upload`, so the disabled icon is `minusInCircle` and the upload icon is `importAction`.
  - The icon is size `m` in the default display and `l` in the large display. Before, it was always `m`.
  - For disabled, upstream passes the invalid color `'disabled'`, which ends up inherited. Ember uses `inherit`, which gives the same result.
- **`aria-invalid`:** now set with `@isInvalid`, as upstream's EuiValidatableControl does. `setCustomValidity` is kept.
- **Kept Ember behavior:**
  - `@onChange` still receives an empty `FileList` on removal. Upstream passes `null`.
  - `@ref` and `removeFiles()` are kept.
  - The `id` arg: `aria-describedby` follows `@id`, not an `id=` attribute (unchanged).
- **Not ported:** the upstream `files` prop (controlled prompt text), and the EuiForm `defaultFullWidth` context.

### EuiControlBar

- **Deprecated:** `deprecate()` runs on every render with:
  - id `ember-eui.eui-control-bar.removed-upstream`;
  - until `15.0.0`, for `@ember-eui/core`, since available/enabled `14.2.0`;
  - a message saying it was removed upstream and goes away in the next major, with EuiBottomBar as the suggested alternative.
- **Theming:**
  - The bar renders in a nested dark `EuiEmotionProvider` (no wrapper, no global styles), like upstream 91.3.1.
  - The content block renders in a nested provider of the **surrounding** color mode, matching the Sass page background and text.
  - The active tab uses page `body` / `textPrimary` with a 4px inset underline.
- **Kept:** all args, control types, defaults (`ghost` button/icon colors, size `l`, position `fixed`), classes (`euiControlBar--{large,medium,small,fixed,absolute,relative,showOnMobile}`, `-isOpen`, `__tab--active`), landmark/heading/live announcement and body padding. Nothing was removed.
- **Sizes:**
  - The bar is 40px (`size.xxl`). Open heights are 240/480px and `calc(100vh - 80px)` for `l`.
  - Open animations are guarded by `euiCanAnimate`. The final transform is static, so a bar with reduced motion still opens.
  - The bar is hidden below the `m` breakpoint unless `@showOnMobile`.
- **Not translated:** the Sass per-color `makeHighContrastColor` overrides for links/buttons/button icons/breadcrumbs. The dark provider's Borealis tokens already cover contrast.

## Existing test changes

- `eui-file-picker-test.gts`:
  - `euiFilePicker--hasFiles` became upstream's `euiFilePicker-hasFiles` (a rename).
  - The "states and display" test replaces `--compressed/--fullWidth/--isInvalid/--isLoading/--large` with the upstream `-isInvalid/-isLoading` state classes, computed `max-width: 100%`, the large flex prompt, the progress bar and `aria-invalid`.
- `eui-control-bar-test.gts`: unchanged, and it passes.

## New coverage (`eui-control-file-test.gts`, 14 tests)

- **File picker:**
  - Default/compressed/fullWidth geometry: 40/32px, 36/32px start padding, 400px form width.
  - The invisible input covers the picker.
  - Dashed border token, line-height 1, truncation, icon position and color.
  - Large/compressed heights (128/104px), centered column, padding, and the icon scaling on focus.
  - Selection: one name, then "2 files selected", the `hasFiles` bold weight and end padding.
  - Clear button: class, label, 16px size, end position, vertical centering, pointer events, click clears and `onChange` gets an empty list.
  - Large "Remove" button, progress bar, loading `overflow: hidden`.
  - Invalid: aria, `customError`, border and icon.
  - Disabled: transparent border, background/color tokens, icon, no clear button, no bold.
  - Spinner: sizes `m`/`s`, position, and it replaces the clear button.
  - Drag over/leave/drop: tokens, and disabled pickers are ignored.
  - Focus color, border transition, native attributes, `aria-describedby`, `@ref` `removeFiles`.
  - Reactive args with no element replacement.
  - Dark/light nearest provider and sibling isolation.
  - JS-object overrides (`size.xxl`, `size.m`, `borderBaseProminent`).
  - RTL icon/spinner sides.
- **Control bar:**
  - Dark tokens inside a light page, the flicker-guard page color, layout of every control type, and a single Emotion class on the `@css` children.
  - Button icon color matches a reference dark-mode button icon.
  - Tabs: button reset, active styles from the page theme.
  - Content in the page mode (light and dark), the fade animation, and s/m/l open heights and transforms in place.
  - Fixed portal: offsets incl. rem, z-index `levels.mask`, absolute z-index `levels.header`, body padding/class, live announcement, teardown.
  - The mobile media rules, RTL logical spacing, and a token override reaching the nested dark bar.
  - The deprecation (id, until, for, since, message).

## Checks (2026-10-12, this worktree, Node 22, Chromium 130 via the scratchpad shim, `CI=true`; pnpm unavailable)

- `ember-tsc --noEmit`: pass.
- ESLint on the changed components, `control-bar.ts` and both test files: pass.
- `vite build --mode=development --out-dir dist-tests` + `testem ci`: **1065/1065**.
  - A first full run had one failure: the spinner rotation inflated a bounding box. It was fixed to use `offsetWidth`, and the filtered family run then passed 3× in a row.
- `node --test scripts/eui-upstream-parity.test.mjs`: **305/305**.
- `node scripts/generate-eui-styles.mjs --check`: passes.
- `node scripts/generate-api-docs.mjs --check`: passes.

## Unresolved / for the coordinator

1. **Missing `@css` on migrated children (the wrapper-span pattern was used meanwhile):**
   - EuiFormControlLayoutClearButton and EuiLoadingSpinner need upstream's right-icon position plus `pointer-events: auto` composed in. Here a positioned `<span>` wrapper carries those styles; `pointer-events` is inherited.
   - EuiButtonEmpty (the large "Remove" button) gets the same treatment.
   - EuiButton (control bar buttons) lacks `@css`. Its layout (`flex-shrink`, margins) comes from a `.euiControlBar__controls > .euiControlBar__button` rule. The Sass `border-radius: $euiBorderRadius/2` and `font-size: s` were not applied, so it keeps the Borealis size `s` button look.
   - EuiBreadcrumbs lacks `@css` too, but no layout styles were needed.
2. **Icon names:** upstream uses `upload`/`minusCircle`. Switch from `importAction`/`minusInCircle` when the icons refresh lands.
3. **Hover styles** (dashed→solid in high contrast, hover state colors) are present but untested; they need trusted pointer input.
4. `utils/css-mappings/eui-file-picker.ts` is dead code (see Files).
5. **EuiControlBar deprecation:** remove it in 15.0.0. Docs demos still render it, which logs the deprecation.

## Next step

Merge, union the generator/parity entries and regenerate in the main checkout. Then add `@css` to EuiFormControlLayoutClearButton/EuiLoadingSpinner/EuiButtonEmpty/EuiButton and drop the file picker wrapper spans and the control bar's child selector.
