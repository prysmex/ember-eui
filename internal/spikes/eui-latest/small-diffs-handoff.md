# Small upstream differences handoff

Branch `eui-wave/small-diffs` (from `feat/eui-latest` at `31a03729`).
Target EUI 123.1.0. Every item was checked against upstream's source in
`upstream-docs/eui/packages/eui/src/components/`.

## What changed

### 1. EuiPageTemplate (page-template-handoff.md)

- **`T.BottomBar` ends up at the end of `<main>` wherever it is placed.**
  Upstream portals the bar (`createPortal`) into the element found by
  `#pageInnerId`, after a `requestAnimationFrame`.
  - Mechanism: `{{#in-element}}`, Ember's portal, with
    `insertBefore=null`. The template records its rendered main element
    (a function modifier sets a tracked `mainElement`) and curries it
    into `T.BottomBar` as the private `@parent`. Until the element is
    known, the bar renders in place, as upstream's does before its frame.
  - Why not a registration or a `<:bottomBar>` slot: a block can't be
    moved to another place in the template, so a registration can only
    count bars (like the sidebar), not render their content elsewhere. A
    slot would only work when the consumer uses it, not "wherever it's
    placed". `{{#in-element}}` moves nothing by hand: Glimmer creates,
    updates and removes the bar's nodes in the main element itself.
  - Content rendered later (`{{#if}}` sections) is inserted before the
    bar, because Glimmer inserts at its block's position. Several bars
    keep their order; a bar rendered later is appended.
- **Responsive stacking stays on CSS media queries.** They give the same
  result as upstream's `useIsWithinBreakpoints`. The new test checks
  every subset of `xs…xl` (32) at every breakpoint −1/0/+1 px, plus 1px
  and 2000px, for the Borealis breakpoints and a custom
  `modify.breakpoint` theme: 896 cases. It sizes an iframe, evaluates
  `euiBreakpointsMedia` / `euiOutsideBreakpointsMedia` with
  `matchMedia`, and compares with upstream's algorithm (largest
  breakpoint ≤ `innerWidth`) on the same `innerWidth`. No mismatch. The
  one difference is timing: CSS applies on the first render, while
  upstream re-renders after its provider's state settles and throttles
  resizes by 50ms. Documented on the page template page.

### 2. EuiSelectable (selectable-handoff.md)

- Upstream `onFocus`: focusing the search only sets `isFocused`. Focus
  on another element that isn't the search or the list does nothing.
  Focus on the list still makes the first checked (or first) option
  current.
- Upstream `onKeyDown` default branch: any other key (e.g. ArrowLeft)
  resets the current option and calls `onFocus()` again, which picks the
  first checked option. Before, it only reset it. Searches already
  re-picked while focused.

### 3. EuiSuperDatePicker (super-date-picker-handoff.md)

- Time zone display:
  - the label is `EuiText @component="span"`;
  - the padding comes from the extracted `euiTimeZoneDisplayStyles`
    factory, which is new in the generator and in the parity matrix;
  - both tabs' inputs always have `aria-describedby` pointing at the
    display id, even when no display renders (upstream).
- **New `EuiText @component`** (upstream `component`): a tag name. It is
  typed as `'div'` so callers keep `HTMLDivElement` attributes.
- `EuiDatePickerRange @inline`: the new `@showTimeSelect` picks
  `responsiveWithTimeSelect` (374px calendars). Upstream reads
  `showTimeSelect` from its controls; blocks can't be inspected, so the
  consumer passes it. Upstream's "Show time select" toggle is back in
  demo d02 (flatpickr `@enableTime`).
- Date buttons: the `title` attribute became upstream's `EuiToolTip`:
  - `display="block"`, with the `tooltipAnchor` css as `@anchorCss`;
  - `disableScreenReaderOutput` unless the date is invalid or needs an
    update.
  The `<:button>` block is unchanged.
- Delimiter: the `EuiFormControlLayoutDelimited` default is upstream's
  `<EuiIcon type="sortRight" aria-label="to">`
  (`euiFormControlLayoutDelimited.delimiterLabel`). It replaces the `→`
  text in every delimited field (date ranges, super date picker, dual
  range). `@delimiter` (even `''`) and the `<:delimiter>` block still
  win.
