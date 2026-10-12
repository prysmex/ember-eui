# Form layout family migration handoff (EuiForm, EuiFormRow, EuiFormLabel, EuiFormLegend, EuiFormFieldset, EuiFormHelpText, EuiFormErrorText, EuiDescribedFormGroup)

Status: **Migrated**. The full core suite passes in Chromium 130 (671/671, including 15 new form-layout tests), with upstream parity 37/37, types, lint and API docs.

## Files

- `packages/core/src/components/`: `eui-form.gts`, `eui-form-row.gts`, `eui-form-label.gts`, `eui-form-legend.gts`, `eui-form-fieldset.gts`, `eui-form-help-text.gts`, `eui-form-error-text.gts`, `eui-described-form-group.gts`. All are now Glimmer classes on extracted factories, using `getEuiThemeContext` / `useEuiBorealisStyles` / `euiClass`, composed in upstream's `cssStyles` order.
- `packages/core/src/-private/eui-form-context.ts` (new): the EuiForm → row/group `fullWidth` context (`ember-provide-consume-context`), kept in its own module so rows don't import EuiForm/EuiCallOut, which avoids import cycles.
- `scripts/generate-eui-styles.mjs` and `scripts/eui-upstream-parity.test.mjs`: a `// forms-layout` block in both (see generator entries below).
- `styles.generated.ts` and `upstream-sources.json`: regenerated (42 factories), purely additive.
  - In this worktree, esbuild's provenance comments came out as `../../../../Users/.../node_modules/...` because `node_modules` is a symlink.
  - I rewrote those comment lines to the main checkout's `// node_modules/...` form with a sed over comment lines only.
  - Check: regenerating and then normalizing gives byte-identical output, and the diff to `styles.generated.ts` has zero deleted lines.
- `packages/core/tests/integration/components/eui-form-layout-test.gts` (new): 15 computed-style, geometry and a11y tests.
- `packages/core/tests/integration/components/eui-form-test.gts`: three legacy-class assertions replaced (see below).
- `packages/core/docs/forms/form-layouts/index.md`, `described-form-groups.md`: only the generated API sections changed.
- Not touched:
  - form controls and checkables (other agents)
  - `link-form-row-control.ts` (its behavior is unchanged and its selectors still match)
  - `utils/css-mappings/eui-form-row.ts` and `eui-described-form-group.ts`: now unused by the components but still registered in the mappings index, same as the dead flex mappings
  - the `screen-reader-only` modifier, providers/shared utils, the showcase, `.vscode/settings.json`

## Generator entries added (`// forms-layout`)

`euiFormRowStyles` (form_row), `euiFormLabelStyles` (form_label), `euiFormLegendStyles` (form_fieldset/form_legend), `euiFormHelpTextStyles`, `euiFormErrorTextStyles`, `euiFormLabelAppendStyles` (form_label_append), `euiDescribedFormGroupStyles`. They also pull in `form/form.styles.js` (`euiFormVariables`, `euiFormMaxWidth`) as a bundled dependency without exporting it. The form-controls agents will probably add `form.styles.js` exports, and the coordinator must union both blocks. The same 7 factories are in the parity `factories` map, which runs the 12-configuration matrix.

## API and default changes (latest-only)

### EuiFormRow

- **Rows are capped at `components.forms.maxWidth` (400px)** unless `@fullWidth` is set (upstream `formWidth`). `@fullWidth` now defaults to the enclosing EuiForm's `@fullWidth`.
- **Layout**
  - The row is `display:flex; flex-direction:column; row-gap: size.xs`.
  - Siblings get `margin-top: size.base` for `row + row` and `row + .euiButton`, or `size.s` between columnCompressed rows.
  - columnCompressed puts the label beside the field: `33% - s` / `67%`, label line height `size.xl`, and rows containing an `.euiSwitch` get `m` around them.
  - center/centerCompressed vertically center the field wrapper at a min height of `size.xxl`/`size.xl`.
