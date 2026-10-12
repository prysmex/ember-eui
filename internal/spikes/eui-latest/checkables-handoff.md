# Checkables family migration handoff (EuiCheckbox, EuiCheckboxGroup, EuiRadio, EuiRadioGroup, EuiSwitch)

Status: **Migrated**. The full core suite passes in Chromium 130 (667/667), along with upstream parity, types, lint and API docs.

## Files

- `packages/core/src/components/eui-checkbox.gts`, `eui-radio.gts`, `eui-switch.gts`, `eui-checkbox-group.gts` and `eui-radio-group.gts`: these are now Glimmer classes on the extracted factories. `eui-checkbox.gts` also exports `euiCheckableReset` and `euiCheckableInputReset`, which EuiRadio reuses.
- `scripts/generate-eui-styles.mjs`: new `// checkables` block with six factories (`euiCheckboxStyles`, `euiCheckboxControlStyles`, `euiCheckboxGroupStyles`, `euiRadioStyles`, `euiRadioGroupStyles`, `euiSwitchStyles`). The generator now extracts 41 factories. Their upstream `form.styles.js` (`euiFormCustomControlStyles`/`Variables`) and the high-contrast helpers are bundled through them.
- `styles.generated.ts` and `upstream-sources.json` were regenerated, never edited by hand.
- `scripts/eui-upstream-parity.test.mjs`: the six factories are in the `factories` map and go through the 12-configuration matrix.
- `packages/core/tests/integration/components/eui-checkables-test.gts`: new, 11 computed-style and behavior tests.
- Legacy assertions updated, each replaced with a semantic check of the same intent:
  - `eui-checkbox-test.gts`: `.euiCheckbox--compressed` and `.euiCheckbox--noLabel` became "the label is rendered" and "no `<label>` is rendered". Upstream has neither modifier.
  - `eui-radio-test.gts`: `.euiRadio--noLabel.euiRadio--compressed` became "no `<label>` is rendered".
  - `eui-switch-test.gts`: the `euiSwitch--compressed` class assertion became `doesNotHaveClass`. `.euiSwitch__icon` became upstream's `.euiSwitch__icons` container, which a compressed switch does not render. The compressed size itself is measured in the new test file.
- `packages/core/docs/forms/form-controls/{checkbox,checkbox-group,radio,radio-group,switch}/index.md`: only the generated API sections were regenerated.
- Not touched:
  - EuiFormFieldset and EuiFormLegend (form family), EuiIcon, and callers (EuiCheckableCard, EuiKeyPadMenuItem, markdown checkbox, super date picker).
  - Providers and shared utilities, the site/showcase, and the docs demos.

## API and default changes (latest-only)

- **Visual state follows the native input, not only args.** Upstream (React, always controlled) picks its selected/disabled slots from props. Ember checkboxes and radios are often uncontrolled, and the browser unchecks sibling radios without a change event. The upstream slots are therefore composed under `:has(> input:checked | :indeterminate | :disabled)` selectors.
  - The CSS values are byte-identical upstream slots. Only the selector that activates them differs.
  - A consequence: callers that pass `disabled=` as an attribute instead of `@disabled` now get the disabled look too. EuiCheckableCard does this.
  - After a user click, the browser clears `indeterminate`, so the box shows the native checked state (upstream React keeps showing the bar until the prop changes).
- **Check mark, indeterminate bar and radio dot are removed with `display: none` when inactive.** Upstream makes them transparent and swaps in an `empty` icon. Removing them keeps forced colors from revealing a hidden mark.
  - The checkbox renders both `check` and `stopFilled` icons; Ember's icon set has `stopFilled`, not upstream's `stopFill`. The icons get `role="presentation"`.
- **DOM follows upstream:**
  - Checkbox: `.euiCheckbox > .euiCheckbox__square > (.euiCheckboxControl > icons) + input.euiCheckbox__input`, then `label`.
  - Radio: `.euiRadio > .euiRadio__circle > (icon + input.euiRadio__input)`, then `label`.
  - Switch: `button > .euiSwitch__body > .euiSwitch__icons`, plus `.euiSwitch__thumb` as a sibling of the body. `.euiSwitch__track` and `.euiSwitch__icon(--checked)` are gone.
  - All legacy `--compressed`, `--noLabel` and `--withIcon` modifiers are removed.
- **`@compressed` on a single EuiCheckbox or EuiRadio is deprecated and has no effect.** Upstream has no compressed checkbox or radio. On the groups, `@compressed` now means upstream's row gap of 0 instead of `xs` (4px), and the groups no longer forward it to each item. `@icon` on EuiCheckbox is deprecated and has no effect.
- **Groups:**
  - The group root gets the class `euiCheckboxGroup` or `euiRadioGroup` and upstream's flex column with an `xs` gap.
  - With `@legend`, the class **and `...attributes`** go on the `EuiFormFieldset` element, as upstream does. Before, attributes were dropped in that case. `Element` is widened to `HTMLDivElement | HTMLFieldSetElement`, and core still type-checks.
  - No `role="radiogroup"` is added (upstream adds none); callers can pass `role`/`aria-label`, and they are forwarded.
