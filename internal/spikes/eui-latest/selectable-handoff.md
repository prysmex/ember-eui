# Selectable and suggest family handoff

Branch `eui-wave/selectable`. Target EUI 123.1.0 / Borealis 8.1.0. Status: **ported, rows left `In progress`**: every family test passes, but the full core suite is 852/853 because of one `Borealis header family` failure (`EuiCollapsibleNav … overlay uses levels.navigation`, z-index 1000 vs 6000) that also fails on the untouched base commit `9e3d1e09` (verified with a `git archive` snapshot build, filtered run 14/15). Mark the rows Migrated once the base is green.

## Scope

EuiSelectable, EuiSelectableList, EuiSelectableListItem, EuiSelectableMessage, EuiSelectableSearch, EuiSelectableTemplateSitewide, EuiSuggest, EuiSuggestInput, EuiSuggestItem. The existing list rendering (fixed row heights, computed list height, `scrollIntoView` of the current option, no react-window) is kept as the Ember "virtualization".

## Files

- Components: `eui-selectable.gts`, `eui-selectable-list.gts`, `eui-selectable-list-item.gts`, `eui-selectable-message.gts` (now a Glimmer class), `eui-selectable-search.gts`, `eui-selectable-template-sitewide.gts`, `eui-suggest.gts`, `eui-suggest-item.gts` (now a Glimmer class). `eui-suggest-input.gts` unchanged (no styles of its own).
- `src/-private/selectable-options.ts`: `checked` type adds `'mixed'` (toggling already treated it as unchecked → `'on'`, as upstream).
- `src/utils/eui/selectable.ts` (new, upstream license header): hand port of `selectable_list.styles.js` (`euiSelectableListStyles`, `euiSelectableListGroupLabelStyles`) and `selectable_template_sitewide.styles.js` (`euiSelectableTemplateSitewideStyles`, `euiSelectableTemplateSitewidePopoverStyles`). Reasons: upstream builds `euiSelectableList__list` with `@emotion/css` (a global document cache for react-window), and the sitewide meta colors come from `euiPaletteColorBlind()`, which reads the global `EUI_VIS_COLOR_STORE`; the port reads `euiTheme.colors.vis` like `token.ts`. Neither could be extracted without patching the generator adapters.
- `src/utils/eui/suggest.ts` (new): **EuiSuggest has no upstream styles in 123.1.0** — it was removed in EUI 89.0.0 (#7263, "use EuiSelectable or EuiComboBox"), still in Sass. This file translates the last upstream styles (EUI 88.5.4 `_suggest_item.scss`/`_suggest_input.scss`/`_variables.scss`) to Borealis tokens: type tints `tintOrShade(vis color, 82%, 70%)` + `makeHighContrastColor`, `tint10` = `darkShade`, code font label, `textSubdued` description, hover/focus `backgroundBaseInteractiveHover` (Borealis list hover) instead of `$euiFocusBackgroundColor`. No parity test is possible (no upstream factory).
- `scripts/generate-eui-styles.mjs` (`// selectable and suggest` block, plus names appended to existing keys so the key union keeps them): `euiSelectableStyles`, `euiSelectableMessageStyles`; helpers `euiYScrollWithShadows` (`_helpers.js`), `euiTitle` (`title.styles.js`), `euiTextBreakWord` (`_typography.js`). 203 factories extracted. `styles.generated.ts` / `upstream-sources.json` regenerated, worktree source-path comments normalized back to `node_modules/…`.
- `scripts/eui-upstream-parity.test.mjs`: `euiSelectableMessageStyles` in the 12-configuration matrix; new tests "selectable static styles and new helpers match upstream" (static `euiSelectableStyles`, `euiTextBreakWord`, `euiYScrollWithShadows` ×3 options, `euiTitle` ×6 sizes in 12 configurations) and "selectable list and sitewide hand ports match upstream in 12 theme configurations" (the `@emotion/css` slot is compared as `css-<name>` + the styles upstream registered in `@emotion/css`'s cache; the vis store is set to each theme's `colors.vis` and restored).
- Tests: new `tests/integration/components/eui-selectable-family-test.gts` (module `Borealis selectable and suggest`, 14 tests); updated `eui-selectable-test.gts` and `eui-combo-box-pill-test.gts` (below).
- API docs regenerated: `docs/forms/selectable/index.md`, `docs/forms/suggest/index.md`. (The generator also rewrote `display/icons`, `display/list-group`, `layout/panel`, `navigation/button` pages for the coordinator's earlier `@css` arguments; those are stale on the base and were reverted here to keep this branch in scope.)
- Not touched: EuiFieldSearch, EuiPopover/Title/Footer, EuiInputPopover, EuiToolTip, EuiHighlight/EuiMark, EuiText, EuiBadge, EuiIcon, EuiCheckbox, providers/shared utils, site/showcase, docs demos.

## API / default changes (latest-only, upstream)

**EuiSelectable**
- **`@singleSelection` defaults to `false` (was `undefined`, same behavior) and multiple selection now renders upstream check box indicators** (`EuiCheckboxControl` styles: primary when checked, `backgroundFilledDanger` when excluded, dash when mixed) instead of check marks; options use **`aria-checked`** (`true`/`false`/`mixed`) instead of `aria-selected`. Single selection keeps icon indicators + `aria-selected`, plus the upstream selected background (`backgroundBaseInteractiveSelect`, `textPrimary`). `allowExclusions` or a `mixed` option always use `aria-checked`.
- **`listProps.onFocusBadge` defaults to `false`** (upstream; was `true`). New `listProps.paddingSize` (`'s'`). New `@css` (composed last into the root class; used by the sitewide template).
- Keyboard: Space toggles the current option in non-searchable lists (upstream); in the search field Space still types. Alt/Shift/Control/Meta no longer reset the current option. Fixed: focusing with the first option current (index 0) no longer re-picks it.
- Search: an sr-only paragraph with upstream `euiSelectable.screenReaderInstructions` is rendered after the field and linked through `aria-describedby`; the listbox gets `aria-label` (placeholder) on the `<ul>` (was on the list wrapper `div`).
- Root `euiSelectable-fullHeight` class removed (upstream `fullHeight` style instead).

**EuiSelectableList**: upstream root (`:has(:focus-visible)` outset focus ring, `bordered`, `paddingSize.s`, `fullHeight` flex-grow) and scroll container (`euiYScrollWithShadows` with animated overflow shadows, focus outline none). Legacy `euiSelectableList-fullHeight` / `-bordered` classes removed. Group labels: upstream `euiTitle xxxs`, divider line before later labels (`selectableListItemBorderColor`), height `rowHeight + 16` after the first (upstream `getListItemSize`). New `@ariaLabel`, `@ariaDescribedby`, `@paddingSize`. `aria-posinset` fixed to count only options before the item (was `index + 1 − all group labels`). An option's own `title` property wins over `searchableLabel`/`label`. Standalone with `@singleSelection` undefined: options look single while the listbox is multiselectable (upstream quirk; EuiSelectable always passes a boolean).

**EuiSelectableListItem**: upstream `EuiListItemLayout` structure/styles (`li.euiListItemLayout.euiSelectableListItem` > `span.euiListItemLayout__content` > indicator, `__prepend`, `__text` (truncated), `__append`); existing `euiSelectableListItem__*` class names kept on the same parts and on both indicators. **`title` moved from the `<li>` to the text span** (upstream: avoids the name being announced twice) via the new `@title` argument. New `@singleSelection`, `@searchable`, `@role`, `@isInteractive`, `@checked="mixed"`. `aria-selected` reflects `checked` even when disabled (was forced `false`). Screen reader text is upstream's (state + instructions, e.g. "Excluded option. To uncheck this option, press Enter."; tokens `euiSelectableListItem.checkOptionInstructions`, `…uncheckOptionInstructions`, `…excludeOptionInstructions`, `…mixedOption*`); the old `includedOption`/`includedOptionInstructions`/`excludedOptionInstructions` strings are gone. `@onFocusBadge` defaults to `false`. `data-test-subj="euiListItemLayout"` (upstream default, overridable).

**EuiSelectableMessage**: `--bordered` class removed (computed border). Rendered as one `div.euiText.euiSelectableMessage` whose single class composes EuiText (`xs`, `subdued`) + `euiSelectableMessageStyles` (EuiText has no `@css`; see Unresolved). `data-test-subj="euiSelectableMessage"`.

**EuiSelectableSearch**: **`compressed` defaults to `true`** (upstream); `aria-owns` added; private `@ariaDescribedby`/`@instructions`.

**EuiSelectableTemplateSitewide**: upstream root/meta/popover styles; meta types `application`/`deployment`/`article`/`case`/`platform` get medium weight + high-contrast vis colors, metas are separated by `•`. **`rowHeight` 52 (was 68)**, popover `@panelPaddingSize="s"` (was `none`) and `@anchorPosition="downCenter"` (EuiPopover's default is now `downLeft`). Loading uses `EuiSelectableMessage` (legacy `euiText--extraSmall` div removed); empty/no-match messages get the upstream 300px min height. Options get upstream's `title` (label + meta texts).

**EuiSuggest / EuiSuggestItem / EuiSuggestInput**: Ember API unchanged. Root gets `class="euiSuggest"`. Items: label and description truncate together with `title`s (EUI 88 `truncate`), `descriptionDisplay="wrap"` wraps both; without a description the label expands (no width class).

## Existing test changes

- `eui-selectable-test.gts`: `li[title="X"]` → `li:has([title="X"])` (title moved to the text, upstream a11y); multiple selection `aria-selected` → `aria-checked` (and asserts no `aria-selected`); the keyboard test passes `listProps.onFocusBadge=true` and the standalone item `@onFocusBadge={{true}}` (badge now off by default, upstream); `euiSelectableMessage--bordered` class → asserts the class is gone and the computed border is solid.
- `eui-combo-box-pill-test.gts`: a checked, disabled standalone option now has `aria-selected="true"` (upstream EuiListItemLayout keeps the selection state; it was forced `false`).

## New coverage (`Borealis selectable and suggest`, 14 tests)

Root flex column, scroll container overflow, scoped list reset, list heights (rows × rowHeight, 6.5 rows, numeric, full) and group label heights; reactive `bordered`/`paddingSize`/`rowHeight` without element replacement (border color/width/radius, padding). List item measured layout (inline-flex, padding, control radius, `s` font, text padding, gap, truncation, title on text), prepend/append, indicators; states on/off/mixed/focused/selected+focused/disabled with icons and backgrounds, multiple selection check boxes (checked/excluded/mixed/unchecked/disabled), selected background without indicators, aria-checked vs aria-selected, SR state text. Selectable multi/single/always/exclusions semantics (listbox attrs, posinset/setsize, clicks, mixed → on), standalone list quirk. Keyboard (first checked on focus, skipping labels/disabled, wrap, modifiers, Space vs Enter, search activedescendant). Search (combobox aria, controls/owns, sr instructions, listbox label, compressed 32px, filtering, marks, SR instructions, no-match message). Messages (EuiText xs subdued + flex/center/padding, reactive bordered, loading/empty/custom/bordered list). Group label title styles/divider, focus badge default/true/text/icon. Sitewide popover (padding s, below and centered, 600px), rowHeight 52, single selection, title, meta list/type colors/weight/bullets, footer padding, 300px empty/loading messages. Suggest item (type size/padding/tint colors, code label, label widths reactive, description subdued/truncate/wrap, tint10) and suggest statuses (dot + tooltip text, check, spinner, none), button reset/full width/focus background/underline, click. Light/dark nearest provider + sibling isolation (selectable, message, suggest tints). JS-object overrides (`backgroundBaseInteractiveSelect`, `textPrimary`, `size.s`) and isolation; high contrast preferred (selected outline `borderStrongPrimary`, focused underline). RTL order of indicator/prepend/text/append and suggest type/label.

## Checks (worktree, Chromium 130, CI=true, Node 22; pnpm unavailable, binaries run directly)

- Core (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **853 tests, 852 pass, 1 fail** — the pre-existing `Borealis header family: EuiCollapsibleNav: overlay vs docked…` (z-index 1000 vs `levels.navigation` 6000). The same test fails on base `9e3d1e09` built from a `git archive` snapshot (filtered: 14 pass, 1 fail). All 14 `Borealis selectable and suggest` tests, `eui-selectable`, `eui-selectable-template-sitewide`, `eui-suggest` and `eui-combo-box-pill` pass (filtered `/selectable|suggest/i`: 30/30).
- `node --test scripts/eui-upstream-parity.test.mjs`: **173/173** (170 before + 1 factory + 2 tests).
- `node scripts/generate-eui-styles.mjs --check`: expected worktree failure (symlinked `node_modules` source-path comments); regenerated and normalized.
- `ember-tsc --noEmit`: pass. ESLint on all changed sources/tests: pass.
- `node scripts/generate-api-docs.mjs --check`: only the four base-stale out-of-family pages listed above.
- Not run (coordinator): rollup build, site build/acceptance, showcase.

## Unresolved / for the coordinator

1. **EuiText needs `@css`.** EuiSelectableMessage composes EuiText's styles itself (one class, like the overlays popover panel) because upstream renders `<EuiText css={message}>`. Once EuiText takes `@css`, switch to `<EuiText @color="subdued" @size="xs" @css={{message}}>`.
2. Pre-existing header failure above (EuiCollapsibleNav overlay z-index after the header × modal-flyout merge).
3. Base API docs are stale for the `@css` pages (icons, list-group, panel, button); regenerate in the main checkout.
4. EuiSuggest has no upstream counterpart in 123.1.0; its styles are a Borealis translation of the last Sass (EUI 88.5.4). Upstream recommends EuiSelectable/EuiComboBox instead — consider deprecating it in the docs.
5. Not ported: upstream `textWrap`/`truncationProps` (EuiTextTruncate) and `isVirtualized=false` wrapping — options always truncate with CSS at a fixed row height; `isPreFiltered.highlightSearch`; option `toolTipContent`; `hasAriaDisabled`; `onActiveOptionChange`; `errorMessage`; the searchable live region ("N results available"); sitewide `colorModes` and `popoverButtonBreakpoints`; selectable `searchProps.value` (controlled search).
6. `utils/css-mappings/eui-selectable-list-item.ts` is now unused by the component (the registry still imports it).

## Next step

Coordinator: merge, regenerate in the main checkout, rerun parity and the full core suite, then mark the nine rows Migrated once the header failure is fixed; check the docs selectable/suggest/sitewide demos visually (check boxes, compressed search, 52px sitewide rows).

## Upstream gaps closed (2026-10-13, branch `eui-wave/selectable`)

All gaps from the docs audit exist in EUI 123.1.0 and are ported. The EuiSelectable row is gone from `docs-audit-gaps.md`. A new EuiInputPopover row (`closeOnScroll`) was added there, because the input popover demo has to leave it out.

`searchableLabel` was already used for matching and for the `title`. It now also falls back with `||` like upstream (an empty `searchableLabel` uses the label), and it has a test and a demo.

### Files

- `src/-private/selectable-options.ts`:
  - New option keys: `hasAriaDisabled`, `textWrap`, `truncationProps`, `toolTipContent`, `toolTipProps`, `data`, `data-test-subj`.
  - The upstream matcher API: `EuiSelectableOptionMatcher` and `createPartialStringEqualityOptionMatcher`.
  - `getMatchingOptions(options, search, isPreFiltered, optionMatcher)`, `isNavigable`, and `toggleOptionWithChange`, which also returns the changed option. `toggleOption` is kept.
  - Nothing mutates its input. Every function returns new arrays/objects.
- `eui-selectable.gts`, `eui-selectable-list.gts`, `eui-selectable-list-item.gts`, `eui-selectable-search.gts`.
- New private `eui-selectable-list/option-text.gts`: upstream `renderSearchedText` / `renderTruncatedText`. Its app-js export was added to `package.json` by hand; rollup also reorders `eui-in-memory-table`, which was left out.
- Tests: new `tests/integration/components/eui-selectable-upstream-props-test.gts` (module `eui-selectable upstream props`, 19 tests). No existing test was changed.
- Docs (`docs/forms/selectable/`):
  - d01 and d02 add `data-test-subj`; d02 uses the yielded parts with `aria-label`, like upstream.
  - d06 adds the error switch.
  - d07 adds the upstream "In an input popover" example (controlled `searchProps.value`, `onChange(options, event, changedOption)`, `isPreFiltered={ highlightSearch: false }`, `listProps.css`).
  - New pages: d08 Truncation, d09 Tooltips, d10 Tooltips on disabled options, d12 Custom option matcher.
  - d11 Rendering the options (was d08) adds the Virtualized switch, `searchableLabel` and `option.data`.
  - d13 is the old d09 Ember extra.
  - The API tables were regenerated; only the selectable page changed.

### API (additive)

**EuiSelectable**
- `@errorMessage` (string; `null` or `undefined` shows nothing). It wins over the loading, no-match and empty messages.
- `@optionMatcher` gets `{ option, searchValue, normalizedSearchValue }`.
- `@isPreFiltered` also takes `{ highlightSearch: false }`.
- `@selectableScreenReaderText` is prepended to the search instructions.
- `@onActiveOptionChange(option | null)`.
- `@onChange(options, event, changedOption)`: the two extra arguments are new.
- `@searchProps`:
  - `value` makes the search controlled. Without it the search is internal UI state.
  - `onChange(searchValue, matchingOptions)` is also called once after the first render, like upstream's mount call. `onSearch` stays as an alias that is not called on render.
  - Also new: `onKeyDown`, `onClick`, `onFocus`, `onBlur`, `inputRef`, `isLoading`, `isClearable`, `'data-test-subj'`.
- `@listProps` adds `isVirtualized`, `textWrap`, `truncationProps` and `css` (composed last into the list root).
- `visibleOptions` is a `@cached` derivation of `@options` and the search. No copy of `@options` is kept.
- The tracked state is only `internalSearchValue` (uncontrolled search), `internalActiveOptionIndex` and `isFocused`.
- A current option that falls out of range after `@options` is replaced is dropped (upstream sets it to `-1`).

**EuiSelectableList**
- New `@isVirtualized`:
  - `false` drops the row and group label heights and the computed list height. A numeric `@height` is kept.
  - Ember EUI renders all rows either way, so "virtualized" means fixed rows and a computed height.
- New `@textWrap`. An option's own `textWrap` wins, and wrapping only applies when not virtualized.
- New `@truncationProps`, merged with the option's own (the option wins). It renders EuiTextTruncate.
- New `@isPreFiltered` and `@css`.
- While searching, labels highlight the match. When virtualized, the text is truncated around the match (`startEnd`), with EuiMark when the shown text is shorter than the search.
- The width is shared like upstream's `defaultOptionWidth`: a ResizeObserver on the list (settled-aware), minus scrollbar, padding, icon and focus badge offsets. It is used only for options without prepend/append.
- No text `title` when truncationProps or a tooltip is used.
- A non-searchable listbox gets `aria-activedescendant`.
- Options pass `data-test-subj` (default `euiListItemLayout`), `hasAriaDisabled`, `textWrap` and the tooltip.
- `@onOptionClick(options, event, changedOption)`.

**EuiSelectableListItem**: new `@hasAriaDisabled` (focus styles, focus badge and tooltip on a disabled option), `@textWrap`, and `@toolTipContent` / `@toolTipProps`. The tooltip is EuiToolTip around the content: position `left` by default, a full-width anchor, `aria-describedby` on the `<li>`, shown on hover and while `@isFocused`, and never on natively disabled options.

**EuiSelectableSearch**: new `@value` (controlled), `@optionMatcher`, `@isClearable`, `@inputRef`, `@onKeyDown`, `@onClick`, `@onFocus`, `@onBlur`, `@dataTestSubj`, and private `@ariaLabel` / `@activeDescendant`.

**Keyboard / a11y**: `hasAriaDisabled` options are navigable but cannot be selected. Searchable lists get upstream's live region: "N results available" (disabled options not counted), or the message, active once an option is current or a message shows. The token is `euiSelectable.searchResults`.

### Deliberate behaviour changes (old → new, upstream reference)

1. **Keys pressed on other content inside the selectable** (e.g. a footer button in the yielded layout): before, they moved and toggled the current option. Now they reset it and do nothing (`selectable.tsx` `onKeyDown` → `isFocusOnSearchOrListBox`). Ember keeps one difference: keydown dispatched on the root element itself still navigates, because existing tests rely on it.
2. **Searching renders labels through EuiTextTruncate** (`startEnd` around the match) when virtualized. Before, it was a CSS ellipsis with EuiHighlight (`selectable_list.tsx` `getTruncationProps` / `renderSearchedText`). The marks are the same; long labels keep the match visible.
3. **Non-searchable listbox has `aria-activedescendant`** (before: none). Upstream: `selectable_list.tsx` `componentDidUpdate`.
4. **The search filters on `input` events too** (paste, cut), not only keyup/change (`selectable_search.tsx` `onChange`).
5. **The search's `aria-label` (placeholder) and `aria-activedescendant` also apply to a yielded `parts.search`.** Before, only the default layout set them (upstream always passes them to the search).
6. **The blur reset runs after the render** (`actions` queue). Removing the focused list during a render, e.g. when `@options` becomes empty, no longer updates state that was already rendered.

### Ember differences kept

- Focusing the search field still makes the first checked or first option current. Upstream only sets `isFocused`. Existing tests rely on this (`Borealis selectable and suggest` keyboard test).
- Messages are strings only (upstream also takes elements).
- `option.data` is yielded as `option.data.*` (upstream spreads it onto the option given to `renderOption`).
- Option prepend/append are text or the `<:optionPrepend>` / `<:optionAppend>` blocks.
- `onFocusBadge` takes `{ text, iconSide }`, not full EuiBadge props.
- A controlled `searchProps.value` reaches the field through an `input` event dispatched after render. EuiFieldSearch updates its own text from a changed `@value` inside the render (a `didUpdate`), and its clear button then throws ("must pass a function to on") when the value becomes `''`. Listeners on the field see that synthetic event.

### Other upstream props still missing

- Root `aria-label` / `aria-describedby` moved onto the search and listbox (`getAccessibleName`).
- Root `id`-based ids.
- `listProps['aria-label'|'aria-describedby'|'autoFocus'|'windowProps'|'activeOptionIndex']`.
- Other EuiFieldSearch props in `searchProps` (prepend/append, …).
- Arbitrary HTML attributes and `css` on options and group labels (only `className` and `data-test-subj`).

### Checks (2026-10-13, worktree `eui-wave/selectable`, Chromium 130, CI=true, Node 22)

- Full core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **1352/1352**. That is main's 1333 plus the 19 new tests.
- Filtered `/selectable|suggest|search/i`: 87/87.
- `ember-tsc --noEmit`: pass. ESLint on every changed source and test: pass.
- `node --test scripts/eui-upstream-parity.test.mjs`: **349/349**. There are no generator changes, and `euiSelectableListGroupLabelStyles` is untouched.
- `node scripts/generate-api-docs.mjs --check`: current.
- Not run, as instructed: `scripts/sync-injected.mjs` and the companion package suites. Also not run: site build and visual checks.

### For the coordinator

1. **EuiFieldSearch** (form packages): updating `this.value` in `didUpdate` while rendering breaks the clear button's `{{on "click" @clear}}` when `@value` becomes `''`. EuiSelectableSearch works around it. A fix there (derive the text from `@value` when given) would let `syncValue` go.
2. **EuiInputPopover** lacks upstream `closeOnScroll` (the gap row was added).
3. Check the selectable docs demos visually, especially the truncation resize panel, tooltips and the input popover example.