- **Display aliases:** `rowCompressed` is identical to `row` (upstream marks it deprecated). `columnCompressedSwitch` is an Ember alias of `columnCompressed`, because upstream removed it and handles switches via `:has(.euiSwitch)`. Unknown values fall back to `row`. The display type is now exported as `EuiFormRowDisplay`, with the same keys as before.
- **Classes:**
  - Removed legacy classes: `euiFormRow--fullWidth`, `--compressed`, `--horizontal`, `--hasSwitch` and `euiFormRow__fieldWrapperDisplayOnly`.
  - Kept upstream classes: `euiFormRow`, `euiFormRow--hasEmptyLabelSpace`, `euiFormRow__labelWrapper`, `__label`, `__fieldWrapper`, `__text`.
  - Added upstream `euiFormRow--hasLabel`. EuiDescribedFormGroup's baseline anchor relies on it.
- **Label additions (upstream):** the label gets `id="<id>-label"` and receives `@isDisabled`. Help texts also get the `euiFormRow__text` class.
- **Label append (upstream):** a string `@labelAppend` renders `<span class="euiFormLabelAppend euiFormRow__labelAppend">` (xs, `textSubdued`). The `<:labelAppend>` block is wrapped in `<EuiText @size="xs" class="euiFormRow__labelAppend">`.
- **`@hasEmptyLabelSpace` without a label** renders an m `EuiSpacer` with class `euiFormRow__labelWrapper` (upstream), replacing the legacy padding.
- **Preserved exactly:** row id `<id>-row`, error ids `<id>-error-<i>`, help ids `<id>-help-<i>` (div rows), the single `<id>-help` id (fieldset rows and the `<:helpText>` block), label `for`/control association, and the `aria-describedby` order. The order stays errors then help, which is DOM order; upstream React orders help then errors. Focus tracking also still runs through focusin/focusout.
- **Small fixes:**
  - Legends no longer get a stray `for` attribute.
  - Without an `<:errors>` block, a missing or empty single `@error` no longer renders an empty `EuiFormErrorText` while invalid (upstream `error && isInvalid`). An `<:errors>` block still renders once with `undefined`, as before.
  - The `<:helpText>` block on div rows now also yields `@helpText`.
- **Ember API kept:** `@legendType="legend"` still selects `<fieldset>`; upstream infers it from `labelType`, but the docs use both. A label with `@hasChildLabel={{false}}` stays a `<label>` without `for`, whereas upstream renders a `<span>`; this keeps the `Element` type. Upstream's `describedByIds` and child `disabled` cloning are not ported (React cloning).

### EuiFormLabel

- **Styles:**
  - xxxs title typography with `font.weight.semiBold` and `colors.textHeading`
  - `display: inline-block`
  - a color transition under `euiCanAnimate`
  - `cursor: pointer` only on `[for]` labels that are not disabled
  - invalid uses `colors.textDanger`
- **Focus:** `@isFocused` only adds `euiFormLabel-isFocused`. Borealis no longer recolors focused labels (upstream has no focus style).
- **New `@isDisabled`** adds `euiFormLabel-isDisabled` and drops the pointer.
- **Kept state classes (upstream):** `-isFocused`, `-isInvalid`, `-isDisabled`.

### EuiFormLegend and EuiFormFieldset

- **EuiFormLegend:**
  - Label typography with `margin-bottom: size.s`, or `size.xs` when `@compressed` (upstream).
  - A hidden legend has no margin. `euiFormLegend--compressed` is removed; `euiFormLegend-isHidden` is kept (upstream).
  - The hidden legend's text gets a local copy of upstream's `euiScreenReaderOnly` mixin. The shared `screenReaderOnly` modifier only adds a class, which has no styles without legacy CSS. This is the same stand-in as EuiLink.
- **EuiFormFieldset:** upstream has no styles. A scoped reset replaces React's global reset: no border, padding or margin, and `min-inline-size: auto`. Fieldset rows get the same reset.

### EuiFormHelpText and EuiFormErrorText

- Help text: `padding-top: size.xs`, xs font, `colors.darkShade`.
- Error text: the same, but `colors.textDanger`. `aria-live="polite"` is kept.

### EuiDescribedFormGroup

- **Root:** `max-width` is 2 × the form max width (800px) unless `@fullWidth`, which now defaults from EuiForm. The next sibling gets `margin-top: size.l`.
- **Layout:**
  - The inner flex group uses `alignItems="baseline"` and the gutter (default `l`, unchanged).
  - The description column has `min-width: min(20rem, 50%)`. The description gets `padding-top: size.s` and the subdued color.
  - Unlabelled first rows get the `::before` baseline anchor. A first row with empty label space gets no top margin.
  - The legacy `euiDescribedFormGroup__fieldPadding--*` classes and `--fullWidth` are removed.
