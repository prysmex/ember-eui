# Tables gaps handoff (EuiBasicTable, EuiInMemoryTable, EuiTable)

Branch `eui-wave/tables-gaps` (from `feat/eui-latest` at `831b7169`). Upstream EUI 123.1.0.
Closes the tables rows of `docs-audit-gaps.md` (EuiBasicTable, EuiInMemoryTable, EuiTable). The
EuiDataGrid rows are untouched.

## Closed

Every item was checked against 123.1.0's source (`basic_table.tsx`, `table_types.ts`,
`table_row_cell.tsx`, `_table_cell_content.tsx`, `table_header_cell*.tsx`,
`table_footer_cell.tsx`, `table.tsx`, `sticky_header/`, `sticky_scrollbar/`, `store/`,
`use_panel_props.ts`, `panel.styles.ts`, `in_memory_table.tsx`). All of them exist in 123.1.0.

### EuiBasicTable

- **Column `valign`**: `'top' | 'middle' | 'bottom' | 'baseline'`, on field and computed columns.
  It goes to `EuiTableRowCell @valign`, so it affects body cells only, as upstream (upstream spreads
  the column's `TdHTMLAttributes` onto the cell). Default `'middle'`.
- **`truncateText: { lines }`**: added to columns, `mobileOptions.truncateText`,
  `EuiTableRowCell @truncateText` and the type `TableTruncateText`. Same as upstream
  `EuiTableCellContent`:
  - The text span is clamped with `EuiTextBlockTruncate @cloneElement`
    (`span.euiTableCellContent__text.euiTextBlockTruncate` with an inline `-webkit-line-clamp`).
  - The content wrapper gets neither the truncate styles nor the word-break styles.
- **`cellProps` no longer leaks cell props to the DOM**: this was the bug. Upstream spreads
  `cellProps` onto `EuiTableRowCell`, which consumes its own props.
  - The Ember cell now takes these keys as arguments: `align`, `textOnly`, `truncateText`,
    `valign`, `isExpander`, `setScopeRow`, `hasActions`, `showOnHover`, `width`, `minWidth`,
    `maxWidth`, `mobileOptions` and `sticky` (`splitCellProps` in `-private/basic-table.ts`).
    Other keys still become attributes or listeners.
  - Precedence follows upstream's spread order. Derived props come first, then `cellProps`, then
    the column's own `width`/`minWidth`/`maxWidth`/`truncateText`/`valign`.
- **Column `name` as rich content**: text, `htmlSafe`, or a component rendered with no arguments.
  A React node carries no props, so I chose a component with no arguments over a per-column block.
  - It renders in the header cell, as the cards header (the `mobileOptions.header` fallback, which
    now also accepts a component) and in the mobile sort menu.
  - Header `data-test-subj` and the sort fallback (`sort.field === name`) still use text names.
    Upstream does the same.
  - The private `-private/table-node.gts` renders this content.
- **Sticky actions column** (`sticky: true`, upstream beta):
  - Only with `@scrollableInline`, and never in the cards layout.
  - The header, row and footer cells get `{ side: 'end' }` plus `data-sticky="end"`.
  - The styles come from upstream's `euiTableStickyCellStyles`: `position: sticky`, the background
    variable `--euiTableCellStickyBackgroundColor`, and a `scroll-state` container query border.
- **Small fixes found by the prop comparison**:
  - `nameTooltip.iconProps` and `nameTooltip.tooltipProps` (upstream) are passed through. Ember's
    `position` shortcut still works.
  - `@stickyHeader` and `@stickyScrollbar` are forwarded to `EuiTable`.

### EuiTable and its cells

- **`@stickyHeader`** (beta), a port of `EuiTableStickyHeader`:
  - A zero-height, `aria-hidden` wrapper sits before `div.euiTable__wrapper`. It holds
    `div.euiTableStickyHeader__container > table.euiTableStickyHeader > thead`, with upstream's
    `euiTableStickyHeaderStyles` and table styles.
  - Upstream renders each registered header cell again from the table's column store. In Ember:
    - Each `EuiTableHeaderCell` and `EuiTableHeaderCellCheckbox` renders a copy of itself into the
      sticky row with `{{#in-element}}`. The copy has the same args and `...attributes`, and its
      content is the same block rendered twice (upstream also renders the cell twice).
    - The copies' widths follow the originals through a `ResizeObserver` (upstream
      `updateColumnWidth`, content-box width), with an initial `getBoundingClientRect`.
    - Copies are appended in render order. The table puts them back in the cells' DOM order
      (`afterRender`, plus a `MutationObserver` on the table for moved cells).
  - With `@scrollableInline`, the inline scroll and the min width are synced from the table, as
    upstream.
  - It is not rendered in the cards layout.
  - The CSS variables `--euiTableStickyHeaderOffsetTop` and `--euiTableStickyHeaderZIndex` work.
