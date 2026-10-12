# Super select migration handoff (EuiSuperSelect, EuiSuperSelectControl)

Status: **Migrated**. The full core suite passes in this worktree (888/888, Chromium 130), along with upstream parity (195/195), types and lint.

## Engine note

The brief described super select as built on ember-power-select/basic-dropdown. It is not: in this branch `EuiSuperSelect` is built on `EuiInputPopover` (the overlays family). That engine is kept: positioning, `@initialFocus` after positioning, the disabled focus trap and outside-click closing. `src/styles/ember-eui.css` has no super select rules, so nothing shared with the combo box was touched.

## Files

- `packages/core/src/components/eui-super-select-control.gts`
  - The button composes, in one Emotion class: the form-controls `buttonReset`, then upstream `euiSuperSelectControlStyles`: `euiSuperSelect__control`, compressed or uncompressed, fullWidth or formWidth, inGroup, open, invalid, readOnly, disabled.
  - It renders inside `EuiFormControlLayout @isDropdown`, which draws the arrow, and passes the layout `@isInvalid`, `@isDisabled`, `@readOnly`, `@isLoading` and `@compressed`.
  - Class getters are `@cached`. The factory is only used through `useEuiBorealisStyles`.
- `packages/core/src/components/eui-super-select.gts`
  - Options are rendered as upstream `EuiSuperSelectItem`, which is `EuiListItemLayout`: a `button.euiListItemLayout.euiSuperSelect__item[role=option]` > `__content` > EuiIcon (check or empty) + `__text` (wrapping).
  - The option styles are the extracted `euiListItemLayoutStyles`: interactive, isFocused, isSelected, isSelectedFocused and isDisabled. It no longer uses `EuiContextMenuItem`.
  - The listbox uses `euiSuperSelectStyles` plus upstream's `eui-scrollBar` utility (`euiScrollBarStyles`, composed locally because no global utility classes are injected).
  - The icon is styled through EuiIcon `@css` (`euiListItemLayout__icon`), not a second class.
  - All style getters are `@cached`. Option classes are composed once per state combination (selected/focused/disabled), not once per option.
- `scripts/generate-eui-styles.mjs` gets a `// super select` block: `components/form/super_select/super_select.styles.js` → `euiSuperSelectStyles` and `euiSuperSelectControlStyles`.
  - It extracts 224 factories, React-free.
  - `styles.generated.ts` and `upstream-sources.json` were regenerated. The worktree `../../Users/...` source-path comments were normalized back to `node_modules/...`, so the generated diff is only the +36 new lines.
- `scripts/eui-upstream-parity.test.mjs`: both factories were added to the `factories` map (12-configuration matrix).
- `packages/core/tests/integration/components/eui-super-select-family-test.gts` is new: module `Borealis super select`, 14 tests.
- `packages/core/tests/integration/components/eui-super-select-test.gts`: one assertion changed (below).
- `packages/core/docs/forms/super-select/index.md`: the API section was regenerated.

## API and default changes

- **New args:**
  - `@placeholder` on both components. It renders `span.euiSuperSelectControl__placeholder` in `forms.colorDisabled` (upstream `controlPlaceholderText`).
  - `@disabled` and `@readOnly` on both. Both disable the button, as upstream, and hide the arrow. The control gets the disabled or read-only styles, and the hidden input gets `readonly`. The list never opens.
  - `@itemClassName` (upstream).
  - `@isDropdownOpen` on the control (focus styles while open).
  - Private `@isPrependProvided`/`@isAppendProvided` on the control.
- **Prepend/append:** `EuiSuperSelect` now forwards its documented `<:prepend>`/`<:append>` blocks to the control. Before, they were declared but never rendered.
- **Removed legacy classes:**
  - `euiSuperSelectControl--fullWidth`, `--compressed` and `--inGroup`. These are now computed styles.
  - `euiSuperSelect--isOpen__button`, replaced by the upstream `open` styles.
  - Kept: `euiSuperSelectControl`, `-isLoading`, `-isInvalid`, `euiSuperSelect`, `euiSuperSelect__listbox`, `euiSuperSelect__item`, `euiSuperSelect__item--hasDividers`.
