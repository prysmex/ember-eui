# Gaps: EuiDataGrid and EuiBasicTable (gaps-grid)

Branch `eui-wave/gaps-grid`, from `feat/eui-latest` at `59460f9c`. Upstream EUI 123.1.0.
This closes the `docs-audit-gaps.md` rows for EuiBasicTable, EuiDataGrid and the EuiDataGrid
extension. One EuiDataGrid row stays: react-window's own options, explained below.

## Closed

### EuiDataGrid

- **`virtualizationOptions.onScroll`** now passes react-window's `GridOnScrollProps`:
  `horizontalScrollDirection`, `verticalScrollDirection` and `scrollUpdateWasRequested`. It still
  passes the DOM sizes and the `isScrolledTo*` flags. The port follows react-window 1.8.11's
  `Grid`, and `body.gts` keeps the same scroll state:
  - The callback runs once when the body mounts (react-window's `componentDidMount`), with the
    initial offsets, `forward`/`forward` and `requested: false`.
  - A user scroll compares the new offsets, clamped to the scroll range, with the previous ones.
    If they are the same, nothing is reported. Otherwise the direction is `forward` when
    `prev < next` and `backward` otherwise (an axis that didn't move reports `backward`, as in
    react-window), with `requested: false`.
  - These scrolls report `requested: true`: `scrollTo`, `scrollToItem`, and a focused cell
    scrolled into view (`scrollCellIntoView` now goes through `scrollTo`, as upstream calls
    react-window's `scrollTo`).
    - The requested offset is reported, floored at 0, and the browser's own `scroll` event for it
      is not reported again.
    - If the request is past the end, the clamped position follows with `requested: false`.
  - `scrollTop`/`scrollLeft` in the payload still come from the DOM, as in upstream's wrapper.
- **`virtualizationOptions.estimatedRowHeight`** follows react-window's `getEstimatedTotalHeight`.
  - The rows laid out so far count at their real height, and the others at the estimate. The laid
    out rows are those up to the furthest rendered or `scrollToItem` target, and they reset when
    the row layout changes.
  - The estimate only affects the scrollable height. Row positions stay exact, and so does the
    unconstrained (auto) grid height, as upstream's `useUnconstrainedHeight`.
  - Without the option the scrollable height stays exact, as before. That is an Ember difference:
    react-window assumes 50 there.
  - `scrollToItem` uses the estimated total, as react-window does.
- **`footerCellProps.style`** on control columns applies to the footer cell, in upstream's
  `EuiDataGridCell` order: the column style first, then the cell's width, `lineHeight` and
  `setCellProps` styles. A truthy `top` becomes `0`. `className` already worked.
  - Upstream passes the other `footerCellProps` keys to the cell content, not the DOM, so nothing
    else is forwarded.
- **Cell action `closePopover`**: I checked `data_grid_cell_actions.tsx`. Upstream passes only
  `rowIndex`, `colIndex`, `columnId`, `Component` and `isExpanded`, and its docs example reads an
  undefined `closePopover`. Nothing was added. The cell actions demo now says so and keeps using
  the API's `closeCellPopover`.
- **"No custom virtualization"** stays a gap. The container constraints docs now explain that
  the Ember body is its own virtualizer, which react-window options don't apply to, and point to
  `@renderCustomGridBody` as the way to replace it.

### EuiDataGrid extension (row-tree): `@rowTree` for renderers

- With `@rowTree`/`@grouping`, data cells give their renderers the row's tree state, typed
  `EuiDataGridRowTreeRowInfo`:
  `{ id, depth, hasChildren, isExpanded, parentId, posInSet, setSize, isToggleCell, toggle() }`.
  - `depth` counts group levels.
  - `toggle()` goes through `grid.toggleRow`, so it closes popovers and calls
    `onExpandedChange`.
  - The state reaches every renderer that gets `@row`: `@renderCellValue`, the `<:cell>` block
    (`cell.rowTree`), control `rowCellRender`/`<:controlCell>`, the detail renderers in the
    popover, `@renderCellPopover` and `<:cellPopover>` (`rowTree`). The in-memory renderer is the
    exception (below).
  - It is `undefined` without the args, and on group rows, which render no value.
- **Naming**: I used `@rowTree`, as the prompt suggested. On renderers it means "this row's tree
  state", while the grid's `@rowTree` arg means the rows config.
- **Hooks**: the logic is in `row-tree-hooks.ts` (`RowTreeCellState.info`). The touchpoints are
  marked lines, now 48 (+2: the popover props type and `cellValueProps`), and the renderer hooks
  pass `@rowTree` next to `@row`. `data-grid-extensions.md` is updated, including its tests table.
- **Not on the in-memory renderer.** It reads every data row, including collapsed ones, which
  have no visible tree state. This is documented.
- The tree recipes **file explorer demo** reads `cell.rowTree` (open and closed folder icons)
  and no longer controls `expandedRowIds`. The grouping page's "renderers don't receive the tree
  state" limitation is removed, and that page gains a renderer table and a field table.

### EuiBasicTable

- **Action `name` as rich content**. It can be text, `htmlSafe`, or a component rendered with
  `@item`. A function of the item may return any of these.
  - A component is the Ember shape of a React node that may depend on the item.
  - Functions are told apart from component classes with `getComponentTemplate` or a
    `GlimmerComponent` prototype.
  - The name renders as the button content, as the screen reader label of icon actions and as
    the collapsed menu item.
  - `disableScreenReaderOutput` only applies to string names, as upstream does.
  - `TableNode` now passes `@item`.
- **Other `<td>` attributes on a column object**. Upstream's `renderItemCell` spreads `...rest`,
  which is every key except align, render, dataType, isExpander, textOnly, name, field,
  description, sortable, footer, mobileOptions and nameTooltip.
  - Field and computed columns now forward any other key: `title`, `id`, `data-*`, `aria-*`,
    `on*` listeners and so on, through the existing `elementProps` modifier.
  - Ember column options are excluded: `component`, `readOnly`, `actions` and `css`. Upstream
    would also set a meaningless `readonly` attribute.
  - A column's own cell args (`setScopeRow`, `hasActions`, `showOnHover`, `sticky`) now win over
    `cellProps`, as `width`/`truncateText`/`valign` already did (upstream spread order).
  - `style` (an object or a string) is a new `EuiTableRowCell @style` arg, merged under the
    cell's width styles like upstream's `resolveWidthPropsAsStyle`. A column `style` replaces a
    `cellProps` style, matching the spread. Typed column keys were added, with
    `data-`/`aria-`/`on` template index signatures.
- **Copy-to-clipboard tabular markers**, as in upstream `basic_table.tsx`.
  - Where the markers go:
    - boundary markers around the `EuiTable` (`OverrideCopiedTabularContent`);
    - no-copy bounds inside the caption;
    - after each cell, a tab, or a newline after the last column: header cells, the select-all
      and row checkboxes, data and action cells;
    - a newline after the expanded row cell.
  - `onTabularCopy` is registered on the document (a static, deduped handler).
  - The markers render through new `<:append>` blocks (upstream `append`) on `EuiTableRowCell`,
    `EuiTableHeaderCell` (including its sticky copy), `EuiTableHeaderCellCheckbox` and
    `EuiTableRowCellCheckbox`.
  - The shared marker is `-private/tabular-copy-marker.gts` (template-only, class passed in). It
    reuses `utils/data-grid/tabular-copy.ts`.
- **Page size defaults** (upstream `EuiComponentDefaultsContext.EuiTablePagination`).
  - The Ember shape: `euiConfig` gets a `componentDefaults` key with upstream's keys:
    `componentDefaults: { EuiTablePagination: { itemsPerPage, itemsPerPageOptions,
    showPerPageOptions } }`. It is app-wide (upstream's is provider-scoped) and reactive, since it
    reads the tracked config.
  - `-private/table-pagination-defaults.ts` (`euiTablePaginationDefaults(context)`) replaces the
    four hard-coded copies of upstream's `euiTablePaginationDefaults`.
  - It is used where upstream reads it: `EuiTablePagination`, the basic table's `pageSize` and
    `PaginationBar`, `EuiInMemoryTable`'s initial pagination, and `EuiDataGrid`'s pagination.
  - `PaginationBar`'s `PAGINATION_DEFAULTS` export is kept, with the same values.
  - Only the `EuiTablePagination` defaults are ported. Upstream's other `componentDefaults`
    (`EuiTable`, `EuiPortal`, `EuiFocusTrap`, `EuiFlyout`, `EuiPopover`, `EuiToolTip`) would fit
    the same key later.

## Behaviour changes (upstream-faithful)

| Change | Old | New | Upstream |
| --- | --- | --- | --- |
| Grid `onScroll` on mount | not called until the first scroll | called once on mount | react-window `componentDidMount` → `_callPropsCallbacks` |
| Grid `onScroll` for an unchanged position | every `scroll` event reported | not reported | react-window `_onScroll` returns null; memoized `_callOnScroll` |
| Basic table cell text | `td`/`th`/caption `textContent` = content | content plus hidden marker chars (`↦` `↵` `✄𐘗` `𐘂𐘂`) | `basic_table.tsx` `renderCopyChar`, caption no-copy bounds, `OverrideCopiedTabularContent` |
| `@cellProps` `style` | object ignored; a string replaced the cell's width style | merged under the width styles | `EuiTableRowCell` `resolveWidthPropsAsStyle` |
| Extra column keys | ignored | set on the cells as attributes or listeners | `renderItemCell` `{...rest}` |

App tests that read a table cell's `textContent` will now see the markers. They can read
`.euiTableCellContent`, or drop `[data-tabular-copy-marker]` elements, as the updated tests do.
This is upstream's DOM. If you want an opt-out, it would be an Ember-only config flag. I didn't
add one.

### Existing tests changed (assertions on the markers only)

- `eui-basic-table-test.gts`:
  - the `texts()` helper now ignores markers, through a new `visibleText()`;
  - 3 caption `hasText` assertions, the `.two thead th:last-child` "Actions" assertion and the
    `#row_1_expansion` "Ann details" assertion now compare `visibleText(...)` with the same
    strings;
  - `find` was added to the imports.
- `eui-in-memory-table-test.gts`: the `names()` helper uses `visibleText()`, and 2 caption
  assertions now compare `visibleText(find('caption'))`.
- `eui-tables-gaps-test.gts`: the `texts()` helper uses `visibleText()`, and the
  `.basic #row_2_expansion` text assertion does too.

No data grid test changed.

## Files

- Data grid:
  - `components/eui-data-grid/body.gts`: scroll state, `estimatedRowHeight`,
    `scrollCellIntoView` through `scrollTo`.
  - `cell.gts`: footer style and `@rowTree`.
  - `row-tree-hooks.ts`: `info`.
  - `eui-data-grid.gts`: popover `rowTree?` type and pagination defaults.
  - `utils/data-grid/types.ts`: scroll event fields, `estimatedRowHeight`, `footerCellProps.style`,
    `EuiDataGridRowTreeRowInfo`, `rowTree?`.
- Tables:
  - `-private/basic-table.ts`: `EuiTableActionName`, `resolveItemNode`, `columnCellAttributes`,
    column attribute types.
  - `-private/table-node.gts`: `@item`.
  - New: `-private/tabular-copy-marker.gts` and `-private/table-pagination-defaults.ts`.
  - `components/eui-basic-table.gts` and `eui-basic-table/{default-item-action,collapsed-item-actions,pagination-bar}.gts`.
  - `eui-in-memory-table.gts` and `eui-table-pagination.gts`.
  - `eui-table-{row-cell,header-cell,header-cell-checkbox,row-cell-checkbox}.gts`.
  - `services/eui-config.ts`: `componentDefaults`.
- Tests (new):
  - `tests/integration/components/eui-data-grid-gaps-test.gts` (10);
  - `tests/integration/components/eui-basic-table-gaps-test.gts` (9).
- Docs:
  - data grid:
    - `container-constraints` index and d05 scroll position;
    - `style-and-display` d05 auto heights, which re-adds upstream's `estimatedRowHeight: 210`;
    - `cells-and-popovers` d01 (`closePopover` note);
    - `grouping` index (renderer `@rowTree` tables, types, limitation removed);
    - `tree-recipes` index and d02 file explorer.
  - tables:
    - `basic-table` index (column attributes, rich action names, copying rows, page size
      defaults);
    - `basic-table` d04 row actions (rich name);
    - `in-memory-table` index;
    - `table` index ("Page size defaults").
  - The API tables were regenerated (only `table/index.md` changed: the `<:append>` blocks,
    `@style` and the pagination defaults).
- `docs-audit-gaps.md`: the three rows are replaced by one EuiDataGrid row (react-window options;
  `@renderCustomGridBody`). `data-grid-extensions.md` is updated.
- `package.json` app-js: unchanged. The new files are `-private` and not app-js.

## Checks (2026-10-13, Chromium 130)

- `ember-tsc --noEmit`: clean for this branch's files. One error, outside this branch:
  `src/utils/markdown/plugins/markdown-default-plugins/parsing-plugins.ts(43,6)` (`Emoji` is not
  assignable to `Plugin`). It appeared after the shared `node_modules` changed at 12:43 (an
  `@elastic/eui-illustrations` install), and it is not in my files.
- ESLint on every changed source and test file: pass.
- `node --test scripts/eui-upstream-parity.test.mjs`: 356/356. There are no generator changes.
- `node scripts/generate-api-docs.mjs --check`: pass.
- Data grid filter (`EuiDataGrid`): 87/87, including the 10 new grid tests and one table test whose name mentions EuiDataGrid. Table filter (`table`):
  116/116, including the 9 new tests.
- Full core suite: **1784/1784**.
- `rollup --config` fails while generating declarations, on the same markdown type error from
  `node_modules`. No app-js change is expected from this branch.

## For the coordinator

- The shared `node_modules` change breaks `ember-tsc` and the rollup declarations (markdown
  `Emoji` plugin type). Whoever installed `@elastic/eui-illustrations` should check it.
- The utilities agent's provider docs page could link `componentDefaults`, which lives in
  `euiConfig` and is documented on the table page.
- Decide whether apps need an opt-out of the table copy markers (see the behaviour changes).
- The basic table selection colour and loading line computed-style assertions failed twice in
  filtered runs under heavy machine load, and passed alone and in the full suite. They look
  timing sensitive and are not related to these changes.