- **`@stickyScrollbar`** (beta), a port of `EuiTableStickyScrollbar`:
  - It renders after the wrapper, needs `@scrollableInline`, and shows only while the wrapper
    overflows.
  - A `ResizeObserver` tracks overflow and an `IntersectionObserver` hides the bar while the
    table's bottom is visible. The track size and offset update with `rAF`.
  - Dragging the track uses pointer capture.
- **`@sticky={{hash side="start"|"end"}}`** on `EuiTableRowCell`, `EuiTableHeaderCell` and
  `EuiTableFooterCell` (upstream `@internal` beta). The cells render `data-sticky`, and no sticky
  styles apply in cards.
- **How sticky interacts with responsive/mobile layouts** (upstream behaviour):
  - In the cards layout (`isResponsive`) the sticky header is not rendered and the cells get no
    sticky styles or `data-sticky`.
  - The cards' mobile header, select-all and sort menu are unchanged.
  - Switching layouts reactively tears the copies down and restores them.

### EuiInMemoryTable: custom panels

`useEuiBasicTablePanelProps` takes three Ember shapes. Each one is exported from
`eui-basic-table.gts`, or is a public component:

- `useEuiBasicTablePanelProps()` is a plain function. It returns `{ css, className }`: `css` is the
  theme function `euiBasicTablePanelStyles` for any migrated component's `@css`, and `className` is
  `'euiBasicTablePanel'`.
- `EuiBasicTablePanel` is a new public component, registered in `components.ts` and
  `template-registry.ts`. It is a `<div>` built on that function, with `@css` composed last.
- `<:childrenBetween as |Panel panelProps|>` yields the component and the props. It was a block
  with no params before, so the change is backward compatible.

Upstream's panelled wrapper styles make a panelled table join the panels above it, and consecutive
panels with the same style join each other.

## Other upstream props compared (EuiBasicTable / EuiInMemoryTable)

Every top-level upstream prop of both tables is now an Ember arg. The remaining gaps are small, and
I listed them in the `docs-audit-gaps.md` EuiBasicTable row:

- An action's `name` is text only. Upstream accepts a ReactNode.
- A column object forwards only `className` and `data-test-subj` to its cells. Upstream spreads any
  `<td>` attribute; use `cellProps` instead.
- The copy-to-clipboard tabular markers (`OverrideCopiedTabularContent`) are not ported. Neither
  are the `EuiComponentDefaultsContext` page-size defaults. Both were already known.
- In-memory `onChange`: in upstream the `rest` spread lets it override the internal handler. That is
  an upstream quirk, so I left it out.

## Behaviour changes (latest-only, upstream-faithful)

- `@cellProps` keys that are cell arguments (list above) are no longer set as DOM attributes. For
  example, `align: 'center'` used to set an `align` attribute and now centres the content.
- When both set a value, a column's `className` and a `cellProps` `className` now both apply.
  Before, the `cellProps` one replaced the column's. A column's `data-test-subj` now wins over a
  `cellProps` one, as in upstream's spread order.
- `EuiTableSortMobile`: an item gets an `aria-label` only for text names. Upstream uses the
  children.
- With `@stickyHeader`/`@stickyScrollbar`, `EuiTable` renders sibling elements before or after its
  wrapper, as upstream does.
  - The header cells' content and attributes appear twice: duplicate ids and `data-test-subj` in
    the hidden copy, as upstream.
  - Test helpers that pick the first matching header element now find the copy, which comes first.
- No existing test changed.

## Browser note

Upstream scrolls with `overflow-inline` (wrapper) and `overflow-inline: hidden` (sticky container).
Playwright's Chromium 130 supports neither (`CSS.supports` is false). There the table overflows its
container instead of scrolling, and React EUI behaves the same in that browser.

The tests that exercise scrolling set `overflow-x` on those elements to stand in for a supporting
browser. I didn't change the styles, to stay faithful. Consider adding a physical
`overflow-x` fallback, which would be an Ember-only deviation.

