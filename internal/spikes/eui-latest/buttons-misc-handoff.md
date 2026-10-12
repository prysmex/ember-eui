# Buttons misc migration handoff (EuiButtonGroup, EuiButtonGroupButton, EuiButtonContent, EuiFacetButton, EuiFacetGroup, EuiFilterButton, EuiFilterGroup, EuiFilterSelectItem)

Status: **Migrated**. The full core suite passes in Chromium 130 (812/812), along with upstream parity, types and lint; API docs regenerated for this family.

## Files

- Components (all now Glimmer classes with `@cached` style getters; factories only through `useEuiBorealisStyles`):
  - `eui-button-group.gts`, `eui-button-group-button.gts`
  - `eui-button-content.gts`
  - `eui-facet-button.gts`, `eui-facet-group.gts`
  - `eui-filter-button.gts`, `eui-filter-group.gts`, `eui-filter-select-item.gts`
- New `packages/core/src/-private/eui-filter-group-context.ts`: upstream `EuiFilterGroupContext` (`compressed`, `display`, `showDividers`) through `ember-provide-consume-context`.
- New `packages/core/src/utils/eui/buttons-misc.ts`: hand port of upstream `button_group_button.styles.js` (`euiButtonGroupButtonStyles`, `_compressedButtonFocusColors`). The upstream module imports `euiScreenReaderOnly` from the React `components/accessibility` barrel, so the generator rejects it (same situation as the key pad menu item port). License header kept; parity-tested.
- `scripts/generate-eui-styles.mjs` (`// buttons-misc` block) and `scripts/eui-upstream-parity.test.mjs`; regenerated `styles.generated.ts` and `upstream-sources.json` (never hand-edited).
- Tests: new `tests/integration/components/eui-buttons-misc-test.gts` (16 tests); updated `eui-button-group-test.gts`, `eui-facet-test.gts`, `eui-filter-group-test.gts`, `eui-button-test.gts` (see below).
- API docs regenerated: `docs/navigation/button/index.md`, `docs/forms/filter-group/index.md`. (The generator also wanted to update `display/icons`, `display/list-group` and `layout/panel` pages: that is base-branch drift from the `@css` work, not this family, so those were left untouched.)

## Generator entries added

New factories:

- `components/button/button_group/button_group.styles.js`: `euiButtonGroupStyles` (static), `euiButtonGroupButtonsStyles`
- `components/facet/facet_button.styles.js`: `euiFacetButtonStyles`, `euiFacetButtonTextStyles`, `euiFacetButton__disabled` (static)
- `components/facet/facet_group.styles.js`: `euiFacetGroupStyles`
- `components/filter_group/filter_button.styles.js`: `euiFilterButtonDisplay`, `euiFilterButtonStyles`, `euiFilterButtonWrapperStyles`, `euiFilterButtonChildStyles`
- `components/filter_group/filter_group.styles.js`: `euiFilterGroupStyles`
- `components/filter_group/filter_select_item.styles.js`: `euiFilterSelectItemStyles`

Helpers needed by the hand port, added to existing keys (merge: union by key):

- `global_styling/mixins/_states.js`: + `euiOutline`
- `global_styling/mixins/_button.js`: + `BUTTON_COLORS`, `euiButtonSizeMap`
- `global_styling/functions/high_contrast.js`: + `preventForcedColors`
- new keys `global_styling/functions/typography.js`: `euiTextShift`; `global_styling/utility/selectors.js`: `euiDisabledSelector`

Generator: 174 factories, React-free. Parity: factory-matrix entries for all new function factories, plus two new tests: the hand port in 12 theme configurations, and static slots (`euiButtonGroupStyles`, `euiFacetButton__disabled`).

## API and default changes (latest-only)

### EuiButtonContent

- Now a Glimmer class. **Unchanged default contract**: without `@size` it renders exactly as before (classless `euiButtonContent`, icon first in DOM; callers style it), so EuiButton/EuiButtonEmpty keep passing untouched.
- The legacy `euiButtonContent--iconRight` modifier class is removed (latest-only). EuiButton/EuiButtonEmpty already place the icon with `flex-direction: row-reverse`.
- New opt-in `@size` (`xs`/`s`/`m`): applies upstream `euiButtonDisplayContent` + `content[size]` + `euiTextTruncate` itself, renders the icon **after** the text for `@iconSide="right"` (upstream DOM order), and adds the `eui-textTruncate` class to the text wrapper. Also new `@isDisabled` (spinner `border: currentcolor`, as upstream), `@textCss` (composed last into the text wrapper class, the `@css` pattern) and `@textDataText` (for `euiTextShift`).
- `@iconSide` type widened to `'left' | 'right'`. Spinner size falls back to `m` for icon sizes the spinner lacks (`original`, …).

