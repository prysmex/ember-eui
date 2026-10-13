# Forms and containers gaps: handoff

Branch `eui-wave/gaps-forms`, from `feat/eui-latest` at 831b7169. Closes the form and container rows of docs-audit-gaps.md, each verified against EUI 123.1.0 source first.

## Closed

| Row | What | Ember choice |
| --- | --- | --- |
| EuiCheckbox `readOnly` | Native `readonly`, upstream's `input.readOnly` / `label.readOnly` styles (default cursor, unselected border kept on focus). | Native `readonly` does not stop checkboxes toggling, and Ember inputs are not controlled, so clicks are cancelled (`preventDefault` on click while read-only). |
| Palettes | `euiPaletteRed/Green/SkyBlue/Yellow/Orange(steps, { colors })`, exported from `utils/color`, `utils` and the `eui-palette` helper. | Upstream reads vis colors from the global `EUI_VIS_COLOR_STORE`; Ember defaults to the Borealis light vis colors (same in dark) and takes `colors` to override. Output equals upstream's for 1, 2, 3, 5 and 10 steps (fixture in the test). |
| EuiColorPalettePicker `append` per palette | Shown beside the title in the list, not for `type: 'text'`. | A React node becomes a string or a component (`ComponentLike`). The picker-level `append`/`prepend` are not forwarded (upstream has them; not in the gaps file). |
| EuiInputPopover `closeOnScroll` | Same algorithm as upstream: 500ms grace, capture-phase window listener, ignores scrolls inside the panel or input, only elements containing the input. | Modifier on the content, active while open. Added to the selectable demo. |
| EuiInlineEditText/Title | `readModeProps.color` / `iconSide`; `editModeProps.inputProps.readOnly` / `prepend` / `append`. | `prepend`/`append`: a string renders an `EuiFormLabel` (like upstream's `EuiFormControlLayout`), anything else is a component. Only these keys were added to the existing explicit key lists. |
| EuiModal `focusTrapProps.returnFocus` | `false`, or a function that returns `false` to skip; same code as EuiFlyout. | `FocusOptions` return values are accepted by the type but, as in EuiFlyout, ignored. `EuiConfirmModal` forwards `@focusTrapProps`. |
| EuiConfirmModal `titleProps` | `className`, `id`, `data-test-subj` on the title element. | Explicit keys (no arbitrary spread in Ember). Confirm modal demos now use `titleProps.id` with `aria-labelledby`, as upstream. |
| EuiSuperSelect `popoverProps` | Forwarded to `EuiInputPopover` (`className`, `panelClassName`, `panelStyle`, `repositionOnScroll`, `ariaLabel`, `panelPaddingSize`, `anchorPosition`, `zIndex`, ...). | As upstream, `isOpen` is not accepted and `fullWidth`/`disableFocusTrap` stay managed by the select. EuiInputPopover now forwards those extra args to EuiPopover (it dropped them before). |
| EuiResizablePanel mode options | `['collapsible', { position, className, 'data-test-subj' }]`. | Upstream's types list `className`, but its code only passes `data-test-subj` to the button. We apply both (documented intent). |
| EuiResizableButton standalone | Works without a container: `@isHorizontal`, plus your own `{{on "mousedown"}}`, `{{on "touchstart"}}`, `{{on "keydown"}}`. Now exported from `components.ts` and the template registry. Upstream's "Custom resize logic" demo added (d11). | Events are modifiers (idiomatic) rather than `onMouseDown`-style args. |
| EuiAccordion hover-only extra action | Not a component feature: upstream's example is consumer CSS (`.euiAccordion:hover &`). Re-added to demo d11 with a theme function passed to the button icon's `@css`; test covers it. | |

## Bug: EuiFieldSearch clear button

`EuiFieldSearch` copied a changed `@value` into its tracked text from a `{{didUpdate}}` modifier. In some render orders (reproduced through `EuiSelectable` with a controlled `searchProps.value`, steps `'x'` then `''` then typing) the clear button's `{{on "click" @clear}}` was updated after `@clear` had become `undefined` and threw. Fix: the text is now derived (`typed` text valid while `@value` is the one it was typed over, else `@value`/`defaultValue`), with no state written from a modifier.

EuiSelectableSearch: removed the after-render synthetic `input` event (`syncValue`); it passes the controlled value to the field's `@value`. Verified: with the workaround removed and the old EuiFieldSearch, two selectable tests failed with the `on` error; with the fix all selectable tests pass.

Caveat: I could not reproduce the throw with EuiFieldSearch alone (about six variants of controlled value, round trips and resets, all passed before the fix). The EuiFieldSearch tests added (4) guard the behaviour (a controlled value following changes to `''`, round trips, the clear button), but only the selectable tests failed before the fix.

## Behaviour changes

- EuiFieldSearch: a changed `@value` still wins over text typed earlier (counted per change, so a controlled round trip `'' -> 'typed' -> ''` ends on `''`); `value` is now a getter. No existing test changed.
- EuiInputPopover forwards more args to EuiPopover. Previously these were silently ignored.
- No existing assertion was changed.

## Not done

- EuiColorPalettePicker top-level `append`/`prepend` (not in the gaps file).

## Checks

- `ember-tsc --noEmit`: clean. eslint on changed files: clean.
- `node --test scripts/eui-upstream-parity.test.mjs`: 353/353 (no style generator changes needed: all factories already existed).
- `rollup --config`: no package.json change (the button export already existed).
- Filtered: eui-field-search 11/11 (4 new); forms and containers upstream gaps 23/23 (the palette parity test is one of them); eui-selectable* 30/30.
- Full core suite: 1685/1685 (main was 1658; +27: 23 new file + 4 field-search).

Tests: `tests/integration/components/eui-forms-gaps-test.gts` (new, 23) and 4 added to `eui-field-search-test.gts`.
