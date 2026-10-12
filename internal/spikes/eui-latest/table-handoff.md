# Table family migration handoff (EuiTable and its parts, EuiTablePagination, mobile sort)

Status: **Migrated**. Full core suite 973/973 in Chromium 130 (12 new `Borealis table family` tests), parity 242/242, types, lint and API docs pass.

## Files

- Components (`packages/core/src/components/`). Each one that computes styles is a Glimmer class with `@cached` getters, and reads factories only through `useEuiBorealisStyles`:
  - `eui-table.gts`, `eui-table-row.gts`, `eui-table-row-cell.gts`
  - `eui-table-row-cell-checkbox.gts`
  - `eui-table-header-cell.gts`, `eui-table-header-cell-checkbox.gts`, `eui-table-header-button.gts`
  - `eui-table-header-mobile.gts`
  - `eui-table-footer-cell.gts`
  - `eui-table-pagination.gts`, `eui-table-sort-mobile.gts`
  - Unchanged because upstream has no styles for them: `eui-table-header.gts`, `eui-table-body.gts`, `eui-table-footer.gts`, `eui-table-sort-mobile-item.gts`.
- `src/-private/table.ts` (rewritten) holds:
  - the table context (`EUI_TABLE_CONTEXT`, which carries `isResponsive` and `hasBackground`; it is upstream's `EuiTableIsResponsiveContext` and `EuiTableVariantContext`)
  - the breakpoint helpers `minBreakpointQuery`, `isTableResponsive` and the `onMediaQueryChange` modifier
  - `widthStyle` (`width`/`minWidth`/`maxWidth`)
  - the scoped resets `CELL_RESET`, `TABLE_RESET` and `buttonReset`
  - `cellContentStyles`, upstream's `EuiTableCellContent` style composition
  - `alignClasses` was removed (it emitted legacy classes).
- `scripts/generate-eui-styles.mjs` and `scripts/eui-upstream-parity.test.mjs` have a new `// table` block. `styles.generated.ts` and `upstream-sources.json` were regenerated (283 factories). The worktree-only `../../…/Users/…` source-path comments were normalized back to `node_modules/…`; regenerating and normalizing gives byte-identical files (`cmp`).
- Tests:
  - New: `tests/integration/components/eui-table-family-test.gts` (12 tests).
  - Updated: `eui-table-test.gts` (see below).
- Docs: the API section of `docs/tabular/table/index.md` was regenerated.

## Generator entries added (`// table`)

- `components/table/table.styles.js`: `euiTableVariables`, `euiTableStyles`, `euiTableCaptionStyles`
- `components/table/table_cells_shared.styles.js`: `euiTableHeaderFooterCellStyles`, `euiTableCellCheckboxStyles`
- `components/table/_table_cell_content.styles.js`: `euiTableCellContentStyles`
- `components/table/table_row.styles.js`: `euiTableRowStyles`
- `components/table/table_row_cell.styles.js`: `euiTableRowCellStyles`
- `components/table/mobile/table_header_mobile.styles.js`: `euiTableHeaderMobileStyles`
- `components/table/const.js`: `EUI_TABLE_CSS_CONTAINER_NAME`
- `global_styling/mixins/_container_query.js`: `euiContainerCSS`

All of them extracted cleanly (no hand port). Parity coverage:

- Every theme factory is in the `factories` 12-configuration matrix.
- A new test, "table static slots and container helper match upstream", checks the caption styles, the container name and `euiContainerCSS`.

Not extracted: upstream's sticky-cell styles. `euiTableStickyCellStyles` is not exported and is only reached through a hook.

## API and default changes (latest-only)

### Responsiveness (EuiTable, rows, cells, EuiTableHeaderMobile)

- **The cards layout is driven by JS, like upstream, instead of legacy CSS.**
  - Below the theme's `m` breakpoint (`min-width` query on `euiTheme.breakpoint.m`, so `@borealisOverrides` breakpoints apply), the table renders upstream's mobile styles: `thead`/`tfoot` hidden and rows as flex cards.
  - Rows and cells read this from the table context.
  - A `matchMedia` change listener (on the table wrapper) only fires when the breakpoint is crossed. Upstream uses a throttled resize listener in its provider instead.
  - Without a window (FastBoot) the table renders as a table. Upstream renders cards there.
- **New `@responsiveBreakpoint`** (upstream): a named breakpoint, `true` (always cards) or `false` (never).
  - The existing `@responsive` is kept (default `true`); `@responsive={{false}}` is the same as `@responsiveBreakpoint={{false}}`.
  - When both are given, `@responsiveBreakpoint` wins.
  - Note that upstream's `true` means "always cards", while Ember's `@responsive={{true}}` keeps its old meaning ("collapse at the breakpoint").
- What is rendered now depends on the layout, as upstream:
  - The mobile header `div.euiTableRowCell__mobileHeader` and the `<:mobile>` block render only in cards. Before, both versions were always rendered and hidden with legacy classes.
  - `mobileOptions.show: false` cells are not rendered in cards, and `only: true` cells are not rendered on desktop.
  - Header cells follow the same rules.
- **EuiTableHeaderMobile renders nothing outside the cards layout** (upstream). It takes its own `@responsiveBreakpoint` (default `'m'`). While hidden, it leaves an empty `<span hidden>` that holds the breakpoint listener.
- `TableMobileOptions` gains `textOnly`, `width`, `minWidth` and `maxWidth` (upstream).
  - In cards, cells default to left alignment unless `mobileOptions.align` is set.
  - In cards, cells use the mobile widths, and actions/expander cells get no width.

### EuiTable

- Like upstream, the table is wrapped in a new `div.euiTable__wrapper`, which carries the container CSS: `container-name: EuiTable` and `container-type: normal scroll-state`. Chromium 130 ignores the `scroll-state` type. `...attributes` stay on the `<table>`.
- **New `@hasBackground`** (default `true`, upstream): the table gets the `backgroundBasePlain` background. With `false`, the footer has no background, and cards get a border instead of a shadow.
- **New `@scrollableInline`** (upstream beta).
- `@compressed` is ignored in the cards layout (upstream).
- Removed classes: `euiTable--compressed`, `--auto`, `--responsive`.
- Not ported: `stickyHeader` and `stickyScrollbar`. They need upstream's column store, a cloned header and a sticky scrollbar.

### EuiTableRow

- Upstream colors:
  - hover: `tableRowBackgroundHover`
  - clickable: hover, pointer and focus colors
  - selected, including the expanded row that follows it
  - expanded: background and enter animation
  - cards: shadow (or border), radius, margin, and left/right columns
- **New `@hasSelection`** (upstream). It defaults to `@isSelectable`, so existing selectable rows get the cards' checkbox column.
- `@hasActions` also accepts `'custom'`.
- **The row is now a single `<tr>` whether or not `@onClick` is set.** Before, toggling `@onClick` replaced the element. Click/Enter/Space behavior and `tabindex="0"` are unchanged.
- Upstream state classes kept: `euiTableRow-isSelected`, `-isSelectable`, `-hasActions`, `-isExpandedRow`, `-isExpandable`, `-isClickable`.

### EuiTableRowCell

- Upstream cell styles:
  - `textParagraph` color and thin top/bottom borders
  - row header (`th`): regular weight, start alignment
  - `valign`, which adds **`baseline`**
  - actions/expander `line-height: 1`
  - cards: min width 50%, `enlarge` (font size m), actions/expander in the right column, custom actions on their own line
- Content (`.euiTableCellContent`):
  - Padding comes from the table (s; xs when compressed).
  - Alignment uses flex plus logical `text-align`.
  - `@truncateText` truncates. **Otherwise long words break (`euiTextBreakWord`)**, which is upstream's default.
  - Action cells get gaps and layouts.
- `@textOnly={{false}}` renders the content without the text span (upstream).
- **New `@minWidth` and `@maxWidth`.** `@hasActions` accepts `'custom'`.
- **`@showOnHover` now uses upstream's `euiBasicTableAction-showOnHover` mechanism:**
  - The content is hidden (opacity 0, with a transition) until the row is hovered or the cell has focus.
  - It is always visible in cards.
  - Ember extension: it also reveals on rows without `@hasActions`.
- Removed classes: `euiTableRowCell--middle/--top/--bottom`, `--hideForDesktop`, `--hideForMobile`, `--enlargeForMobile`, and `euiTableCellContent--alignRight/--alignCenter/--truncateText/--overflowingContent/--showOnHover`. `euiTableCellContent__hoverItem` became `euiBasicTableAction-showOnHover`.
- Kept classes: `euiTableRowCell--hasActions` and `--isExpander` (both upstream).

### EuiTableHeaderCell

- Upstream styles: xs semibold `textHeading`, middle alignment, `xs` gap.
- The sort button:
  - Full width, with a scoped button reset.
  - On hover and focus it turns `textPrimary` and underlined.
- **A subdued `sortable` icon (`euiTableSortIcon--sortable`, `tableCellSortableIconColor`) appears on sortable columns that are not sorted** (upstream).
- **`aria-sort` follows upstream:**
  - sorted: `ascending`/`descending`
  - sortable: `none`
  - otherwise no attribute
  - Change: a `@readOnly` column that is not sorted no longer gets `none`.
- `aria-live="polite"` on sortable headers is kept from Ember (upstream has none).
- The text span is upstream's `eui-textTruncate` (was `euiTableCellContent__text`), with the same title/description behavior. Hidden-cell rules follow `mobileOptions`.
- New `@minWidth` and `@maxWidth`.
- Not ported: `tooltipProps`, `append`, `sticky`.

### Checkbox cells

- Header: upstream width `size.xl` (32px) by default, start alignment, middle vertical alignment. New `@minWidth`/`@maxWidth`.
- Row: thin top/bottom borders on desktop. In cards the checkbox is absolutely positioned at `top: s` and `inset-inline-start: s/2`.

### EuiTableFooterCell

- Upstream semibold xs `textHeading`, with the `tableFooterBackground` background when the table has a background.
- The content always truncates (upstream).
- New `@minWidth`/`@maxWidth`.

### EuiTableHeaderButton

- Removed upstream. It is kept, and styled with the header sort button slots plus an inline-flex layout and a truncated label.

### EuiTablePagination

- **Defaults are now upstream's:**
  - `@itemsPerPage` **10** (was 50)
  - `@itemsPerPageOptions` **[10, 25, 50]** (was [10, 20, 50, 100])
- New:
  - `@showPerPageOptions` (`@hidePerPageOptions` is kept as a deprecated alias)
  - `0` means all rows: the button reads "Showing all rows", the option reads "Show all rows", and the pages are hidden
  - the current option gets `aria-current="true"`
  - the options panel gets `data-test-subj="tablePaginationRowOptions"`
  - `@responsive` and `@ariaControls` are passed to EuiPagination
- The flex group now wraps with gutter `s` (upstream).

### EuiTableSortMobile

- Upstream `margin-inline-start: auto` on the root.
- Items get upstream's aria-labels ("Sort Name descending" etc.), because `@ariaLabel` is now passed the item name.
- Icons keep Ember's names (`arrowDown` for upstream's `chevronSingleDown`).

