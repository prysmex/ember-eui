# EuiDataGrid nested rows and grouping (data-grid-grouping)

Branch `eui-wave/data-grid-grouping`, from `feat/eui-latest` (e8f5e032).
**Ember EUI extension**: upstream EUI 123.1.0 has no tree data or row
grouping. Both are opt-in args; without them the grid's behavior, DOM and
`@registerApi` object are unchanged (all 55 existing data grid tests pass
unmodified).

## API

- `@rowTree`: the rows array itself (zero config) or
  `{ rows, getChildren, getParentId, getRowId, expandedRowIds,
  defaultExpandedRowIds ('all' | ids), onExpandedChange, toggleColumnId }`.
  Nested form: a row's `children` array (default) — data row indexes are
  pre-order. Flat form (no row has `children`): `parentId ?? parent` points
  at another row's `id` — `@rowIndex` is the array index. Ids default to
  `row.id`, else the index. Expansion is uncontrolled (internal) unless
  `expandedRowIds` is passed; `onExpandedChange` is called either way.
  `@rowCount` is optional (made optional in the signature).
- `@grouping`: `{ groupBy: string[], getValue?(rowIndex, columnId, row),
  rows?, expandedGroupIds, defaultExpandedGroupIds, onExpandedChange,
  renderGroupCell, toggleColumnId }`. `getValue` defaults to
  `row[columnId]` when rows are known (`grouping.rows` or `@rowTree`). With
  `@rowTree`, root rows are grouped and keep their subtrees. Group ids are
  `group:` + JSON of the value path (`group:["France","Paris"]`).
  `renderGroupCell` is a component rendered in every data cell of a group
  row (`@group {columnId,value,count,rowIndices}`, `@groupId`, `@columnId`,
  `@colIndex`, `@isToggleCell`, `@isExpanded`, `@depth`) — aggregates are a
  consumer render concern. Default: value + `(count)` in the toggle cell.
- Renderers (`@renderCellValue`, `<:cell>`, popovers, in-memory renderer)
  also get `@row` / `row` (undefined without the new args).
- `@registerApi` adds `expandRow(id)`, `collapseRow(id)`, `expandAll()`,
  `collapseAll()` only when `@rowTree`/`@grouping` is active;
  `setFocusedCell`/`openCellPopover` expand a hidden row's ancestors.
- ARIA: `role="treegrid"`, `aria-rowcount` = visible rows; rows get
  `aria-level`, `aria-setsize`, `aria-posinset`, `aria-expanded` (parents
  only). Group rows also get class `euiDataGridRow--group`.
- Keyboard: in the toggle cell Space toggles; Enter toggles when the cell
  is not expandable (group rows always) and otherwise still opens the
  popover. ArrowLeft/Right keep moving between cells (documented: the grid
  focuses cells, so APG treegrid row arrows would conflict).

## Grid core changes (the "integrity" surface)

1. `eui-data-grid.gts`: `rowTreeModel`/`rowModel` (null without the args),
   `rowCount`/`dataRowCount` getters replacing direct `@rowCount` reads,
   one branch in `getCorrectRowIndex`, `treeRowAt`, `findTreeRowIndex` for
   the API, `toggleRow`, role switch, API extras merged only when active.
2. `cell.gts`: `treeRow`/`isGroupRow`/`isToggleCell`/`rowData` getters,
   group rows not expandable, Space/Enter toggle at the top of `onKeyDown`,
   `<EuiDataGridTreeCell>` before the renderer in both content branches,
   `@row` on the 4 renderer invocations.
3. `row.gts`: 4 ARIA attributes + group class. `pagination.gts`: page count
   from `grid.rowCount`. `in-memory-renderer.gts`: `@row`.

Everything else is new: `utils/data-grid/row-tree.ts` (pure model:
build nested/flat trees with cycle guards, group, sort siblings, flatten,
ancestors), `eui-data-grid/row-model.ts` (tracked expanded state,
controlled/uncontrolled, sorting inputs), `eui-data-grid/tree-cell.gts`
(indent + `EuiButtonIcon` arrowRight/arrowDown toggle with `tabindex=-1` so
it is not an interactive child, group label/count, `renderGroupCell`).
Types appended to `utils/data-grid/types.ts`.

## Interactions

- Sorting: siblings sorted by the in-memory sort rank (`inMemory.level
  'sorting'`); otherwise rows keep the consumer's order. Groups sort by
  value (empty last, numeric/date/natural text), in the direction of their
  column when `@sorting` includes it, else ascending.
- Pagination pages over visible rows; collapsing can leave `pageIndex` past
  the end (consumer state, as with any row count change).
- Virtualization, row heights, focus, popover, copy work unchanged on the
  visible list. Group rows use stable negative row indexes (`-1`, `-2`, …)
  so height caches / cell props never collide with data rows;
  `rowHeightsOptions.rowHeights` applies to data rows only.
- Control columns render nothing in group rows (no synthetic index reaches
  `rowCellRender`). Custom grid bodies get the toggle in their cells but no
  tree ARIA on their own rows. Block content in the toggle column wraps
  below the toggle (render inline content there).
- Not done: `<:groupRow>` block (blocks would need threading through
  body/row/cell — `renderGroupCell` component instead), lazy-loaded
  children, group selection, built-in aggregates.

## Checks (worktree)

- ember-tsc clean; eslint clean on changed files.
- Full core suite **1288/1288** (was 1267; +12 unit `data-grid-row-tree`,
  +9 integration `eui-data-grid-tree-test.gts`). Data grid integration
  64/64.
- Parity `node --test scripts/eui-upstream-parity.test.mjs` 349/349 (no
  generator changes).
- Visual check: headless Chrome screenshot of nested and grouped grids in a
  provider (toggle aligned, indentation per level, no row overflow).

## Docs

`packages/core/docs/tabular/data-grid/grouping/` (order 8): extension
callout, options tables, behavior notes; demos: nested `children` (lead),
flat `parentId` with controlled expand/collapse all, group-by switcher with
in-memory sorting + pagination. API table on the basics page regenerated.

## Coordinator

- Site acceptance nav count changed 113 -> 114
  (`site/tests/acceptance/docs-test.ts`); the docs demos were not run in
  the site (no site builds here).
- `packages/core/package.json` app-js: added `eui-data-grid/row-model.js`
  and `eui-data-grid/tree-cell.js` only (rollup also reordered
  `eui-in-memory-table.js`; that hunk was dropped).
- `components.md`: one new row (`eui-data-grid/tree-cell.gts`).