## Styles and parity

- Generator: a new `// tables-gaps` block extracts `euiTableStickyHeaderStyles`,
  `euiTableStickyScrollbarStyles` and `euiContainerQuery`. The last uses an extension-less key so
  that the existing `_container_query.js` entry is not edited.
- Hand port in `utils/eui/table.ts`: `euiTableStickyCellStyles`. Upstream keeps it module-local and
  only exposes it through the `_useEuiTableStickyCellStyles` hook.
- Parity tests:
  - Both new factories are in the 12-configuration `factories` matrix.
  - A new test compares the hand port with the upstream hook (loaded with a stubbed
    `useEuiMemoizedStyles`) in every color/contrast mode, and compares `euiContainerQuery`.
- `styles.generated.ts` and `upstream-sources.json` were regenerated, and the worktree path
  comments normalized to `node_modules/…`. Regenerating and normalizing gives no diff.

## Files

- New:
  - `src/utils/eui/table.ts`
  - `src/-private/table-node.gts`
  - `src/components/eui-table/sticky-header.gts`
  - `src/components/eui-table/sticky-scrollbar.gts`
  - `src/components/eui-basic-table-panel.gts`
  - `tests/integration/components/eui-tables-gaps-test.gts`
- Changed:
  - `src/-private/table.ts`: `TableTruncateText`, the context fields for the sticky row and
    registration, and the `StickyHeaderCellSync` modifiers.
  - `src/-private/basic-table.ts`: the column types and `splitCellProps`.
  - The components `eui-table`, `eui-table-row-cell`, `eui-table-header-cell`,
    `eui-table-header-cell-checkbox`, `eui-table-footer-cell`, `eui-table-sort-mobile`,
    `eui-basic-table` and `eui-in-memory-table`.
  - `components.ts` and `template-registry.ts` (lines added only).
  - `package.json` app-js (from `rollup --config`).
- Docs:
  - basic-table:
    - index text.
    - d08 table layout: re-added upstream's vertical align button group and Address
      `truncateText: { lines: 2 }`.
    - d10 inline scrolling: a sticky actions column and `@stickyScrollbar`.
  - in-memory-table: index text, plus a new d10 "Custom panels" demo (upstream example).
  - table: index text, plus a new d03 "Sticky headers and horizontal scrollbar (beta)" demo.
  - table-layout-guidelines: the sticky actions rule is restored.
  - `scripts/api-docs-pages.json`: `EuiBasicTablePanel` is on the in-memory page, an added line.
    The API tables were regenerated. The page count is unchanged (110), so the site nav count
    stays the same.
- `docs-audit-gaps.md`: the three rows are closed; I replaced the EuiBasicTable row with the
  remaining small gaps.

## Checks (2026-10-13)

- `ember-tsc --noEmit`: pass. ESLint on every changed source and test file: pass.
- `node --test scripts/eui-upstream-parity.test.mjs`: 356/356.
- `node scripts/generate-api-docs.mjs --check`: pass.
- Core `rollup --config`: pass.
- Focused Chromium 130 runs:
  - new `Borealis tables gaps`: 8/8.
  - `filter=table`: 95/95, which covers the existing table family, basic table, in-memory table
    and selectable tests, all unmodified.
  - `filter=grid` (data grid): 97/97.
  - search bar: 9/9.
- Full core Chromium 130 suite: **1666/1666** (main 1658 + 8 new).

The new tests cover:

- the features on their own: valign, line clamping, `cellProps` args, rich names, sticky actions,
  the sticky header (widths, order, scroll sync, sort click, toggling and cards) and the sticky
  scrollbar (overflow, drag, track).
- a combined table with sticky header + sticky actions + sticky scrollbar + clamp + valign,
  exercising sorting from the copy, select all from the copy, row selection, pagination (clears
  the selection, as upstream), expanded rows and collapsed actions. The cards switch removes the
  sticky parts and keeps the mobile header, sort and clamp.
- the in-memory table with a sticky header (sorting from the copy).
- the custom panels (function, component, yielded block, joining).

## For the coordinator

- Merge the generated files by regenerating (`// tables-gaps` generator block).
- `EuiBasicTablePanel` is a new public component (its `components.md` row is added, Migrated).
- Decide whether to add a physical `overflow-x` fallback for `@scrollableInline` (see the browser
  note above).
