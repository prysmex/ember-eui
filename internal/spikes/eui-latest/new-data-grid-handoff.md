# New component: EuiDataGrid (new-data-grid)

Branch `eui-wave/new-data-grid`, from `feat/eui-latest` (40bb9591). Target EUI
123.1.0 / Borealis 8.1.0. Status: **Migrated** — all five planned milestones
are done; the gaps listed under "Not ported" are deliberate scope cuts, not
half-done code.

## Milestones

| # | Milestone | Status |
| --- | --- | --- |
| 1 | Core grid: columns/rowCount/`@renderCellValue` + `<:cell>`, header, cells, all upstream styles, `@gridStyle`, `@rowHeightsOptions` (static, lineCount, per-row, measured auto), ARIA grid semantics | Done |
| 2 | Keyboard navigation and focus (single tabbable cell, arrows/Home/End/PageUp/PageDown/Ctrl+Home/End, Enter/F2/Escape), interactive-cell focus trap, cell actions, expansion popover, header column actions | Done |
| 3 | Virtualization (rows and columns, overscan), `@height`/`@width`, sticky header/footer, scroll-into-view, `virtualizationOptions` callbacks | Done |
| 4 | Toolbar: column selector (search, hide/show, drag reorder), sort popover, display selector (density, lines per row, reset), keyboard shortcuts, fullscreen, `toolbarVisibility` options, additional controls | Done |
| 5 | Pagination (EuiTablePagination), column resizing (mouse), leading/trailing control columns, footer row, `@inMemory` schema detection and sorting | Done |

## Files

- `packages/core/src/components/eui-data-grid.gts` — root (`EuiDataGrid`): grid
  state shared with its parts (focus registry, popover cell, display-selector
  overrides, column order, in-memory values, fullscreen), classes/styles, ARIA,
  keyboard handling.
- `packages/core/src/components/eui-data-grid-toolbar-control.gts` — public
  `EuiDataGridToolbarControl`.
- `packages/core/src/components/eui-data-grid/` — private parts: `body` (virtualized
  body), `row`, `cell`, `cell-actions`, `header-row`, `header-cell`,
  `column-actions`, `column-resizer`, `footer-row`, `toolbar`, `column-selector`,
  `column-sorting`, `display-selector`, `keyboard-shortcuts`,
  `fullscreen-selector`, `pagination`, `in-memory-renderer`.
- `packages/core/src/utils/data-grid/` — ported pure logic: `types.ts`,
  `schema.ts` (detectors, comparators, detection), `sorting.ts`,
  `row-heights.ts` (`RowHeightUtils`), `focus.ts` (key handler, tab
  management, copy), `toolbar.ts`, `scheduling.ts`.
- `packages/core/src/utils/eui/data-grid.ts` — hand ports (with parity test) of
  `fullscreen_selector.styles` (vanilla `@emotion/css`), the toolbar control's
  inline styles and the display selector's inline styles/width.
- Generator: 17 datagrid style modules (22 exports) in the `// new-data-grid`
  block of `scripts/generate-eui-styles.mjs`; parity entries in
  `scripts/eui-upstream-parity.test.mjs` plus a hand-port parity test.
- Registries: `EuiDataGrid`, `EuiDataGridToolbarControl` in `components.ts` /
  `template-registry.ts`; `packages/core/package.json` app-js refreshed by rollup.
- Docs: `packages/core/docs/tabular/data-grid/{basics,schema-and-sorting,toolbar,cells-and-popovers,virtualization,pagination,control-columns}/`
  (7 pages, 10 demos); API reference on the basics page
  (`scripts/api-docs-pages.json` entry added).
- Tests (33): `tests/integration/components/eui-data-grid-test.gts` (semantics,
  computed styles, gridStyle reactivity without re-creating cells, row heights,
  auto heights, dark mode/overrides, setCellProps/rowClasses/reactive args,
  popover renderers), `-keyboard-test` (navigation, popover, cell actions,
  focus trap, header actions), `-virtualization-test` (windowed rows/columns,
  stable cells while scrolling, keyboard scroll-into-view, callbacks,
  unconstrained height), `-toolbar-test`, `-features-test` (pagination,
  control columns/footer, in-memory sorting, resizing, hash-based state as in
  the docs demos).

## Ember API and differences from upstream

- Cell content: `@renderCellValue` component (args `@rowIndex @colIndex
  @columnId @setCellProps @isExpandable @isExpanded @isDetails @schema
  @cellContext`) or the `<:cell as |cell|>` block (same keys). React props
  spread from `cellContext` become `@cellContext`.