### Scoped resets

These stand in for React's global reset, composed before the upstream slots:

- Cells: box sizing, margin/padding 0, no border, `vertical-align: baseline`. The upstream rules then set the borders.
- Table: margin/padding 0, `border-spacing: 0`.
- Header buttons: upstream's `button` reset plus the theme font family, `text-align: inherit` and a pointer cursor.

## Styling migrated children

- No second Emotion class is added to a migrated child.
- The sort icons on EuiIcon use plain class names (`euiTableSortIcon`, `euiTableSortIcon--sortable`) and `@color="subdued"`. The sortable tint comes from upstream's button rule (`.button .euiTableSortIcon--sortable`), which wins by specificity, as upstream.
- `@css` was not needed.

## Existing test changes (`eui-table-test.gts`)

Each change below replaces a legacy class check with an equivalent native or semantic check:

- `euiTable--compressed/--auto/--responsive` became computed `table-layout: auto` plus the upstream wrapper.
- `euiTableCellContent--alignRight` became computed `justify-content: flex-end`.
- The header `.euiTableCellContent__text` title became `.eui-textTruncate`.
- The mobile header is asserted absent on desktop, because it now renders only in cards; the cards rendering is covered in the new file.
- `--truncateText` became computed `white-space: nowrap`.
- `--middle` became computed `vertical-align: middle`.
- An unsorted sortable column now has the upstream `euiTableSortIcon--sortable` icon. Before, the test asserted it had no icon.
- `--overflowingContent` became "the content has no text span".
- `__hoverItem` became `euiBasicTableAction-showOnHover`.
- EuiTableHeaderMobile gets `@responsiveBreakpoint={{true}}`, because it renders only in cards.

