---
title: Data grid
order: 1
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiDataGrid` displays tabular data in a virtualized, keyboard-navigable
grid. Describe the columns with `@columns`, give the number of rows with
`@rowCount` and render each cell, either with the `<:cell>` block or with a
`@renderCellValue` component. The grid only asks for the cells that are on
screen, so the data can live anywhere (an array, a store, a server).

```hbs
<EuiDataGrid
  aria-label="People"
  @columns={{this.columns}}
  @rowCount={{this.people.length}}
>
  <:cell as |cell|>
    {{get (get this.people cell.rowIndex) cell.columnId}}
  </:cell>
</EuiDataGrid>
```

Each cell receives `rowIndex` (the row in your data, even when the grid
is sorted or paginated), `colIndex`, `columnId`, `schema`, `isDetails`
(`true` inside the expansion popover), `isExpanded`, `isExpandable`,
`cellContext` and `setCellProps`, which lets a cell set its own `className`,
`style`, `isExpandable` or attributes.

The grid follows upstream EUI's accessibility model: a single cell is
tabbable, arrows/Home/End/Page Up/Page Down/Ctrl+Home/Ctrl+End move between
cells, Enter or F2 opens a cell's details and Escape closes them. Name the
grid with `aria-label` or `aria-labelledby`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiDataGrid

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@columns` (required) | `EuiDataGridColumn[]` |  | Column definitions (`id`, `displayAsText`, `schema`, `initialWidth`, `actions`, `cellActions`, …). |
| `@columnVisibility` | `EuiDataGridColumnVisibility` |  | Controlled column order/visibility. Optional in Ember: without it the grid keeps its own state, starting with every column visible. |
| `@rowCount` | `number` |  | Number of rows in the data (not needed with `@rowTree` or `@grouping.rows`). |
| `@rowTree` | `EuiDataGridRowTree` |  | Ember EUI extension: nested rows. The rows array (nested through each row's `children`, or flat with `parentId`), or options `{ rows, getChildren, getParentId, getRowId, expandedRowIds, defaultExpandedRowIds, onExpandedChange, toggleColumnId }`. |
| `@grouping` | `EuiDataGridGrouping` |  | Ember EUI extension: groups rows by column values (`{ groupBy, getValue, rows, expandedGroupIds, defaultExpandedGroupIds, onExpandedChange, renderGroupCell, toggleColumnId }`). |
| `@renderCellValue` |  |  | Component rendering a cell's value; receives `@rowIndex`, `@colIndex`, `@columnId`, `@isDetails`, `@isExpanded`, `@isExpandable`, `@setCellProps`, `@schema`, `@cellContext` and (with `@rowTree` or `@grouping.rows`) `@row`. Or use the `<:cell>` block. |
| `@cellContext` | `Record<string, unknown>` |  | Extra data passed to every cell renderer as `@cellContext`. |
| `@renderCellPopover` |  |  | Component rendering the expansion popover (its default block renders the cell value with `@isDetails`); or use the `<:cellPopover>` block. |
| `@renderFooterCellValue` |  |  | Component rendering footer cells; or use the `<:footerCell>` block. |
| `@renderCustomGridBody` |  |  | Escape hatch replacing the virtualized body: a component receiving `@Cell`, `@visibleColumns`, `@visibleRowData`, `@setCustomGridBodyProps`, `@gridWidth`, `@headerRow` and `@footerRow`; or use the `<:customGridBody>` block. Give cell content with `@renderCellValue` or the `Cell`'s own block. |
| `@renderCustomToolbar` |  |  | Custom toolbar layout: a component receiving the toolbar controls (`@hasRoomForGridControls`, `@columnControl`, `@columnSortingControl`, `@keyboardShortcutsControl`, `@displayControl`, `@fullScreenControl`, `@additionalControls`); or use the `<:customToolbar>` block. |
| `@leadingControlColumns` | `EuiDataGridControlColumn[]` |  | Columns before the data columns (e.g. row selection). |
| `@trailingControlColumns` | `EuiDataGridControlColumn[]` |  | Columns after the data columns (e.g. row actions). |
| `@schemaDetectors` | `EuiDataGridSchemaDetector[]` |  | Extra schema detectors, appended to the defaults. |
| `@gridStyle` | `EuiDataGridStyle` |  | Borders, header/footer styles, stripes, row hover, density. |
| `@rowHeightsOptions` | `EuiDataGridRowHeightsOptions` |  | Default and per-row heights (`'auto'`, a number, `{ lineCount }` or `{ height }`). |
| `@toolbarVisibility` | `boolean \| EuiDataGridToolBarVisibilityOptions` | `true` | `false` hides the toolbar, or an object toggling each control. |
| `@headerVisibility` | `boolean` | `true` | `false` hides the header row. |
| `@pagination` | `EuiDataGridPaginationProps` |  | Pagination state and callbacks; rendered with `EuiTablePagination`. |
| `@sorting` | `EuiDataGridSorting` |  | Sorted columns and `onSort`. |
| `@inMemory` | `EuiDataGridInMemory` |  | Let the grid read rendered values to detect schemas and sort in memory. |
| `@onColumnResize` |  |  | Called after a column is resized. |
| `@minSizeForControls` | `number` | 479 | Below this width only the right toolbar controls show. |
| `@height` | `string \| number` |  | Grid height (CSS length or px number). Without it the grid grows with its rows. |
| `@width` | `string \| number` |  | Grid width (CSS length or px number). |
| `@virtualizationOptions` | `EuiDataGridVirtualizationOptions` |  | Overscan counts and render/scroll callbacks of the virtualized body. |
| `@onFullScreenChange` | `(isFullScreen: boolean) => void` |  | Called when fullscreen mode is entered or left. |
| `@registerApi` | `(api: EuiDataGridRefProps) => void` |  | Called after render with the grid's imperative API (upstream's `ref`): `setIsFullScreen`, `setFocusedCell`, `openCellPopover`, `closeCellPopover`, `scrollTo` and `scrollToItem`. |
| `@ariaLabel` | `string` |  | Accessible name of the grid (same as the `aria-label` attribute). |
| `@ariaLabelledBy` | `string` |  | Id(s) labelling the grid (same as the `aria-labelledby` attribute). |
| `@css` | `EuiCss` |  | Extra styles composed last into the grid class. |