### EuiButtonGroup / EuiButtonGroupButton

- Group buttons no longer render through `EuiButton`. Like upstream (`EuiButtonDisplay` + group styles), the option element gets one class composed from `euiButtonDisplayStyles`, the group button slots and `euiButtonDisplaysColors[fill|empty][color]`. Root class `euiButtonGroupButton` plus upstream state classes `-isSelected` / `-isIconOnly` kept; the inner `euiButton__content/__text` wrappers are gone (content is `euiButtonContent` + `euiButtonGroupButton__text`).
- **Single selection keeps the Ember radio semantics** (deliberate difference from upstream 123, which renders `aria-pressed` buttons for both types): a `<label>` with a visually hidden radio (now hidden with the `screenReaderOnly` modifier — the old `euiScreenReaderOnly` class had no CSS once legacy styles were removed), shared `name`, native arrow-key navigation, `@onChange(id, value)` on `change`. The label shows the focus ring through `:has(> input:focus-visible)`. Multi selection: `<button aria-pressed>`, `@onChange(id)`.
- Upstream sizes: container 32/40px (`s`/`m`, `compressed` = `s`) with `xs` padding, plain background and an `::after` border; buttons are inset 24/32px with a 6px radius; icon-only buttons are square. Default color `text` (selected = `backgroundLightText`); other colors fill when selected. Disabled + selected uses `buttonGroupBackgroundDisabledSelected`.
- Colors: upstream `BUTTON_COLORS` plus `neutral`/`risk`; `ghost` still accepted and renders as `text`; unknown names fall back to `primary`.
- **Removed classes:** `euiButtonGroup--{size}`, `--{color}`, `--fullWidth`, `--isDisabled` (upstream `euiButtonGroup-isDisabled` is used instead), `euiButtonGroupButton__textShift`.
- **New option fields** `toolTipContent` / `toolTipProps` (`position`, `title`, `delay`): wraps the option in `EuiToolTip` with upstream `euiButtonGroup__tooltipWrapper(-isSelected)` anchor classes.
- Fieldset/legend get a scoped React reset (`border: none`, `min-inline-size: auto`, …).
- `EuiButtonGroup` is now a class (default export); the named export is kept.

### EuiFacetButton / EuiFacetGroup

- Facet button: upstream `EuiButtonDisplay` size `s` (32px) + `euiFacetButton`; text uses `euiTextShift` + truncate, bold (600) when selected; disabled text `textDisabled`, `pointer-events: none`, icon and quantity at opacity 0.5. Removed classes `euiFacetButton--isSelected/--unSelected`. Text inherits the display's medium (450) weight when not selected, as upstream.
- Facet group: plain `div.euiFacetGroup` with upstream flex/gap styles instead of `EuiFlexGroup` (no `euiFlexGroup` class, no `--vertical`/`--gutter*` classes). Gaps: vertical `gap: <g> 0`, horizontal `gap: <g> <g + 12px>` (none/s/m/l = 0/4/8/12px).

### EuiFilterGroup / EuiFilterButton

