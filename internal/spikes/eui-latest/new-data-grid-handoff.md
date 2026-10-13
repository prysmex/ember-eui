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
  `fullscreen-selector`, `pagination`, `in-memory-renderer`, and (API parity)
  `body-base` (shared body state), `custom-body`, `copy-marker`,
  `default-cell-popover`; `utils/data-grid/tabular-copy.ts`.
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
  (7 pages, 16 demos); API reference on the basics page
  (`scripts/api-docs-pages.json` entry added).
- Tests (55): `eui-data-grid-api-test.gts` (API parity features, 22), `tests/integration/components/eui-data-grid-test.gts` (semantics,
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

## API parity (branch `eui-wave/data-grid-api`)

Completed on top of the merged port (from `feat/eui-latest` 3268787c). The
former scope cuts are now ported:

| Upstream | Ember |
| --- | --- |
| `columnVisibility.canDragAndDropColumns` (`draggable_columns.tsx`) | `header-row.gts`/`header-cell.gts`: data header cells are `EuiDraggable` handles (`@customDragHandle="custom"`) in a horizontal `EuiDroppable`; pointer drag (pragmatic drag and drop) or Space, Left/Right, Space (Escape cancels); keys are stopped while lifted; Enter keeps opening the column actions (only Space lifts, like hello-pangea); focus follows the dropped column; the resizer sits next to the handle; drag icon, header shade/`noLeadingBorder`/`isKeyboardDragging` styles; the grid body auto-scrolls horizontally during pointer drags. |
| `renderCustomGridBody` (`data_grid_body_custom.tsx`) | `@renderCustomGridBody` component or `<:customGridBody>` block (`custom-body.gts`) receiving `Cell`, `visibleColumns`, `visibleRowData`, `setCustomGridBodyProps`, `gridWidth`, `headerRow`, `footerRow`. Column widths/row heights moved to `body-base.ts` (`EuiDataGridBodyBase`), shared by both bodies. |
| `renderCustomToolbar` | `@renderCustomToolbar` component or `<:customToolbar>` block (`toolbar.gts`) receiving `hasRoomForGridControls`, `columnControl`, `columnSortingControl`, `keyboardShortcutsControl`, `displayControl`, `fullScreenControl` as components (undefined when hidden) plus `additionalControls`. |
| ref API (`useImperativeGridRef`) | `@registerApi` (named like `EuiComboBox @registerApi`), called after render with `{ setIsFullScreen, setFocusedCell, openCellPopover, closeCellPopover, scrollTo, scrollToItem }`; data row indexes mapped through sorting/pagination (changing page), upstream's invalid-cell errors; `scrollTo`/`scrollToItem` port react-window's semantics (`align` auto/smart/center/end/start). Not yielded (the grid has no default block). |
| `rowHeightsOptions.scrollAnchorRow` | `body.gts` `compensateLayoutShift`: when the row layout changes, the first/middle visible row's top shift is added to `scrollTop`. |
| `OverrideCopiedTabularContent` / `tabularCopyMarkers` | `utils/data-grid/tabular-copy.ts` (`onTabularCopy`, registered on the document) + `copy-marker.gts`: tab/newline markers after header/body/footer cells, no-copy bounds around control columns and the focused cell's screen reader text, content bounds around the body. |
| `toolbarVisibility.showDisplaySelector.additionalDisplaySettings` / `customRender` | Components in the options; `customRender` receives `@densityControl`, `@rowHeightControl`, `@additionalDisplaySettings`, `@resetButton`. |
| `toolbarVisibility.additionalControls` (ReactNode or `{ left: { prepend, append } , right }`) | Components in the options (in addition to the existing blocks). |
| `renderCellPopover` props `cellActions`, `DefaultCellPopover`, `children` | `@cellActions`/`@DefaultCellPopover` (and in the `<:cellPopover>` block hash); the default popover uses the same `default-cell-popover.gts`; `children` is the component's default block. |
| `virtualizationOptions.className/style/initialScrollTop/initialScrollLeft` | Applied to the scrolling body element. |

Ember differences and decisions:

- Custom body `Cell`s can't reach the grid's `<:cell>`, `<:controlCell>` or
  `<:cellPopover>` blocks (blocks can't be curried): content comes from
  `@renderCellValue`/`rowCellRender` or the `Cell`'s own blocks (default,
  `<:controlCell>`, `<:cellPopover>`); `headerRow`/`footerRow` accept the
  `controlHeaderCell` / `footerCell`, `controlFooterCell`, `cellPopover`
  blocks. `Cell` also takes `@isExpandable`/`@renderCellValue` overrides
  and `...attributes`. Custom body cells are not absolutely positioned
  (height from the row height, `auto` for auto rows).
- `setCustomGridBodyProps` sets attributes, `className`, `style` (object)
  and `on*` function props as event listeners; upstream's `ref` is not
  supported (use the consumer's own elements/modifiers).
- `additionalControls` in the custom toolbar props is an Ember addition
  (the grid's control blocks can't be handed over).
- `scrollAnchorRow: 'center'` uses the real middle visible row; upstream
  compares `floor((stop - start) / 2)` with the row index itself, which
  only matches when scrolled to the top.
- `@registerApi` `setFocusedCell` forces the focus update (upstream skips
  it when the cell already is the grid's focused cell), so focus can be
  restored after a popover/modal closes. A cell asked to take focus while
  a popover holds it waits (up to 30 frames) for the popover to release
  focus.
- Grid arrow-key navigation ignores keys typed inside popovers (an
  editing form in the cell popover).
- `noCopyBoundsRegex` uses the `u` flag (lint: astral bound character).
- Header drag and drop: hello-pangea's live drag announcements and the
  `DragOverlay` portal are not ported (Ember's `EuiDraggable` has no
  announcements; pragmatic drag and drop uses the native drag image); a
  hidden instructions paragraph is referenced by every draggable header's
  `aria-describedby` instead (token
  `euiDataGridHeaderCell.dragInstructions`, Ember addition). Upstream's
  mousedown focus-trap workaround is unnecessary (native drags don't
  prevent `mousedown`).
- Header cells now re-register their focus callback when their column
  index changes (columns moved by drag, header actions or the selector).
- Tabular copy markers are `euiScreenReaderOnly` spans with
  `aria-hidden="true"` and `data-tabular-copy-marker`, so a cell's
  `textContent` includes them; tests read cell text from
  `[data-datagrid-cellcontent]` (the content element) instead.

## Not ported (intentional)

- `virtualizationOptions.direction`, `estimatedRowHeight`,
  `estimatedColumnWidth`, `itemKey`, `outerElementType`: react-window
  internals. The Ember body computes exact row/column offsets (no
  estimates), keys rows/cells by index and always renders a `div`; RTL
  `direction` is not supported by the Ember virtualizer (upstream's grid
  also forces `ltr` on react-window by default).
- Keyboard column resizing (upstream has none either).

## Checks (2026-10-13, `eui-wave/data-grid-api`, Chromium 130)

- `ember-tsc --noEmit`: pass.
- ESLint on all changed source and test files: pass.
- `node scripts/generate-eui-styles.mjs --check`: only the expected stale
  source-path comment in a worktree (no generator changes on this branch);
  parity `node --test scripts/eui-upstream-parity.test.mjs`: 349/349.
- `node scripts/generate-api-docs.mjs --check`: pass (basics page updated).
- Core Rollup build: pass; `package.json` app-js gained the new private
  parts (`body-base`, `copy-marker`, `custom-body`, `default-cell-popover`).
- Data grid tests (filter `EuiDataGrid`): 55/55 (new
  `eui-data-grid-api-test.gts`: header drag and drop, imperative API,
  custom toolbar/body, scroll anchoring, tabular copy, other upstream
  props, editing in the cell popover).
- Every data grid docs demo rendered (and the editable cells / imperative
  API demos exercised) through a temporary integration test (not
  committed).
- Full core suite: 1267/1267.

## Checks (2026-10-12, first port)

- Data grid tests 33/33, full core 1215/1215, parity 340/340.

## For the coordinator

- Site checks were not run (not allowed here). The 7 docs pages add a
  `data-grid` group under "Tabular content": update the side-nav count in
  `site/tests/acceptance/docs-test.ts` (109 → 116, or 117 if the group itself is
  a nav item).
- Generated files were regenerated in the worktree (stale source-path comments
  are expected; regenerate in main after merging).
- `eui-wave/data-grid-api` adds no docs pages (6 demos on the existing
  cells-and-popovers, toolbar and virtualization pages), so the side-nav
  count is unchanged.
