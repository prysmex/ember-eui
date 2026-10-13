# Combo box family migration handoff (EuiComboBox, trigger, input, options, group, messages, create option, pill)

Status: **Migrated**. The full core suite passes in Chromium 130 (875/875), along with upstream parity (181/181), types, lint and the combo box API docs.

The engine is still ember-power-select / ember-basic-dropdown, with the same keyboard behavior, selection, `@onChange` contract, search, async options, create option and positioning. Only the styling, the private DOM and the a11y attributes changed.

## Files

- Components. All style getters are `@cached`, and factories only go through `useEuiBorealisStyles`:
  - `eui-combo-box.gts`: `rootClass` and `panelClass`. It also adds blockless rendering and makes `opts` work while `@options` is a promise.
  - `eui-combo-box/trigger.gts`: the wrap, layout, placeholder and spacer classes.
  - `eui-combo-box/trigger/input.gts`: the input and container classes, plus the input's aria attributes.
  - `eui-combo-box/options.gts`: list item rows, ids, posinset and the list classes.
  - `eui-combo-box/group.gts`, `no-matches-message.gts`, `search-message.gts`: were template-only, now Glimmer classes.
  - `eui-combo-box/create-option.gts`.
  - `eui-combo-box-pill.gts`: was template-only, now a Glimmer class.
- `src/utils/eui/combo-box.ts` (new, with the upstream license header). It holds:
  - A hand port of `euiSelectableListGroupLabelStyles`. The upstream module also imports `@emotion/css`, a DOM-backed Emotion instance. Extracting it made the generator bundle a second Emotion runtime, which crashed the parity suite with `document is not defined`.
  - `comboBoxBoxReset` and `comboBoxOptionLabel`. The label helper lives here to avoid an import cycle between the combo box and the pill.
- Generator (`scripts/generate-eui-styles.mjs`), `// combo box` block:
  - `combo_box.styles.js`: `euiComboBoxStyles`
  - `combo_box_input.styles.js`: `euiComboBoxInputStyles`
  - `combo_box_pill.styles.js`: `euiComboBoxPillStyles`
  - `combo_box_options_list.styles.js`: `euiComboBoxOptionListStyles`, `LIST_MAX_HEIGHT`
  - The generator now extracts 210 factories. `styles.generated.ts` and `upstream-sources.json` were regenerated. Worktree path comments were normalized to `node_modules/…`, and the worktree-only emotion/stylis source entries were dropped. The only other diffs are esbuild `_refN` renames.
- Parity (`scripts/eui-upstream-parity.test.mjs`):
  - The three function factories run through the 12-configuration matrix.
  - A static test covers `euiComboBoxStyles` and `LIST_MAX_HEIGHT`.
  - A group label hand-port test runs against upstream `lib/…/selectable_list.styles.js` in 12 configurations.
- `src/styles/ember-eui.css`: three rules were removed, and their behavior now lives in the components:
  - The `:root` `--ember-basic-dropdown-content-z-index: 99999` variable. It is now set on the panel element itself.
  - `.euiComboBox .euiComboBox__inputWrap { margin:0; list-style:none }`. The wrap is now a `<div>` with its own reset.
  - `.ember-power-select-visually-hidden`. It is now upstream `euiScreenReaderOnly`, nested in the panel class.
- `src/services/eui-config.ts`: the default `euiComboBoxOptionsHeight` changed from 33 to **29**, upstream's `rowHeight`.
- Tests:
  - New: `tests/integration/components/eui-combo-box-family-test.gts`, module `Borealis combo box family`, 17 tests.
  - Updated: `eui-combo-box-test.gts`. Its behavior coverage is all kept (see below).
- `docs/forms/combo-box/index.md`: only the generated API section was regenerated.

## API and default changes (latest-only)

- **The input wrap is a `<div>`** (upstream). It was a `<ul>` holding non-`li` children.
  - It keeps the `euiComboBox__inputWrap` and `ember-power-select-multiple-options` classes and its id.
  - It adds upstream's `euiComboBox__inputWrap--plainText` and `data-test-subj="comboBoxInput"`.
  - The legacy `--compressed`, `--fullWidth`, `--noWrap`, `--isLoading` and `-isClearable` wrap classes and the root `euiComboBox--compressed` / `--fullWidth` classes are removed. The root keeps `euiComboBox`, `-isDisabled`, `-isInvalid` and `-isOpen`.