- **Option DOM changed.** Options were `EuiContextMenuItem` buttons (`euiContextMenuItem` classes). They are now `euiListItemLayout` buttons with `data-test-subj="euiListItemLayout"`.
  - The selected option is primary-colored on `backgroundBaseInteractiveSelect`.
  - The keyboard-focused option gets the `backgroundBaseInteractiveHover` highlight, because upstream removes the item focus outline.
  - Disabled options use `textDisabled`.
  - Options with a `null`/`undefined` value are skipped (upstream).
- **Ember extensions (removed upstream, kept here):**
  - `@hasDividers` draws a `border.thin` bottom border on every option except the last.
  - `@itemLayoutAlign` (`center`/`top`/`bottom`) sets the content's `align-items`. It is marked deprecated.
- **Keyboard (upstream 123):**
  - Space on the control also opens the list (Enter clicks it).
  - Arrow keys no longer wrap around, and they skip disabled options. Before, they wrapped and could land on a disabled button.
  - **Tab on an option now chooses it** and closes the list. Before, Tab was swallowed.
  - The initial focus is the selected option, or else the first one, skipping disabled options forward.
  - On close, focus returns to the control. Unlike upstream, this only happens when focus was in the list or was lost, so an outside click keeps focus on what it clicked.
- **ARIA:**
  - The listbox has `aria-label` "Select listbox" (token `euiSuperSelect.ariaLabel`) instead of `aria-labelledby` pointing at the control's announcement span.
  - `aria-activedescendant` follows the current (focused) option, not the selected one.
  - Options keep `role="option"` and `aria-selected`.
  - The announcement (`euiSuperSelect.screenReaderAnnouncement`) uses upstream's new wording: "...Use the Up and Down arrow keys to navigate or Escape to close."
  - **Removed:** the control's screen-reader-only "Select an option: X, is selected" span (token `euiSuperSelectControl.selectAnOption`), which upstream 123 no longer renders. `@screenReaderId` is a deprecated no-op.
  - **New (upstream):** when `@id` is set and `<id>-label` exists (an `EuiFormRow` with the same `@id`), the button gets `id="<id>-button"` and `aria-labelledby="<id>-button <id>-label"`. A caller's own `aria-labelledby` is kept.
- **Sizes and styles** come from the upstream form-control styles:
  - Height 40px (compressed 32px), with a `line-height` equal to the height and zero block padding.
  - Inline padding 12px (8px compressed), plus 24px for the arrow affordance.
  - `radius.control`, 400px form width, the inset border shadow, focus/open 2px outline and invalid 1px outline.
  - Truncated text.
  - The listbox is at most 300px tall, scrolls, and has 8px padding.
- **Kept Ember semantics:**
  - `@onFocus`/`@onBlur` fire when the list opens and closes. Upstream also forwards them to the button's DOM focus events.
  - `@isOpen` forces the list open.
- **Not ported:**
  - `popoverProps`, the `aria-label` prop (an `aria-label` attribute still lands on the button), the imperative `openPopover`/`closePopover` ref, and the EuiForm `defaultFullWidth` context.
  - Typeahead: upstream has none either.

## Existing test changed

- `eui-super-select-test.gts` "blocks render the options": `hasClass('euiSuperSelectControl--fullWidth')` is replaced by `doesNotHaveClass(...)` plus a computed `max-width: 100%`. The modifier is a removed legacy class. All other assertions are unchanged and pass, including the selection, keyboard, blocks, focus-after-positioning and controlled-value tests.
- `eui-color-palette-test.gts` (a caller) passes unchanged.

## New coverage (`Borealis super select`, 14 tests)

- **Control:**
  - Measured 40/32px height and line height, zero block padding.
  - Padding with the arrow affordance (36/32px). This becomes 60px once the warning icon is added.
  - Box sizing and margin, display, start alignment and truncation.
  - Radius, inset border, background, paragraph color, Inter and the upstream font size.
  - 400px form width, pointer cursor, the arrow at the end, and the icon-count variable.
- **Widths and groups:** fullWidth (800px), compressed radius, and the group (`--group`, prepend wrapper, no own border, fills the group). There are no empty side wrappers.
- **States:**
  - Invalid: class, outline and warning icon.
  - Focus: 2px focus-color outline.
  - Disabled: tokens, cursor, layout class, no arrow.
  - Read-only: tokens, cursor, class, no arrow, hidden input `readonly`.
  - Loading: spinner.
  - Disabled and read-only never open, by click or by keyboard.
  - Open keeps the focus outline.