- **New `@ratio`** (`half` default, `third`, `quarter`) sets the field grow to 1, 2 or 3 unless `fieldFlexItemProps.grow` is given. The description grows 1 by default; both defaults are equivalent to before.
- **Default title size is now `xs`** (upstream). Before, `@titleSize` was not defaulted when passed to EuiTitle, so titles rendered at EuiTitle's `m`.
- **Naming (upstream):** the title gets a generated id `euiDescribedFormGroupTitle-<random>`, and the group's `aria-labelledby` points to it. A caller's `aria-labelledby` wins, and an `aria-label` attribute removes the default labelledby through a small modifier.
- **Conditional rendering:** title and description render only when their blocks are given, so there are no empty `h2`s or EuiTexts.
- **DOM:** the root stays a wrapper `div[role=group]` around the flex group. Upstream makes the flex group the root, but forwarding a div-typed `...attributes` to EuiFlexGroup (`HTMLDivElement | HTMLSpanElement`) fails Glint, and the wrapper keeps `Element` stable and existing selectors working. Responsive collapse comes from EuiFlexGroup: below the `m` breakpoint both columns are 100% wide and stacked.

### EuiForm

- **New `@fullWidth`** provides the default to rows and groups through context (upstream `FormContext`). Changes are tracked.
- **Callout markup:** errors are now listed in a `<ul>`; before, the `<li>`s were direct children of the callout body. An m `EuiSpacer` follows the callout (upstream).
- **Kept:** the default title "Please correct the fields", the `@array` behavior and the `tagName` API.
- **Not ported:** upstream's `tabIndex=-1` and auto-focus of the callout. That would move focus whenever the form becomes invalid; it needs a product decision.

## Existing test changes (eui-form-test.gts)

1. `hasClass('euiFormRow--fullWidth')` became computed `max-width: 100%`, because the legacy modifier class no longer exists.
2. `hasClass('euiFormLegend--compressed')` became computed `margin-bottom: 4px` (size.xs). The test was renamed to "EuiFormLegend hidden and compressed".
3. `hasClass('euiDescribedFormGroup--fullWidth')` became computed `max-width: 100%`.

Everything else in that file, including all label-association and describedby tests, passes unchanged.

## Test coverage (eui-form-layout-test.gts, 15 tests)

- **Display modes:**
  - row and rowCompressed: column, xs gap, 400px cap, measured label/field gap, label-append placement, `row + row`, `row + .euiButton`
  - fullWidth
  - columnCompressed and its alias: row direction, s gap, 33%/67% geometry, compressed line height, s sibling margin, switch rows (m margins, base line height), RTL order
  - center and centerCompressed: min heights, measured vertical centering
- **Typography and color:** labels match EuiTitle xxxs (size, line height, letter spacing) with the semibold weight, heading color and Inter font. Help and error texts are measured the same way, with their colors and AA contrast.
- **Label states:** pointer only with `[for]` and not disabled; invalid, disabled and focused classes/colors, with no focus recolor.
- **Accessibility wiring:** row/label/error/help ids, label `for`, label click focuses the field, `aria-describedby` order including multiple help texts, append span/block, empty label spacer height, hasChildLabel, fieldset rows (legend without `for`, `fs-help`, reset box), rows without a label.
- **Fieldset/legend:** reset box; s vs xs spacing measured and toggled in place; hidden legend is screen-reader-only with no margin.
- **Described group:**
  - width and sibling spacing, baseline, gutter, half-ratio equal columns
  - third/quarter ratios, including the 20rem minimum
  - title id and labelledby, aria-label and aria-labelledby overrides
  - default title size xs, custom size/tag/gutter
  - description padding and color, the `::before` anchor, empty-label first row
  - responsive collapse at exactly `m - 1` vs `m`, using iframes with copied CSSOM
- **EuiForm:** fullWidth context (inherit, own value wins, groups inherit, outside unaffected, reactive update without replacement); callout `ul > li`; spacer.
- **Reactive args:** display, fullWidth, isInvalid, label and helpText change with row/label/input elements preserved. The color transition is finished before reading. Teardown is checked.
- **Themes and overrides:**
  - Light/dark nearest provider with a sibling and a reactive mode switch: label, invalid, help, error, append, description and legend colors, plus dark contrast.
  - JS-object overrides (`components.forms.maxWidth`, `size.xs`/`base`, `textDanger`/`textHeading`) apply inside the provider only and are restored on removal.