- **Width:** the root takes the form width (`max-inline-size: 400px`, width 100%) unless `@fullWidth`. It used to stretch to its container.
- **The options list panel** is upstream EuiInputPopover. The old dead classes (`euiPanel--borderRadiusMedium`, `euiPopover__panel-isAttached`, `--bottom`, `-isOpen`, `-noArrow`, …) are gone.
  - It is a single Emotion class on ember-basic-dropdown's content, composing:
    - EuiPanel plain, radius m (the panel radius, 12px), padding s;
    - `euiPopoverPanelStyles`: the background variable, open state, `isAttached`;
    - the bottom shadow, or the top shadow when the content has `ember-basic-dropdown-content--above`;
    - the paragraph text color (the portal leaves the provider wrapper).
  - Classes: `euiPanel euiPanel--plain euiPopover__panel` + `@dropdownClass`.
  - The z-index stays 99999, now through `--ember-basic-dropdown-content-z-index` on the element, which works whatever stylesheet loads first. Its background uses the same variable mechanism.
  - Upstream computes the z-index per anchor (+2000). That is not ported.
- **The list** is the virtualized `div[role=listbox].euiComboBoxOptionsList.euiComboBoxOptionsList__rowWrap.euiComboBoxOptionsList__virtualization`:
  - max height 200px, y-scroll with overflow shadows;
  - `position: relative`, so keyboard scrolling offsets are relative to the list;
  - `data-combo-box-list=<uniqueId>` replaces the invalid `aria-controls="ember-power-select-trigger-…"`. `scrollTo` uses it.
- **Options** are upstream EuiListItemLayout rows, replacing `button.euiFilterSelectItem`:
  - Markup: `div.euiComboBoxOption.euiListItemLayout[role=option]` > `__content` > (indicator) + `span.euiListItemLayout__text.euiComboBoxOption__content` (truncated, `title` = `option.title` or the label while not searching) + `__append` with the hollow `returnKey` enter badge when focused.
  - States: focused (hover background), selected (`textPrimary` + select background), disabled (`textDisabled`, not-allowed). Interactive styles apply only while enabled.
  - **Options are no longer tab stops** (they had `tabindex="0"`). Focus stays in the input, as upstream.
  - New attributes: `id="<uniqueId>-<power-select index path>"`, `aria-setsize` and `aria-posinset`.
  - **Single selection** shows upstream's indicator: a `check` icon for the selected option and `empty` for the others.
  - **Multi selection** keeps selected options in the list, as Ember did. They get the selected styles and `aria-selected="true"`. Upstream removes them from the list instead.
- **Group labels:** `div.ember-power-select-group.euiComboBoxTitle[role=presentation]` > `span.ember-power-select-group-name`.
  - Styles are upstream xxxs titles with the divider above every group but the first. The first row is detected by index, because vertical-collection renders a spacer element before it.
  - Groups after the first are `rowHeight + 16` tall, as upstream's `getListItemSize`. With groups, vertical-collection uses `staticHeight=false`.