- Other render props are components or named blocks: `@renderCellPopover` /
  `<:cellPopover>` (yields `rowIndex colIndex columnId schema
  cellContentsElement setCellPopoverProps cellActions`; it does not re-render a
  block-based cell value), `@renderFooterCellValue` / `<:footerCell>`, control
  columns' `headerCellRender`/`rowCellRender`/`footerCellRender` or
  `<:controlHeaderCell>`/`<:controlCell>`/`<:controlFooterCell>` (switch on
  `columnId`), column `display` is a component.
- `toolbarVisibility.additionalControls` → `<:leftControlsPrepend>`,
  `<:leftControlsAppend>`, `<:rightControls>` blocks.
- `cellActions` accept upstream-style components (`@Component` button) or, as
  an Ember convenience, `{ iconType, label, onClick, 'data-test-subj' }`
  descriptors.
- `@columnVisibility` is optional (internal state, all columns visible).
- `aria-label`/`aria-labelledby` attributes are moved to the `role=grid`
  element (like upstream's prop handling); `@ariaLabel`/`@ariaLabelledBy`
  args do the same.
- Additions: `aria-colcount` on the grid and `aria-colindex` on cells/headers
  (upstream sets neither; columns are virtualized here).
- `@pagination` fields are read one by one (objects with tracked accessors
  work); `gridStyle`/`rowHeightsOptions` should be plain objects (they are
  compared structurally, like upstream's `useDeepEqual`).
- `setCellProps` may be called during render (e.g. `{{cell.setCellProps
  (hash …)}}`): updates are applied after render and compared shallowly.
- Virtualization is Ember-native (no react-window): row/column offsets are
  prefix sums (arithmetic for uniform rows); the rendered window is tracked as
  integer bounds and only invalidates when they change, rows/cells are keyed by
  index so cells that stay in range keep their DOM. `virtualizationOptions`
  supports `overscanRowCount`, `overscanColumnCount`, `onItemsRendered`
  (called after render) and `onScroll`.
- Measurements use offset sizes (not `getBoundingClientRect`), so ancestors'
  CSS transforms (e.g. the scaled test container) don't break sizing.
- The grid's unconstrained height uses measured auto row heights (upstream
  estimates auto rows with the default height).
- Scoped reset: the grid adds `*:where(& *) { box-sizing: border-box }`
  (zero specificity) because upstream's cell layout relies on the global reset.
- `@css` (added to EuiButtonGroup, EuiDroppable, EuiDraggable, EuiFilterGroup
  and EuiTable on `eui-wave/css-gaps`): the sort popover's order styles go on
  `EuiButtonGroup @css` and the column selector/sorting list styles on
  `EuiDroppable @css` / `EuiDraggable @css` like upstream; the former wrapper
  divs and the order flex item class are gone. The pagination's `aria-label`
  is `EuiTablePagination @aria-label`.
- Upstream behavior kept: `minRowHeight` measured for `lineCount` persists when
  switching to a smaller static height; sort pruning of hidden columns happens
  in the toolbar sort control; column widths reset when the visible columns
  change.

## Not ported (scope cuts)

- Drag and drop of header columns (`columnVisibility.canDragAndDropColumns`);
  columns can be reordered from the column selector and the header actions.
- `renderCustomGridBody` and `renderCustomToolbar`.
- The imperative ref API (`setIsFullScreen`, `setFocusedCell`,
  `openCellPopover`, `closeCellPopover`, `scrollToItem`).
- `rowHeightsOptions.scrollAnchorRow` (layout-shift compensation).
- Tabular copy markers (`OverrideCopiedTabularContent`); Ctrl/Cmd+C copying of
  the focused cell is ported.
- Keyboard column resizing (upstream has none either).

## Checks (2026-10-12, this worktree, Chromium 130)

- `ember-tsc --noEmit`: pass.
- ESLint on all new/changed source and test files: pass.
- `node scripts/generate-eui-styles.mjs`: 385 factories; parity
  `node --test scripts/eui-upstream-parity.test.mjs`: 340/340.
- `node scripts/generate-api-docs.mjs --check`: pass (1 page added).
- Core Rollup build (declarations + package exports): pass.
- Vite browser-test build: pass.
- Data grid tests (filter `EuiDataGrid`): 33/33.
- Full core suite: 1215/1215.

## For the coordinator

- Site checks were not run (not allowed here). The 7 docs pages add a
  `data-grid` group under "Tabular content": update the side-nav count in
  `site/tests/acceptance/docs-test.ts` (109 → 116, or 117 if the group itself is
  a nav item).
- Generated files were regenerated in the worktree (stale source-path comments
  are expected; regenerate in main after merging).