No other assertion was changed or weakened.

## New coverage (`Borealis table family`, 12 tests)

- **Table:** fixed/auto layout, full width, background on/off, tabular numbers, `s` vs compressed `xs` font sizes (relative to the provider root), content padding s/xs, cell borders and color, measured row height. Header and footer cell typography and colors, footer background and truncation.
- **Rows:** selected background, hover rules read from the stylesheet, clickable focus color, click/Enter/Space, Space `preventDefault`, removing `@onClick`, expanded background/checkbox offset/animation. Every reactive change keeps the same element.
- **Row cells:**
  - each alignment, reactively (`justify-content` plus logical `text-align`)
  - wrapping by default, truncation measured (`scrollWidth > clientWidth`)
  - `textOnly=false`, `valign` top/bottom/baseline, `width`/`minWidth`/`maxWidth` styles, row header `th`
  - actions gap and `line-height: 1`, `showOnHover` hidden until focus-within
- **Header cells:**
  - `aria-sort` none/ascending/descending, reactively without replacement
  - the `sortable`/`sortUp`/`sortDown` icons and the sortable tint
  - button reset/width/weight/color, hover underline rule, focus primary and underline
  - title with description, screen-reader-only description, click
  - read-only and plain cells, empty `td`
- **Checkbox cells:** widths, borders, alignment, and selection with EuiCheckbox (row and select-all).
- **Responsive:**
  - The query matches at `m` but not at `m - 1` in iframes (flex-family technique).
  - The real window is tested exactly at the boundary by overriding `breakpoint.m` to `innerWidth + 1` (cards) and then `innerWidth` (table).
  - In cards: hidden header, flex cards, radius/margin, checkbox and actions columns, absolute checkbox, mobile header, enlarge, mobile widths/alignment, `show`/`only`, the `<:mobile>` block, visible hover actions, EuiTableHeaderMobile.
  - The switch back to the table keeps the same element. A sibling table outside the provider stays a table.