- **RTL:** capped rows start on the right, the label append sits at the inline end, and the described group mirrors.

## Checks run (2026-10-12, worktree `eui-wave/forms-layout`)

Environment: Node 22.22.1, pnpm unavailable (binaries run directly), Chromium 130 via the `google-chrome` shim with `CI=true`.

- Core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **671 tests, 671 pass, 0 fail**. That is the 656 base plus the 15 new tests.
- Filtered `filter=form`: 51/51.
- `node --test scripts/eui-upstream-parity.test.mjs`: **37/37 pass**. That is 30 before plus the 7 new factories.
- `node scripts/generate-eui-styles.mjs --check`: throws "Stale generated artifact" **in this worktree only**, because of the symlinked `node_modules` path comments. The committed file equals the regenerated output after comment-path normalization (verified with `cmp`). Re-run in the main checkout after merge.
- `ember-tsc --noEmit`: pass. ESLint on all changed components, the context module and both tests: pass.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating 2 pages.
- Not run (root): core rollup build, site build/acceptance, showcase visual checks, and the validated-form / changeset-form package tests (they render EuiFormRow).

## Unresolved

1. **Visual changes for callers.** Unmigrated callers and docs get the 400px row cap, the 800px described-group cap and the new spacing. On legacy docs pages with Amsterdam CSS, the vendor `.euiFormRow`/`.euiFormLabel` base rules still apply alongside. Audit visually, especially form-layout demos, inline forms (`hasEmptyLabelSpace` + flex), super date picker / quick select, and the validated/changeset form packages.
2. **`screenReaderOnly` modifier.** It has no styles without legacy CSS, so EuiFormLegend carries a local stand-in. The coordinator should extract `euiScreenReaderOnly` as a shared factory when EuiScreenReaderOnly migrates.
3. **EuiForm callout focus.** Upstream's auto-focus and `tabIndex=-1` are not ported (behavior decision).
4. **Dead mappings.** `utils/css-mappings/eui-form-row.ts` and `eui-described-form-group.ts` are dead; remove them in the coordinated mappings cleanup.
5. **Nested headings.** `<:title>` content that is itself a heading (the docs use `<h3>`) nests inside EuiTitle's own heading tag (`h2 > h3`). This predates the port. Upstream clones the child heading instead. Prefer `@titleTagName` with plain text.

## Next step

Root: merge (union the `// forms-layout` generator/parity blocks with the form-controls agents' blocks), regenerate in the main checkout, run the core build, the validated-form / changeset-form tests and site checks, then visually pass the form-layout docs pages.

## Follow-up: EuiForm error callout focus (upstream decision, branch `eui-wave/upstream-decisions`)

The user chose "keep upstream behavior", which resolves Unresolved item 3 above. Upstream 123.1.0 `form.js` renders the callout with `tabIndex={-1}` and a stable callback ref (`useCallback(node => node?.focus(), [])`), so focus moves only when the callout element mounts.

- **Port:** the callout now has `tabindex="-1"` and a local `focusOnInsert` function modifier (`ember-modifier`). The modifier reads no tracked state, so it runs once per inserted callout, just like the callback ref.
- **When focus moves:**
  - The callout appears: `@isInvalid` becomes true while there are errors and `@invalidCallout` is `'above'`. This also covers the first render of an already invalid form, as upstream's ref does on mount.
  - Re-renders of a visible callout do not move focus. Examples are new errors and a new `@errorTitle`.
  - Becoming valid does not move focus. The next invalid transition focuses again.
  - `@invalidCallout="none"` never focuses.
- **Unchanged:**
  - `role="alert"` and `aria-live="assertive"`.
  - The default title "Please correct the fields".
  - The callout still appears only when there are errors. Upstream shows it whenever `isInvalid`, even with no errors; the Ember condition was kept.
  - The `@array` and `tagName` APIs.
- **Tests:** `eui-upstream-decisions-test.gts` covers this ("EuiForm error callout focus", 2 tests). No existing form test asserted the old no-focus behavior, so none changed.
- **Watch:** the validated-form and changeset-form packages render EuiForm. On submit with errors, focus now goes to the callout. Their suites were not run here.
