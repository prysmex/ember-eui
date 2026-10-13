---
title: Data grid nested rows and grouping
order: 8
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid nested rows and grouping"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="Ember EUI extension" @iconType="info">
  Upstream EUI's data grid has no nested rows or row grouping: <code>@rowTree</code>
  and <code>@grouping</code> are Ember EUI additions. Without them the grid
  behaves and renders exactly like upstream.
</EuiCallOut>

<EuiSpacer />

<EuiText>

## Nested rows

Pass your rows as `@rowTree`. A row's `children` array holds its child rows;
no other configuration is needed. Cell renderers receive the row object as
`@row` (or `row` in the `<:cell>` block hash), so nested data needs no
index lookups. `@rowCount` is not needed.

Flat rows work too: when no row has a `children` array, each row's
`parentId` (or `parent`) refers to another row's `id`. In this form
`@rowIndex` is the row's index in your array.

For other shapes pass options, `@rowTree={{hash rows=… getChildren=…}}`:

| Option | Default | Description |
| --- | --- | --- |
| `rows` | (required) | Nested or flat rows. |
| `getChildren(row)` | `row.children` | Child rows (nested form). |
| `getParentId(row)` | `row.parentId ?? row.parent` | Parent row id (flat form). |
| `getRowId(row, rowIndex)` | `row.id`, else the index | Row id, used for the expanded ids. |
| `expandedRowIds` | (internal state) | Controlled expanded row ids. |
| `defaultExpandedRowIds` | `[]` | Initially expanded ids when uncontrolled, or `'all'`. |
| `onExpandedChange(ids)` |  | Called with the new expanded ids when a row is toggled. |
| `toggleColumnId` | first data column | Column holding the indentation and the toggle. |

## Grouping

`@grouping={{hash groupBy=(array "country" "city")}}` groups rows by column
values, outermost first. Group rows show the toggle, the value and the row
count in the toggle column. The grid reads values with `getValue(rowIndex,
columnId, row)`, or `row[columnId]` when it knows the rows (`rows` in the
grouping options, or `@rowTree`). With `@rowTree`, root rows are grouped and
keep their children.

| Option | Default | Description |
| --- | --- | --- |
| `groupBy` | (required) | Column ids to group by. |
| `getValue(rowIndex, columnId, row)` | `row[columnId]` | Raw value to group by. |
| `rows` |  | Flat rows (renderers get `@row`; `@rowCount` is then not needed). |
| `expandedGroupIds` / `defaultExpandedGroupIds` / `onExpandedChange` |  | Like the row tree options, for group ids. |
| `renderGroupCell` | value and count | Component rendered in every data cell of a group row, with `@group` (`columnId`, `value`, `count`, `rowIndices`), `@groupId`, `@columnId`, `@colIndex`, `@isToggleCell`, `@isExpanded` and `@depth`: use it for labels or per-column aggregates. |
| `toggleColumnId` | first data column | Column holding the indentation and the toggle. |

Group rows have negative row indexes (`-1`, `-2`, …), are not expandable
and render no control column content; the other cells are empty unless
`renderGroupCell` fills them.

```gts
const totalSales = (rowIndices: number[]) =>
  rowIndices.reduce((total, rowIndex) => total + rows[rowIndex].sales, 0);

const GroupCell = <template>
  {{#if @isToggleCell}}
    {{@group.value}} ({{@group.count}})
  {{else if (eq @columnId "sales")}}
    Total: {{totalSales @group.rowIndices}}
  {{/if}}
</template>;

<EuiDataGrid
  @columns={{columns}}
  @grouping={{hash groupBy=(array "country") rows=rows renderGroupCell=GroupCell}}
/>
```

## Behavior

- The grid renders only the visible rows: `aria-rowcount`, pagination and
  keyboard navigation count rows, not data rows. Sorting reorders siblings
  (in-memory sorting, or your own order); groups are ordered by value, in
  the direction of their column when it is sorted.
- Keyboard: in the toggle cell **Space** toggles the row. **Enter** toggles
  group rows and rows whose toggle column is not expandable; otherwise it
  keeps opening the cell popover. Arrow keys keep moving between cells
  (unlike a WAI-ARIA tree, the grid focuses cells, not rows).
- ARIA: the grid becomes `role="treegrid"` and rows get `aria-level`,
  `aria-setsize`, `aria-posinset` and, when they have children,
  `aria-expanded`.
- `@registerApi` adds `expandRow(id)`, `collapseRow(id)`, `expandAll()` and
  `collapseAll()`; `setFocusedCell`/`openCellPopover` expand the ancestors
  of a collapsed row first.
- Render inline content in the toggle column: block elements wrap below the
  toggle. Changing pages after collapsing rows is up to your `onChangePage`
  state, like any change of the row count.
- Custom grid bodies (`@renderCustomGridBody`) get the toggle in their cells
  but their own rows carry no tree ARIA.

</EuiText>

<EuiHorizontalRule />