- **Responsive arguments:** `@responsiveBreakpoint` true/xl/xs, `@responsive={{false}}`, precedence, `hasBackground=false` pseudo border.
- **Pagination:** upstream defaults, options/`aria-current`, choosing a size closes the popover, page buttons/next/disabled last, show-all (0) hides the pages, `showPerPageOptions=false`, reactive without replacement.
- **Mobile sort:** labels, sorted icon, item click. Also the header button reset, layout, title, icon and hover rule.
- **Themes:**
  - light/dark from the nearest provider, without replacing elements
  - nested JS-object overrides (`size.s`, `backgroundBasePlain` per mode)
  - sibling isolation
- **RTL:** logical alignment measured, the card's checkbox column on the right, `inset-inline-start`.
- **Preferred high contrast:** cards get real 1px solid borders (with and without background); the standard theme keeps the shadow only.

## Checks run (2026-10-12, worktree `eui-wave/table`)

Environment: Node 22.22.1, binaries run directly (no pnpm), Chromium 130 through the scratchpad shim, `CI=true`.

- Core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **973 tests, 973 pass, 0 fail**.
- Filtered `table` run: 46/46.
- `node --test scripts/eui-upstream-parity.test.mjs`: **242/242 pass**.
- `ember-tsc --noEmit`: pass. ESLint on `-private/table.ts`, all `eui-table*.gts` and both test files: pass.
- `node scripts/generate-api-docs.mjs --check`: pass after regenerating `docs/tabular/table/index.md`.
- `node scripts/generate-eui-styles.mjs --check`: "Stale generated artifact" **in this worktree only**, because of the symlinked `node_modules` path comments. Regenerating and normalizing is byte-identical to the committed files.
- Not run (coordinator): rollup core build, site build/acceptance, showcase.

## Unresolved

1. Not ported:
   - `stickyHeader`, `stickyScrollbar` and per-cell `sticky` (upstream beta; they need the column store and a cloned header).
   - `tooltipProps` on header cells.
   - Multi-line `truncateText: { lines }` (needs EuiTextBlockTruncate).
   - `append` on cells.
2. EuiTablePagination: upstream adds `eui-xScroll` to its flex group. EuiFlexGroup has no `@css`, and utility classes are not injected, so it is omitted. **Coordinator: add `@css` to EuiFlexGroup**, then pass `euiXScroll`.
3. Pagination and mobile sort icons use Ember's `arrowDown` (upstream `chevronSingleDown`). Switch if the icon family adds the name.
4. EuiTableSortMobileItem only gets an aria-label when `@ariaLabel` is passed: Ember cannot read the block text up front. EuiTableSortMobile passes the item name.
5. Default changes to audit in docs and callers:
   - pagination 10 / [10, 25, 50]
   - word breaking by default
   - sortable icon
   - EuiTableHeaderMobile hidden on desktop
   - FastBoot renders a table, not cards
6. Docs demos (`docs/tabular/table/demo/*`) were not visually audited. `d03-responsive` still works (narrow the window).

## Next step

Coordinator:

- Merge, union the `// table` generator/parity blocks, regenerate in the main checkout, run the full suite.
- Add `@css` to EuiFlexGroup for the pagination `eui-xScroll`.
- Visually check the table docs pages at desktop and below 768px.