- Pretty duration stays opt-in (`@showPrettyDuration`), unchanged.

### 4. EuiSelectableTemplateSitewide (sitewide-handoff.md)

- New `@css`, composed after the root styles. `@isPreFiltered` takes
  EuiSelectable's type, `{ highlightSearch }` included. Every other
  EuiSelectable arg was already forwarded.
- `searchProps` (through EuiSelectable → EuiSelectableSearch) now
  forwards EuiFieldSearch's `fullWidth`, `incremental`, `disabled`,
  `isDisabled`, `readOnly`, `isInvalid` and `id`. Any other key with a
  scalar value becomes an attribute of the `<input>`, through the private
  `spread-attributes` modifier (upstream's `...rest`). Functions and
  objects are skipped. `aria-describedby` is excluded, because upstream
  merges it with the message id (`getAccessibleName`), which is not
  ported.

### 5. EuiImage (gaps-display-handoff.md), breaking

- `...attributes` go on the `<img>` and on the full screen `<img>`
  (upstream `commonImgProps`), not on the `<figure>`. `Element` is now
  `HTMLImageElement`.
- `@wrapperProps` spreads its other keys as attributes of the figure.

### 6. EuiTreeView

- New `<:icon as |node isExpanded|>` block, rendered in the icon wrapper
  of each node that has `icon` / `iconWhenExpanded` (upstream's per-node
  icon element). Nested levels use it too, through a private
  `@hasIconBlock`. Component icons per node still work.

### 7. EuiCard

- `betaBadgeProps.anchorProps` go on the badge wrapper span:
  - `className` and `css`, composed after `euiCard__betaBadgeAnchor`;
  - any other key as an attribute.

### 8. Other rest spreads

- **`EuiTabbedContent`**: the other keys of a tab object become
  attributes of its `EuiTab` (upstream `{ id, name, content,
  ...tabProps }`). The date popover tabs now carry upstream's
  `superDatePicker{Absolute,Relative,Now}Tab` test subjects and
  `"Start date: Absolute"`-style `aria-label`s (date-pickers-handoff:
  "per-tab attributes not set").
- Not done, as not small or owned elsewhere:
  - EuiBadge `iconOnClick` rest onto the child button (the combo box
    pill depends on the root, and the combo box belongs to another
    agent);
  - EuiSelectable's `getAccessibleName` (root `aria-label` /
    `aria-describedby` moved to the search and the listbox);
  - `listProps['aria-label']`;
  - list group tooltips;
  - EuiListGroup `listItems`.

## Deliberate behaviour changes (old → new, upstream reference)

| # | Change | Old | New | Upstream |
| --- | --- | --- | --- | --- |
| 1 | `T.BottomBar` position | In place | End of `<main>` | `page_template/bottom_bar/page_bottom_bar.tsx` (`createPortal`) |
| 2 | Focusing EuiSelectable's search | The first checked or first option became current | Nothing current | `selectable.tsx` `onFocus` (`searchable && target === inputRef`) |
| 3 | Other keys in EuiSelectable | Reset only | Reset, then pick the first checked option | `selectable.tsx` `onKeyDown` default branch |
| 4 | EuiImage attributes | `<figure>` | `<img>` (both) | `image.tsx` `...rest` in `commonImgProps` |
| 5 | Date button title | `title` attribute | EuiToolTip | `date_popover_button.tsx` |
| 6 | Time zone label | `div` | `span` | `timezone_display.tsx` |
| 7 | Time zone `aria-describedby` | Only while shown | Always | `absolute_tab.tsx` `describedByIds`, `relative_tab.tsx` |
| 8 | Delimiter | `→` text | `sortRight` icon, `aria-label="to"` | `form_control_layout_delimited.tsx` `EuiFormControlDelimiter` |
| 9 | Unknown `searchProps` / tab / `wrapperProps` / `anchorProps` keys | Ignored | Attributes | upstream `...rest` spreads |

All of them are in `.changeset/borealis-migration.md` (one bullet) and in
the "Changed defaults and behaviors" tables of
`docs/migrating-to-borealis.md` (Layout, Display, Forms).

## Existing tests changed (assertions only where the behaviour changed)