- **EuiSwitch:**
  - New `@mini`: 22×10, no icons, `xs` label. It takes precedence over `@compressed`.
  - New `@labelProps` (`{ className, id }`).
  - Borealis sizes: uncompressed is **44×20** (`xxl + xs` × 1.25 base), compressed is 28×16, mini is 22×10. Compressed and mini render no icon container.
  - The thumb animates `inset-inline-start`, so it flips in RTL.
- **Scoped resets** stand in for React's global reset, composed before the upstream styles so every upstream rule wins:
  - Border-box sizing and the Borealis font family on roots, faux controls and labels.
  - `margin: 0; padding: 0` on the hidden inputs.
  - Upstream's `button` reset on the switch button.
  - Border-box on the switch body, icons and thumb. The thumb's 1px border depends on it.
- Not ported:
  - Upstream EuiCheckbox `readOnly` and EuiCheckboxControl `excluded`. Ember had neither.
  - `legend` as an object with `display: 'hidden'`. Ember keeps the `@legend` string; EuiFormFieldset has `@display`.

## Checks run (2026-10-12, worktree `eui-wave/checkables`)

Environment: Node 22 and Chromium 130 through the scratchpad `google-chrome` shim, with `CI=true`. Binaries were run directly because pnpm is unavailable.

- Core tests (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **667 tests, 667 pass, 0 fail**. That is the 656 base tests plus 11 new `Borealis checkables` tests.
- Filtered runs while iterating:
  - `eui-checkbox` 5/5, `eui-radio` 4/4, `eui-switch` 3/3, `eui-form` 27/27, `checkable` 14/14.
  - `key-pad` 3/3, `markdown` 9/9, `super-date` 9/9.
- `node --test scripts/eui-upstream-parity.test.mjs`: **36/36 pass**. That is 30 before plus 6 new factories.
- `node scripts/generate-eui-styles.mjs --check`: **pass** (exit 0, 41 factories, React-free) in this worktree.
  - The only changes to existing generated code are esbuild `_refN` renames (for example `_ref20` → `_ref27`) caused by the newly bundled sources, plus the source-path comments.
- `ember-tsc --noEmit`: pass. ESLint on all changed components and tests: pass.
- `node scripts/generate-api-docs.mjs --check`: pass after regenerating.
- Not run (root agent's job): the rollup/core build, site build, site type check, acceptance tests and showcase.

## Test notes

- Space toggling: synthetic key events cannot trigger a browser default action. The tests therefore check that the native input or button takes focus (`tabIndex` 0, `document.activeElement`) and then run its activation behavior (`click()`), which is what Space does. A real-key check needs a WebDriver/CDP run.
- Focus rings:
  - The checkbox square and radio circle use `&:has(input:focus-visible)` (2px solid primary, 2px offset).
  - The switch uses `euiFocusRing` outset (`outline-style: auto` only for `:focus-visible`).
  - Both are asserted against `:focus-visible`, so pointer focus expects no ring.
- The switch thumb is scaled (0.9 compressed, 0.8 mini), so the tests use `offsetWidth`/`offsetHeight` rather than bounding rects. Transitions are finished with `document.getAnimations()`.
- Forced colors (`forced-colors: active`) cannot be emulated in testem. The tests cover the structural guarantee instead (inactive icons are `display: none`) and the always-present 1px solid border on the faux controls.

## Unresolved

1. **The icon fill depends on EuiIcon.** Upstream EuiIcon sets `fill: currentColor`. Ember's SVGs have no fill and EuiIcon is not migrated, so on pages without Amsterdam CSS the check mark, the bar, the radio dot and the switch icons use the SVG default fill (black) instead of the control's `color`. Per the wave rules no local icon styling was added; the icon family should land `fill: currentColor`. Icon colors are not asserted (the container `color` is).
2. Docs demos still pass `@compressed` to a single checkbox (`checkbox/demo/d01-checkbox.md`, `switch/demo/d02-hidden-label.md` is fine). The checkbox one is now a no-op. Root/docs owner: update the demo and consider adding a `@mini` switch demo.
3. Callers were not visually audited:
   - EuiCheckableCard: it passes `disabled=` as an attribute, which the native `:disabled` selectors now honor.
   - EuiKeyPadMenuItem: it passes `@containerClass`.
   - The markdown checkbox, and the super date picker's rounding switch.
   - Table header/row cell checkboxes: they do not use EuiCheckbox.
4. On legacy docs pages that still load Amsterdam CSS, vendor `.euiCheckbox`/`.euiRadio`/`.euiSwitch` rules also apply. For example, the legacy `.euiCheckbox .euiCheckbox__input` hides inputs differently, and legacy switch rules target the old `__track` structure.

## Next step

Root agent: merge, regenerate in the main checkout, then run the core build, site build/type check and the showcase. The EuiIcon family should provide `fill: currentColor` (item 1). EuiCheckableCard and EuiKeyPadMenuItem are natural follow-ups.