- Filter group: new `@compressed`, `@display` (`regular`/`highlighted`) and `@showDividers` (default `true`, upstream) args, shared with buttons through context; `data-display` / `data-dividers` attributes as upstream. `--fullWidth` class removed (`display: flex`).
- **Filter button DOM follows upstream:** a `div.euiFilterButton__wrapper` (padding, dividers, withNext overlap, grow, notification min width) around the `<button>`; `...attributes` stay on the button. Text wrapper renamed `euiFilterButton__textShift` → upstream `euiFilterButton__text` (+ `-hasNotification`). Removed classes `--hasIcon`, `--noGrow`, `--withNext`; added upstream `-isIconOnly` (no default block) and `-isToggle`.
- It no longer renders through `EuiButtonEmpty`: the button composes `euiButtonEmptyStyles` (or `EuiButtonDisplay` + `base/fill` colors for toggles) with the filter slots in one class, as upstream passes `css` to its button. The root still has class `euiButtonEmpty` (`euiButton` for toggles), like upstream.
- New `@isToggle` (upstream): small EuiButton look, `aria-pressed`, `backgroundLightText` when selected, filled in `highlighted` groups or non-text colors, and the badge rendered in the inverse color mode (nested `EuiEmotionProvider`, upstream `EuiThemeProvider colorMode="INVERSE"`).
- New `@badgeColor` (`accent` default, `success`). Badge gets `role="marquee"` (upstream).
- **ARIA change:** buttons with `@iconType` `chevronSingleDown` (upstream) or `arrowDown` (Ember's name for the same icon) are popover anchors: they get `aria-expanded` (from `@isSelected ?? @hasActiveFilters`) and no longer `aria-pressed`. Other buttons keep `aria-pressed` from `@isSelected` (Ember compatibility; upstream only sets it on toggles).
- `@hasActiveFilters` font weight is upstream medium.

### EuiFilterSelectItem

- **`aria-selected` now follows `@checked === 'on'`** (upstream) instead of `@isFocused`. Focus is the upstream focus background/primary/underline. `euiFilterSelectItem-isFocused` class removed.
- Scrolls into view (`block: 'nearest'`) when `@isFocused` becomes true, as upstream.
- New `@truncateContent` (default `true`).

## Styling migrated children

- `EuiNotificationBadge` has no `@css`. Upstream styles the filter button badge (`cursor: inherit`, `transition: none`, `forced-color-adjust`, disabled opacity) and the facet quantity (disabled opacity) through `css`. Interim: those slots are scoped from the owning button (`& .euiFilterButton__notification`, `&:disabled :is(.euiFacetButton__icon, .euiFacetButton__quantity)`), which is deterministic by specificity, not by insertion order. **Coordinator: add `@css` to EuiNotificationBadge**, then pass these slots there.
- `EuiFlexItem` has no `@css`: the select item's `eui-textTruncate` is scoped from the button (`& .euiFilterSelectItem__content`).
- `EuiToolTip` (overlays family) anchor gets the upstream `tooltipWrapper` slot through `@anchorClassName`; if the tooltip migration gives the anchor its own Emotion class, switch to an `@anchorCss`/`@css` argument.
- Suggested follow-up for the button family owner: EuiButton/EuiButtonEmpty can pass `@size` to EuiButtonContent and drop their duplicated content/text Emotion classes (and their `row-reverse`), matching upstream DOM order.

## Unresolved / for the coordinator

1. `@css` on EuiNotificationBadge / EuiFlexItem (above).
2. Upstream variant APIs not ported: the children API of EuiButtonGroup (`data-variant` segmented/selection), `hasAriaDisabled`, filter select item `toolTipContent`. The Ember combo box renders its own `euiFilterSelectItem` markup (not this component) and keeps its legacy classes.
3. Hover/active computed colors, forced-colors mode and real keyboard arrow navigation between radios need trusted input/emulation (root browser checks); covered here structurally (radios share a name, take focus, focus ring on the label).
4. Docs demos for facet/filter/button group were not visually audited.

## Checks run (2026-10-12, worktree `eui-wave/buttons-misc`)

Environment: Node 22, Chromium 130 through the scratchpad `google-chrome` shim, `CI=true`; binaries run directly (no pnpm).

- Core tests (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **812 tests, 812 pass, 0 fail**, including the 16 new `Borealis buttons misc` tests.
- `node --test scripts/eui-upstream-parity.test.mjs`: **148/148 pass**.
- `node scripts/generate-eui-styles.mjs --check`: pass (174 factories, React-free).
- `ember-tsc --noEmit`: pass. ESLint on all changed components, utils and tests: pass.
- `node scripts/generate-api-docs.mjs --check`: this family's pages are current; it still lists `display/icons`, `display/list-group` and `layout/panel` as stale, which is base-branch drift (the coordinator's `@css` and lists work), deliberately not regenerated here.
- Not run (root): rollup core build, site build/acceptance, showcase.

## Existing tests updated (legacy-class assertions)

- `eui-button-test.gts` "@iconType and @iconSide": `euiButtonContent--iconRight` class → measured icon position after the text.
- `eui-button-group-test.gts`: `--small/--text/--medium/--primary/--fullWidth` classes → computed display/width; `--isDisabled` → upstream `euiButtonGroup-isDisabled`.
- `eui-facet-test.gts`: `--isSelected/--unSelected` → computed font weight; `--vertical/--gutter*`/`euiFlexGroup` → computed flex direction (gaps measured in the new file).
- `eui-filter-group-test.gts`: `--fullWidth` → `display: flex`; `--withNext`/`--hasIcon` classes dropped (withNext measured in the new file, icon presence asserted); `__textShift` → upstream `__text`; the arrowDown anchor now asserts `aria-expanded` instead of `aria-pressed`; select item `-isFocused`/`aria-selected` → `aria-selected` follows `@checked`, focus asserted by background.

Nothing unrelated was weakened.

## Test notes

- The disabled facet icon uses `@type="dot"`; when an icon had to load, EuiIcon's `isLoaded` fade-in animation fills and overrides opacity, so the test cancels it before measuring (applies upstream too). Notification badges animate every property; finite animations are finished first.

## Next step

Coordinator: merge (union the generator/parity entries, including the helper names added to existing `_states`/`_button`/`high_contrast` keys), regenerate, run the full suite; add `@css` to EuiNotificationBadge/EuiFlexItem and switch the scoped slots; consider moving EuiButton/EuiButtonEmpty to EuiButtonContent `@size`.