- `eui-selectable-family-test` keyboard test:
  - after `focus(input)`, it asserts that nothing is current and that
    there is no `aria-activedescendant`;
  - one more ArrowDown reaches Banana: the first arrow now lands on
    Apple. Before, focus made Apple current and the arrow moved to
    Banana.
- `eui-super-date-picker-test` ("it renders", "follows changes",
  "selection is kept"): `hasAttribute('title', X)` became `hasText(X)`.
  The button's text is the date the title repeated.
- `eui-date-pickers-test`:
  - end button `title 'now'` became `hasText('now')` and no `title`;
  - the invalid and needs-updating title assertions became "no `title`
    attribute". The texts are now covered by the tooltip test in
    `eui-super-date-picker-upstream-props-test`;
  - delimiter `hasText('→')` became the `sortRight` svg with
    `aria-label="to"`.
- The same delimiter assertion changed in `eui-form-control-layout-test`,
  `eui-date-picker-range-test` and `eui-form-controls-test`.
- `eui-super-date-picker-upstream-props-test`: "no zone" now expects
  `aria-describedby` pointing at a missing id. Before, there was no
  attribute.
- `eui-super-date-picker-pretty-duration-test` ("Click to apply" for 2s,
  and `showTooltip: false`):
  - the focus returns to the start button, which now has its own
    tooltip;
  - so the assertions look for the "Click to apply" tooltip by text,
    instead of "the only `[role=tooltip]`".
- `eui-utilities-test` EuiImage test: setup only. The `data-small`… hooks
  moved into `@wrapperProps` so they stay on the figure. The assertions
  are unchanged.

## New tests

- `eui-page-template-composable-test`, 3 tests:
  - the bar is last although placed first, later content goes above it,
    and it updates in place;
  - several bars and a conditional bar;
  - the media query ≡ `useIsWithinBreakpoints` matrix.
- `eui-super-date-picker-upstream-props-test`, 2 tests:
  - time zone span, padding and describedby;
  - date button tooltip: no title, block anchor, hover text, screen
    reader output only when invalid.
- `eui-upstream-small-diffs-test.gts` (new), 15 tests:
  - EuiText `@component`;
  - delimiter icon / `@delimiter` / `''`;
  - `@showTimeSelect` stacking at 700px;
  - selectable search focus, other keys and search;
  - list focus;
  - `searchProps` args and attributes, `disabled`;
  - sitewide `@css` and attributes;
  - EuiImage attributes and `wrapperProps`;
  - tree view `<:icon>` with and without the block;
  - card `anchorProps`;
  - tabbed content tab attributes;
  - date popover tab subjects and labels.

## Docs

- Page template: index (Ember differences) and d03.
- Date picker range: d02 has upstream's "Show time select" toggle back.
- Image index: where attributes go.
- Tree view: `<:icon>`.
- Selectable: d02 `searchProps`.
- API tables regenerated (7 pages: image, text, tree view, date picker
  range, delimited layout, selectable, sitewide, card).
- `docs-audit-gaps.md` had no rows for these items, so it is unchanged.

## Checks (worktree, Chromium 130, CI=true)

- Filtered runs while iterating: 375/375 (page template, date, delimited,
  forms, utilities, selectable, tabs, small differences).
- Full core suite: **1806/1806**.
- Companions (temporary worktree-local `node_modules` pointing `@ember-eui/core` at this worktree, restored): validated-form **25/25**, changeset-form **24/24**.
- `node --test scripts/eui-upstream-parity.test.mjs`: 357/357, the new
  factory included.
- `generate-eui-styles --check`: clean.
- ESLint on changed files: clean.
- `ember-tsc --noEmit`: one error, in
  `src/utils/markdown/plugins/markdown-default-plugins/parsing-plugins.ts`
  (`Emoji` plugin type). That file is untouched here, and the shared
  `node_modules` is outside this branch. The same error makes `rollup`
  exit non-zero, but `dist` is emitted. No new source files, so
  `package.json` is unchanged.

## For the coordinator

- The flatpickr `@enableTime` toggle in date picker range d02 is not
  verified in a site build. If EuiFlatpickr doesn't re-initialize when
  `@enableTime` changes, key the calendars on the switch.
- The `Known gaps` section of `docs/migrating-to-borealis.md` still
  lists super date picker / selectable items that earlier waves closed.
  This branch didn't touch them.