| Block | Description |
| --- | --- |
| `<:cell>` | Cell content when `@renderCellValue` is not given. |
| `<:cellPopover>` | Expansion popover content when `@renderCellPopover` is not given. |
| `<:footerCell>` | Footer cell content when `@renderFooterCellValue` is not given. |
| `<:controlHeaderCell>` | Header of a control column without `headerCellRender`. |
| `<:controlCell>` | Body cell of a control column without `rowCellRender`. |
| `<:controlFooterCell>` | Footer cell of a control column without `footerCellRender`. |
| `<:leftControlsPrepend>` | Toolbar controls before the column/sort controls. |
| `<:leftControlsAppend>` | Toolbar controls after the column/sort controls. |
| `<:rightControls>` | Toolbar controls before the right icon buttons. |
| `<:customToolbar>` | Custom toolbar (like `@renderCustomToolbar`), yielding the toolbar controls. |
| `<:customGridBody>` | Custom grid body (like `@renderCustomGridBody`). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiDataGridToolbarControl

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@iconType` |  |  | Icon before the label. |
| `@badgeContent` | `string \| number` |  | Count shown in a badge after the label (e.g. `5` or `'3/10'`). |
| `@isDisabled` | `boolean` |  | Disables the button. |
| `@css` | `EuiCss` |  | Extra styles composed last into the button class. |

| Block | Description |
| --- | --- |
| default block | The control's label. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

</EuiText>
<!-- api:end -->