- **Placeholder:** light and dark colors. It goes away when a value is selected (no element replacement) and comes back for an unknown value. Also checks the hidden input value.
- **Open/close:**
  - The panel is the control's on-screen width, with no panel padding and a z-index of at least 2000.
  - Listbox max height, overflow, padding and `scrollbar-width`.
  - Escape closes and returns focus. `onFocus`/`onBlur` fire in order.
  - Clicking the control toggles the list. An outside click closes it and keeps its own focus.
- **Options:**
  - Layout classes, `itemClassName`, role and type.
  - Inline-flex, full width, padding, radius, color, font, cursor and text padding.
  - Wrapping text and the content gap.
  - dropdownDisplay vs inputDisplay.
  - `aria-selected`, check vs empty icons, and the icon's `@css` (`flex-shrink`).
  - Selected primary color.
  - Disabled: `disabled` attribute, color, cursor; it cannot be chosen.
  - Dividers (1px solid `border.color`, none after the last option), and no dividers by default.
  - `itemLayoutAlign="top"`, and options without a value are skipped.
- **Keyboard:**
  - ArrowDown opens on the first enabled option.
  - `activedescendant` and the highlight follow focus.
  - No wrap at either end, and disabled options are skipped.
  - Tab picks the focused option and returns focus.
  - Space opens on the selected option.
  - Selected+focused and selected backgrounds.
  - Escape does not change the value.
- **ARIA:** form-row `aria-labelledby`, a caller's `aria-labelledby` kept, listbox role/tabindex/label, the description text (screen-reader only), unique option ids, `activedescendant` on the selected option, and no `aria-current`.
- **Reactive args:** compressed, fullWidth, invalid, loading, disabled, value and options all update in place, without replacing the button or the layout.
- **Providers:**
  - Nearest-provider light/dark, a nested override, and sibling isolation.
  - JS-object overrides: `size.xxl` drives the height and line height, `radius.control` applies to the control and the options, and the nearest override wins.
  - Options portaled out of a dark provider keep the dark tokens.
- **RTL:**
  - The control's affordance padding and the arrow move to the left.
  - The options' check column moves to the right (document `dir`, because the list is portaled to the body).
- **High contrast (preferred):** a real 1px border on the control, a 1px `borderStrongPrimary` outline on the selected option, and standard contrast isolated.
- **Standalone `EuiSuperSelectControl`:** the `inputDisplay` block, hidden input, append in a group, and no announcement span.

## Checks (2026-10-12, worktree `eui-wave/super-select`, Node 22, Chromium 130 via the scratchpad shim, `CI=true`)

- Full core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **888 tests, 888 pass, 0 fail**.
- Filtered run (`/super select|super-select|color-palette/i`): **21/21**. That is 14 new, 5 legacy super select and 2 color palette tests.
- `node --test scripts/eui-upstream-parity.test.mjs`: **195/195**.
- `node scripts/generate-eui-styles.mjs --check`: fails with "Stale generated artifact: styles.generated.ts". This is the expected worktree failure (symlinked `node_modules` path comments). The committed file was regenerated, then its comments were normalized.
- `ember-tsc --noEmit`: pass. ESLint on both components and both test files: pass.
- `node scripts/generate-api-docs.mjs --check`: the super select page is regenerated. It reports only `docs/display/list-group/index.md` as stale. That is base drift from the lists family (`externalIconClass` → `externalIconCss`), deliberately left untouched here.
- Not run (coordinator): rollup core build, site build/acceptance, showcase/visual checks.

## Unresolved / for the coordinator

1. **API docs drift** in `docs/display/list-group/index.md`, which predates this branch. Regenerate in the main checkout.
2. **Portaled list direction.** The list follows the document direction, not a local `dir` wrapper around the control. This is the same for every EuiPopover caller.
3. **Icon names.** Upstream draws the arrow with `chevronSingleDown`, through the layout's `@isDropdown`. The layout still uses `arrowDown` (form-controls handoff #1).
4. **The color palette picker** (a caller, not migrated) now renders on the new item layout. Its `euiColorPalettePicker__item*` classes still have no Borealis styles. Audit it with that family.
5. **CSS mappings:** `utils/css-mappings/*` has no super select entries, so there is nothing to clean up.

## Next step

Coordinator: merge, union the generator/parity entries, regenerate in the main checkout, and run the full suite. Then visually check `/docs/forms/super-select` (dividers, `itemLayoutAlign="top"`, EuiHealth displays) and the color palette picker.
