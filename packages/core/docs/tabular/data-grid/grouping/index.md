---
title: Data grid nested rows and grouping
order: 8
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid nested rows and grouping"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="Ember EUI extension" @iconType="info">
  Upstream EUI's data grid has no nested rows (tree data) or row grouping:
  <code>@rowTree</code> and <code>@grouping</code> are Ember EUI additions.
  Both are opt-in. Without them the grid behaves and renders exactly like
  upstream's <code>EuiDataGrid</code>.
</EuiCallOut>

<EuiSpacer />

<EuiText>

`EuiDataGrid` can show hierarchical rows: folders and files, managers and
reports, tasks and subtasks. Rows with children get a toggle and their
children are indented under them. It can also **group** flat rows by column
values (country, then city), with a group row per value showing a row count
or your own aggregates.

This guide spans several pages:

- **This page:** quick start, data shapes, how renderers get rows, the API
  reference and limitations.
- [Tree expansion](/docs/core/docs/tabular/data-grid/tree-expansion): expanded state (uncontrolled,
  defaults, controlled, persisted), the toggle column and the imperative API.
- [Row grouping](/docs/core/docs/tabular/data-grid/group-by): `@grouping`, group ids, group cells with totals,
  and grouping trees.
- [Trees with other features](/docs/core/docs/tabular/data-grid/tree-features): sorting, pagination, row
  heights, virtualization, control columns, popovers, copy, keyboard and
  accessibility.
- [Tree recipes](/docs/core/docs/tabular/data-grid/tree-recipes): lazy loading, a file explorer, an org
  chart, filtering a tree.

## Quick start

Pass your rows as `@rowTree`. A row's `children` array holds its child rows,
and that is all the configuration needed. You don't pass `@rowCount`: the
grid counts the rows itself. Render cells from the row object, which the
grid hands to every renderer as `row` (see *Renderers* below):

```hbs
<EuiDataGrid aria-label="Files" @columns={{this.columns}} @rowTree={{this.files}}>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

Click a toggle, or focus a cell in the first column and use the keyboard:
ArrowRight expands, ArrowLeft collapses or goes to the parent row, and
Space toggles. The first demo below is this snippet running.

## Data shapes

The grid accepts three shapes:

1. **Nested rows** (the default): each row may have a `children` array.
   Child rows can have their own `children`, to any depth.
2. **Flat rows:** when no row has a `children` array, each row's `parentId`
   (or `parent`) names another row's `id`. Rows without a parent, or whose
   parent doesn't exist, are root rows. Cycles are broken (the row that
   closes the loop becomes a root).
3. **Anything else**, through accessors: `@rowTree={{hash rows=…
   getChildren=… getParentId=… getRowId=…}}`. Passing `getChildren` selects
   the nested form and passing `getParentId` selects the flat form.

Each row needs an id, which the grid uses for the expanded state. By default
this is `row.id`, falling back to the row's index. Give your rows stable ids
when they can change (lazy loading, filtering, live data). Otherwise an
expanded row's id moves to another row when rows are inserted before it.

```js
// flat rows that call their parent "manager" and their id "email"
rowTree = {
  rows: this.people,
  getRowId: (person) => person.email,
  getParentId: (person) => person.manager
};
```

## Renderers: `@row` and `@rowIndex`

The grid itself never sees your data, only indexes. With `@rowTree` (or
`@grouping.rows`) it does know your row objects, so every cell renderer
also receives the row:

| Renderer | Row object | Row index |
| --- | --- | --- |
| `<:cell as \|cell\|>` block | `cell.row` | `cell.rowIndex` |
| `@renderCellValue` component | `@row` | `@rowIndex` |
| `@renderCellPopover` component, `<:cellPopover>` block | `@row` / `row` | `@rowIndex` / `rowIndex` |
| `@inMemory` (the off-screen renderer reading values) | `@row` | `@rowIndex` |
| control column `rowCellRender` / `<:controlCell>` | `@row` / `row` | `@rowIndex` / `rowIndex` |

Why both? `@rowIndex` is the grid's *data row index*. For **flat rows** it is
the row's index in your array, so `this.rows[rowIndex]` keeps working, as in
any data grid. For **nested rows** there is no single array to index into:
the grid numbers every row in pre-order (a parent, then its children, then
the next root row), regardless of what is expanded. `@row` saves you from
rebuilding that numbering. Use `@rowIndex` for per-row grid options
(`rowHeightsOptions.rowHeights`, `gridStyle.rowClasses`) and for the
imperative API, which address rows by data row index.

Without `@rowTree`/`@grouping.rows`, `row` is `undefined`, as before.

## API reference

### `@rowTree`

Either the rows array itself or an options object:

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `rows` | `T[]` | (required) | Nested or flat rows. |
| `getChildren` | `(row) => T[] \| null \| undefined` | `row.children` when it is an array | Child rows (selects the nested form). |
| `getParentId` | `(row) => string \| number \| null \| undefined` | `row.parentId ?? row.parent` | Parent row id (selects the flat form). |
| `getRowId` | `(row, rowIndex) => string \| number \| null \| undefined` | `row.id`, else the row index | Row id, used in the expanded ids. |
| `hasChildren` | `(row) => boolean` | `row.hasChildren === true` | Shows a toggle before the children are loaded ([lazy loading](/docs/core/docs/tabular/data-grid/tree-recipes)). |
| `expandedRowIds` | `string[]` | (internal state) | Controlled expanded row ids. |
| `defaultExpandedRowIds` | `string[] \| 'all'` | `[]` | Initially expanded rows when uncontrolled. |
| `onExpandedChange` | `(ids: string[]) => void` |  | Called with the new expanded ids whenever a row expands or collapses. |
| `toggleColumnId` | `string` | first data column | Column holding the indentation and the toggle. |

### `@grouping`

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `groupBy` | `string[]` | (required) | Column ids to group by, outermost first. An empty array turns grouping off. |
| `getValue` | `(rowIndex, columnId, row) => unknown` | `row[columnId]` | Raw value to group by. Required when the grid doesn't know the rows. |
| `rows` | `T[]` |  | Flat rows: renderers get `@row`, and `@rowCount` is not needed. |
| `expandedGroupIds` | `string[]` | (internal state) | Controlled expanded group ids (see [group ids](/docs/core/docs/tabular/data-grid/group-by)). |
| `defaultExpandedGroupIds` | `string[] \| 'all'` | `[]` | Initially expanded groups when uncontrolled. |
| `onExpandedChange` | `(ids: string[]) => void` |  | Called with the new expanded group ids. |
| `renderGroupCell` | component | value and count | Rendered in every data cell of a group row. |
| `toggleColumnId` | `string` | first data column | Column holding the indentation, toggle and group label. |

`renderGroupCell` receives `@group` (`{ columnId, value, count,
rowIndices }`), `@groupId`, `@columnId`, `@colIndex`, `@isToggleCell`,
`@isExpanded` and `@depth`.

### Imperative API additions

With either argument, the object passed to `@registerApi` also has
`expandRow(id)`, `collapseRow(id)`, `expandAll()` and `collapseAll()`. Ids
are row ids or group ids. `setFocusedCell` and `openCellPopover` (data row
index) expand the target row's collapsed ancestors first.

### TypeScript

The types are exported from `@ember-eui/core/components/eui-data-grid`:

```ts
import type {
  EuiDataGridRowTree, // T[] | EuiDataGridRowTreeOptions<T>
  EuiDataGridRowTreeOptions,
  EuiDataGridGrouping,
  EuiDataGridGroupCellProps,
  EuiDataGridCellValueElementProps // has `row?: any`
} from '@ember-eui/core/components/eui-data-grid';