- **The input:**
  - It uses upstream's transparent borderless `euiComboBoxInput` styles.
  - It sizes to its content with `field-sizing: content` and fills the rest of the row. Upstream measures the text width instead.
  - **The placeholder is the input's native `placeholder`.** `p.euiComboBoxPlaceholder` is removed.
  - New on the input: `aria-activedescendant` (the highlighted option's id while open), `aria-label` / `aria-labelledby` / `aria-describedby`, and `aria-invalid` with `@isInvalid`.
  - The hidden validity input is now `aria-hidden` and gets `opacity: 0`. The old inline value `0px` was invalid CSS.
- **The layout:**
  - It gets `@isInvalid`, so upstream's warning icon shows.
  - The dropdown arrow (`arrowDown`, or `@triggerIcon`) is **hidden while disabled**, as upstream.
  - Multi selection gets `height: auto`.
  - The clear button and spinner are unchanged.
- **Pills:**
  - Upstream `euiComboBoxPill` styles: 22px tall, 20px line height, 1px block margin, `max-width: calc(100% - 18px)`.
  - **The default color is `hollow`** (upstream). It was EuiBadge's `default`.
  - New `data-test-subj="euiComboBoxPill"`.
  - The default remove label is the i18n token `euiComboBoxPill.removeSelection` ("Remove {label} from selection in this group"), used when the option has a text. `@iconOnClickAriaLabel` still wins.
  - New private `@searchField`.
  - Plain text selections (`span.euiComboBoxPill--plainText`) use the form control text and truncate.
- **Messages:** no matches, search and loading are upstream empty states: `div.euiComboBoxOptionsList` (padding s, centered, word break) > xs `EuiText.euiComboBoxOptionsList__empty`. `...attributes` (power-select's id and aria-label) moved to the wrapper div, and `Element` is now `HTMLDivElement` (it was EuiText's div). The default texts are unchanged ("No results found", "Type to search", "Loading options...").
- **Create option:** the upstream empty state (`__contentWrapper`, `__emptyStateText`, enter badge), plus `data-test-subj="comboBoxCreateOption"`. With `@alwaysShowCreateOption` it is a start-aligned interactive row with the "Create" badge. The badge is `aria-hidden` only when it is the icon badge.
- **A block is now optional:** without one, options render their label (a string, or `@searchField` / `label`) with **EuiHighlight on the search text** in the list, and plain labels in the pills. With a block, the caller renders the content, so there is no automatic highlighting, because ember-power-select yields only `(option, index)`.
- **`euiComboBoxOptionsHeight`** defaults to 29 (was 33).

## Existing test changes (`eui-combo-box-test.gts`)

- `OPTION`: `.euiComboBoxOptionsList button.euiFilterSelectItem` is now `.euiComboBoxOptionsList .euiComboBoxOption[role="option"]`. The rows changed element and class (see above). Every behavior assertion is unchanged.
- "prose list styles leave the input alone": the harness no longer injects the theme's `.euiComboBox .euiComboBox__inputWrap` padding/font rule. The wrap now carries its own upstream box and font, and is a `<div>`. The assertion is unchanged: same pill offsets inside and outside EuiText, and `list-style: none`.
- "options list stays above modals" and "announcement … for screen readers only" are unchanged. They now pass because of the component's own panel class, not the removed CSS rules.

## New coverage (`Borealis combo box family`, 17 tests)

- **Root:** position, form max width, fullWidth.
- **Wrap:**
  - Measured box: 40px, or 32px compressed.
  - Padding: 8/12, plus 60px or 36px of icon affordance at the end; compressed 4/4.
  - Gaps, `display: flex`, wrap vs nowrap (single), growth with rows of pills, the default inset border and the background.
  - Clear button label and the arrow.
- **Pills:** the hollow default compared with an EuiBadge, the option color, measured size/line height/margins/max width, i18n remove labels, removal by `mousedown`, disabled pills without remove buttons.
- **EuiComboBoxPill on its own:** the explicit label, `onClose`, a numeric option, plain text font and color.
- **Single selection:** a pill without remove, plain text alignment and cursor, the check/empty indicator, selected color and background, `aria-selected`, replacing the selection.
- **Input:** native placeholder, `aria-label`, upstream input styles (24px, borderless, transparent, font, color, placeholder color), filling the row, following the pill on the same row.
- **States:**
  - Invalid: 1px outline, `aria-invalid`, warning icon.
  - Open: 2px focus outline that wins over invalid.
  - Disabled: background, color, no arrow, no clear button.
  - All without element replacement.
- **Panel:**
  - Classes, width equal to the input, padding s, panel radius, popover background, paragraph color, z-index 99999, absolute position, opacity, shadow.
  - The status line is screen-reader only.
  - The list: max height 200 and auto overflow.
  - Opened above: the top attached shadow differs from the bottom one.
- **Options:**
  - Measured 29px rows, padding, control radius, color, cursor, font, truncation, `title`.
  - Focused background and the enter badge; selected and disabled states.
  - `aria-selected`, `aria-disabled`, `aria-setsize`, `aria-posinset`, and no tab stops.
  - `aria-activedescendant` following ArrowDown; Enter selects.
- **Groups:** presentation role, title color/weight/size, padding, 29px then 45px rows, divider color, index-path ids, posinset skipping groups.
- **Blockless:** labels, `mark.euiMark` highlight, no `title` while searching.
- **Messages:** no matches, search message, create option (layout, badge, Enter creates), always-show create (row, pointerup creates), loading spinner state resolving into rows.
- **Reactive args** (compressed, fullWidth, invalid) on the same root, wrap and pill.
- **Providers:** light/dark nearest provider, child inheritance, sibling isolation, the portaled panel in dark mode, JS-object `border.radius.control` overrides with the nearest one winning.
- **RTL:** logical paddings, icon side, pill start.
- **High contrast (preferred):** solid border, underlined focused option, panel border; standard contrast stays isolated.

## Checks run (2026-10-12, worktree `eui-wave/combo-box`)

Node 22.22.1, binaries run directly, Chromium 130 through the scratchpad shim, `CI=true`.

- Core (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **875 tests, 875 pass, 0 fail**.
- Filtered `combo` run (family, existing combo box, pill and form tests): 40/40.
- `node --test scripts/eui-upstream-parity.test.mjs`: **181/181**.
- `node scripts/generate-eui-styles.mjs --check`: "Stale generated artifact". This is the expected worktree failure (symlinked `node_modules` path comments). The coordinator should regenerate in the main checkout.
- `ember-tsc --noEmit`: pass. ESLint on every changed source and test: pass.
- `node scripts/generate-api-docs.mjs --check`:
  - The combo box page was regenerated and is current.
  - It still reports `docs/display/list-group/index.md` as out of date. That drift (`@externalIconClass` → `@externalIconCss`) predates this branch and belongs to the lists family, so it was left alone.
- Not run (coordinator): rollup core build, site build/acceptance, showcase/visual checks.

## Unresolved / for the coordinator

1. **EuiBadge has no `@css`.** The pill styles go in an extra class with doubled specificity (`&&`), so they win over the badge class whatever the insertion order. `EuiComboBoxPill.pillCss` holds the upstream slot, ready for `@css={{this.pillCss}}` once EuiBadge takes it.
2. **EuiText has no `@css`.** To keep a single Emotion class on EuiText, the empty state styles (padding, centering, word break) are composed on the wrapping `div.euiComboBoxOptionsList`, and the EuiText gets only the plain `euiComboBoxOptionsList__empty` class. The visual result is the same.
3. **Selectable family overlap:** `euiSelectableListGroupLabelStyles` is hand-ported in `utils/eui/combo-box.ts`. If the selectable agent extracts or ports it too, keep one copy. Do not add `selectable_list.styles.js` to the generator: it pulls in `@emotion/css`.
4. **Icon names:** `arrowDown` and `returnKey` are used instead of upstream's `chevronSingleDown` and `return`, which are not in the bundled set. Switch them with the icon refresh.
5. **Not ported:**
   - Upstream's per-anchor z-index.
   - `onFocusBadge`, `truncationProps` / `EuiTextTruncate` middle truncation and `rowHeight="auto"`.
   - `delimiter`, prepend/append for single selection, option `prepend`/`append`/`toolTipContent`.
   - The "already added" / "all options selected" / "no available options" messages.
   - Marking the combo box invalid after a blur with leftover text.
   - The focus-time screen reader "removeOptionMessage".
   - The clickable chevron button: the arrow stays decorative, and clicking it opens the list through the trigger.
6. **`field-sizing: content`** is Chromium and Safari only. Firefox falls back to the input's default width before the flex grow, so the input may wrap below the pills earlier there.
7. **Removing the global `:root` dropdown z-index** from `ember-eui.css` also affects any app-owned ember-basic-dropdowns that relied on it. Only the combo box uses ember-basic-dropdown in core.

## Next step

Coordinator: merge, then regenerate `styles.generated.ts` and `upstream-sources.json` in the main checkout. Switch the pill to EuiBadge `@css` when it exists. Then run the core build and site checks, and look at the combo box docs demos visually: pill colors, panel width and the list.

## Upstream gaps closed (2026-10-13, branch `eui-wave/combo-box`)

All gaps from the docs audit exist in EUI 123.1.0 and are now ported; the
EuiComboBox row is gone from `docs-audit-gaps.md`.

Files: `eui-combo-box.gts`, `eui-combo-box-pill.gts`,
`eui-combo-box/{options,trigger,trigger/input,create-option,group}.gts`,
new private `eui-combo-box/node.gts` (text-or-component renderer) and
`eui-combo-box/option-text.gts` (upstream `renderTruncatedOption` /
`renderVariableHeightOption`), matching helpers ported from
`matching_options.ts` / `utils.tsx` into `utils/eui/combo-box.ts`. No
generator changes: `hasRowHeightAuto`, `inGroup`, `euiListItemLayout__prepend`
and `textWrap.wrap` were already generated.

API (all additive):
- Option keys `prepend` / `append` (text or a component, gets `@option`) in
  rows (EuiListItemLayout prepend/append), pills (`euiComboBoxPill__*`, text
  in `.eui-textTruncate`), plain text selection
  (`euiComboBoxPlainTextSelection__*`) and group titles.
- Option `toolTipContent` / `toolTipProps` (position, delay, title, offset,
  className, css, anchorClassName): EuiToolTip inside the row, full-width
  anchor, `aria-describedby` on the option, shown on hover and while the
  option is highlighted; none on disabled options; no text `title` then.
- `@truncationProps` + option `truncationProps` (merged, option wins) →
  EuiTextTruncate; while searching `startEnd` around the match with
  EuiHighlight (`strict` = `@isCaseSensitive`) or EuiMark when shorter.
  Width shared across rows like upstream (`optionWidth`).
- `@rowHeight="auto"`: VerticalCollection `@renderAll`, no row heights,
  `textWrap.wrap`, `hasRowHeightAuto` list styles, highlight only.
- `@delimiter`: typing it adds the text before it; Enter (no highlighted
  match) and the "add" row add each value (split, trimmed, unique); the
  empty state says "Add each item separated by ,".
- `@isCaseSensitive`: upstream partial matcher (trimmed, case-sensitive);
  `@sortMatchesBy="startsWith"`: options reordered per search (within groups).
- `@noSuggestions`: list never opens (`onOpen` returns false), no chevron,
  Enter calls `@onCreateOption`.
- `@prepend` / `@append` (single selection only, like upstream): one string →
  EuiFormPrepend/Append label for the input; components / arrays rendered
  in the layout's side nodes; `inGroup` wrap styles.
- Default block yields a third value, the raw search text (`''` in pills),
  so blocks can use EuiHighlight like `renderOption`.
- `@onCreateOption(value, flattenedOptions)` (2nd arg new); text equal to a
  selected label is not created again; text equal to the only matching
  option selects it (upstream `addCustomOption`). `@customOptionText` also
  takes upstream's `{searchValue}` (bold).

Ember differences kept (documented on the page): default matching still
ignores case and accents (power-select); selected options stay listed;
creating on blur only with `@noSuggestions` or `@delimiter`; adding still
closes the list (except when typing the delimiter / on blur); the first
match is highlighted on open, so its tooltip shows then too; group
`sortMatchesBy` sorts within groups (upstream sorts its flat list).

Bug found while porting: deriving `@options` from `select` (replaced on
every highlight) re-ran power-select's options modifier, which resets the
highlight → infinite loop. The search text is now copied to a tracked
`searchValue` only when it changes.

Docs: demos renumbered to upstream's order; new Tooltips, Truncation,
Multiple lines, Single selection with prepended label, With delimiter,
Case-sensitive matching, Sorting matches; Option rendering uses
`prepend`/`append`; Custom dropdown content highlights with the yielded
search value; Custom options only uses `@noSuggestions` (no adaptation
note); single selection custom text uses `{searchValue}`. API tables
regenerated (the generator also re-adds `@initialFocus` to
`layout/modal/index.md` from main's source; left out of this branch).

Checks: core suite 1315/1315 (1302 + 13 new in
`eui-combo-box-upstream-props-test.gts`; existing combo tests unmodified),
ember-tsc clean, eslint clean on changed files, parity 349/349, rollup
refreshed package.json app-js (2 new private files).

## Upstream behavior by default (2026-10-13, branch `eui-wave/combo-upstream`)

User decision: "make combo box match upstream behavior, but we can't
support regressions". Coordinator constraint: no copy of the options and
no mutation; the list is derived from args on every change.

### How it works now

`EuiComboBox` still uses ember-power-select, but owns the list:
`powerSelectOptions` is a `@cached` getter over `@options` (or what a
promised `@options` resolved to), `@selectedOptions` and the tracked
search text, through a port of upstream `getMatchingOptions`
(`getMatchingEntries` + `entriesToPowerSelectOptions` in
`utils/eui/combo-box.ts`). ember-power-select gets `@matcher` = match-all
so it never filters again. Tracked state is UI only: `select` (open,
highlight), `searchValue`, `hasFocus` / `inputHasFocus`, and the settled
value of a promised `@options`. `@search` results go through the same
matching (pre-filtered, selected removed). Groups are copied (new
`options` arrays); options and the caller's arrays never are (frozen
arrays tested).

### Behavior changes (each checked against upstream 123.1.0 source)

1. **Matching** (`matching_options.ts`): case-insensitive substring on the
   trimmed label and search; no accent folding. `@isCaseSensitive`;
   `@matcher` kept; new upstream `@optionMatcher`.
2. **Selected options** are left out of the list in multiple selection
   (label + `key` equality, case per `@isCaseSensitive`, like
   `getSelectedOptionForSearchValue`); single selection keeps them
   (`showPrevSelected`) with the check by label + key; choosing the
   selected option again keeps it (`onAddOption`).
3. **Blur** (`onContainerBlur`): leaving with no highlighted option runs
   `setCustomOptions(true)` for any combo box: the only exact match is
   selected, else `@onCreateOption` (delimiter split). Text not added
   stays and marks the combo box invalid (`markAsInvalid`); the trigger no
   longer clears the search on close.
4. **Adding**: multiple selection keeps the list open (choice, Enter,
   custom option) and highlights the next option; single selection closes.
   `@closeOnSelect` defaults to `!!singleSelection`. Enter without a
   highlighted option adds the text even if it partially matches.
5. **Highlight**: nothing on open (`activeOptionIndex = -1`); single
   selection opened by click highlights its option (`onComboBoxClick`);
   tooltips show only on hover / arrows; `@highlightOnHover` off.
6. **`sortMatchesBy="startsWith"`** sorts the flat list, group titles
   included, and options follow the title before them.

Other differences found and fixed: arrows wrap and ArrowUp starts at the
end, skipping disabled options and groups; Escape closes and keeps text;
Tab is prevented while an option is highlighted; Backspace in an empty
input removes the last pill without opening the list (single selection
reopens; `asPlainText` also deletes one character); focusing the input
opens the list; the clear button focuses the input and opens the list;
no placeholder while searching; upstream empty states ("{searchValue}
doesn't match any options", "There aren't any options available",
"You've selected all available options", "{label} has already been
added"); `@isLoading` shows the spinner in the list; enter badge only
with new `@onFocusBadge`; upstream `{ label, options }` groups; new
`@async` and `@onSearchChange(value, hasMatchingOptions)`. Accessibility:
the input is the combobox (`role`, `aria-expanded`, `aria-controls` while
open, `aria-haspopup`, `aria-autocomplete`, `aria-required`, label);
power-select's trigger is `role="presentation"`, `tabindex="-1"`, no
label (with `@searchEnabled={{false}}` it stays power-select's combobox);
listbox `aria-label` "Choose from the following options" and
`aria-multiselectable` only for multiple selection; mousedown in the list
keeps focus in the input; screen reader instructions (polite live region)
while the input has focus.

### Changed existing assertions (old → new, upstream reference)

`eui-combo-box-test.gts`:
- "external options and selection replacements…": `['Cherry','Date']` →
  `['Date']` (selected not listed; `collectMatchingOption`).
- "selecting an already selected option removes it" → renamed "selected
  options are not listed, so they cannot be chosen again": `choose('Apple')`
  + changes `[['Banana']]` → list is `['Cherry']`, changes `[]` (same).

`eui-combo-box-family-test.gts`:
- single selection: Banana background `backgroundBaseInteractiveSelect` →
  `…SelectHover` (opened by click, selected option highlighted;
  `onComboBoxClick`).
- options: 4 rows → 3 (Cherry selected, not listed); "first option
  highlighted on open" (hover background, enter badge) → not focused, no
  badge without `@onFocusBadge` (`activeOptionIndex -1`, `onFocusBadge`);
  Cherry selected-style/`aria-selected` assertions removed (not listed);
  setsize 4 → 3, Durian posinset 4 → 3; `aria-activedescendant` on open
  = Apple → absent, one extra ArrowDown before the existing ones.
- without a block: `['Banana','Ananas','Cherry']` → `['Banana','Ananas']`.
- messages: "No results found" → "zzz doesn't match any options"
  (`euiComboBoxOptionsList.noMatchingOptions`).
- provider: `rows()[0]` color textPrimary ("selected") → textParagraph
  (selected Apple not listed).
- high contrast: ArrowDown added before the underline check (no
  highlight on open).

`eui-combo-box-upstream-props-test.gts`:
- prepend/append: `state.selected = []` before opening (selected options
  are not listed).
- tooltips: "shown when the list opens" → absent on open, shown after
  ArrowDown (`activeOptionIndex -1`).

No other test edits.

### New tests

- Core `eui-combo-box-upstream-behavior-test.gts` (35): ports of
  `combo_box.test.tsx`, `matching_options.test.ts` and the spec's keyboard
  cases, plus: replacing `@options` while open / after a selection / with
  equal new objects / while searching, a promised `@options` replaced by
  an array, `@search` results without the selection, frozen
  `@options` / `@selectedOptions` (flat and grouped) never mutated.
- validated-form: forwarding test and "selected options leave the list,
  leaving adds the typed text, validity follows".
- changeset-form: forwarding test and "leaving with typed text adds it,
  and validates after it is added".

### Companion packages

Both `FieldComboBox`es forward every `EuiComboBox` arg (option keys are
data), yield `(option, index, searchValue)`, pass `@ariaLabel` as the arg
(it was an attribute on the wrapper), honor `@autofocus` / `@autoFocus`,
and render blockless when called without a block (they always passed a
block, so blockless options rendered empty). changeset-form validates
again after `@onCreateOption` (blur validated before the created value
landed); its `singleSelection` type (`isPlainText`) was dropped for
EuiComboBox's. flatpickr and pikaday don't use EuiComboBox.

### Docs

Combo box page: differences reduced to what is left (below); d15 uses
`@onSearchChange`, d17 mirrors upstream's `@async` demo, d21 uses
`@optionMatcher`; d24 "Keeping the list open" (manual remaining-options
workaround + `@closeOnSelect={{false}}`) removed. Companion docs note the
new behavior. Release note: `.changeset/combo-box-upstream-behavior.md`
(core major, forms minor) and 13 `EuiComboBox` rows in
`docs/migrating-to-borealis.md` (+ Known gaps updated). Note: the pending
major changesets make the next release 15.0.0, not 16.0.0.

### Remaining differences

- `asPlainText` selection is shown next to the input, not as its value.
- The chevron is decorative (no `comboBoxToggleListButton`); no
  `comboBoxClearButton` test subject (EuiFormControlLayout owns it).
- With `startsWith` and groups, a title left without options isn't
  rendered (ember-power-select drops empty groups).
- Typing keeps the highlighted option if it still matches (upstream keeps
  the index).
- `@search` results are filtered when they arrive (selection changes
  while they are shown don't re-filter them).
- `inputPopoverProps`, `inputRef`, option ids by original index.

### Checks

- Core full suite 1368/1368 (1333 + 35 new), filtered `combo` 88/88.
- validated-form 25/25 (before 23/23), changeset-form 24/24 (before
  22/22). Note: the companions' `node_modules` symlink resolves
  `@ember-eui/core` to the MAIN checkout's `packages/core`, not the
  worktree or the injected copy, so the "before" counts (and any run with
  the brief's recipe) test main's core dist. The "after" counts were
  measured with a temporary worktree-local `node_modules` pointing
  `@ember-eui/core` at the worktree core (restored afterwards).
- ember-tsc (core, validated-form, changeset-form), eslint on changed
  files, parity 349/349, rollup (no package.json change),
  `generate-api-docs` (combo page regenerated).