interface EuiDataGridRowTreeOptions<T = any> {
  rows: T[];
  getChildren?: (row: T) => T[] | null | undefined;
  getParentId?: (row: T) => string | number | null | undefined;
  getRowId?: (row: T, rowIndex: number) => string | number | null | undefined;
  hasChildren?: (row: T) => boolean;
  expandedRowIds?: string[];
  defaultExpandedRowIds?: string[] | 'all';
  onExpandedChange?: (expandedRowIds: string[]) => void;
  toggleColumnId?: string;
}

interface EuiDataGridGrouping<T = any> {
  groupBy: string[];
  getValue?: (rowIndex: number, columnId: string, row: T | undefined) => unknown;
  rows?: T[];
  expandedGroupIds?: string[];
  defaultExpandedGroupIds?: string[] | 'all';
  onExpandedChange?: (expandedGroupIds: string[]) => void;
  renderGroupCell?: ComponentLike<{ Args: EuiDataGridGroupCellProps }>;
  toggleColumnId?: string;
}

interface EuiDataGridGroupCellProps {
  group: { columnId: string; value: unknown; count: number; rowIndices: number[] };
  groupId: string;
  columnId: string;
  colIndex: number;
  isToggleCell: boolean;
  isExpanded: boolean;
  depth: number;
}
```

## Limitations

- **Renderers don't receive the tree state.** A cell doesn't get its
  row's depth or expanded state. If you need them (e.g. an open folder
  icon), control the expanded ids, as in the file explorer recipe.
- **Group rows have no data.** They use negative row indexes (`-1`, `-2`, …),
  are not expandable (no popover or cell actions), and render nothing in
  control columns. There is no built-in "select the whole group".
- **No built-in aggregates.** `renderGroupCell` gets each group's
  `rowIndices`; compute totals there.
- **Lazy loading is up to you.** The grid calls `onExpandedChange`; you load
  the children and update `rows` (see the recipe).
- **The toggle column wants inline content.** Block elements in that
  column's cells wrap below the toggle.
- **Custom grid bodies** (`@renderCustomGridBody`) show the toggle in their
  cells, but the rows they render carry no tree ARIA attributes.
- **Sorting is per level.** In-memory sorting reorders siblings. Server-side
  sorting means you send the rows in the order you want.

</EuiText>

<EuiHorizontalRule />
