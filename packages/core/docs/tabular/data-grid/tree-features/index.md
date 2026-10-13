---
title: Data grid nested rows with other features
order: 11
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid nested rows with other features"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="Ember EUI extension" @iconType="info">
  Part of the nested rows and grouping guide. See the
  <a href="/docs/core/docs/tabular/data-grid/grouping">overview</a>.
</EuiCallOut>

<EuiSpacer />

<EuiText>

The grid renders the **visible rows**: root rows plus the children of
expanded rows, in tree order. Everything that counts rows works on that
list: `aria-rowcount`, pagination, virtualization, keyboard navigation
(ArrowDown goes to the next visible row, whatever its level).

## Sorting

- **Siblings are sorted, the hierarchy stays.** With in-memory sorting
  (`@inMemory={{hash level="sorting"}}`), each parent's children are
  reordered and stay under their parent. Rows never move to another level.
- **Groups are ordered by value**, ascending by default. When `@sorting`
  includes the grouped column, its groups follow that direction.
- **Server-side sorting**: without `@inMemory` the grid keeps your row
  order. Sort each `children` array (or the flat list) yourself in `onSort`.

## Pagination

Pages hold visible rows: expanding a row pushes rows to the next pages and
changes the page count. Children can land on a different page than their
parent. ArrowLeft from such a child goes to the parent and changes page.
When collapsing leaves `pageIndex` past the last page (collapse all on the
last page, or a smaller tree), the grid calls `onChangePage` with the last
page, so your `pageIndex` stays valid. You don't need to clamp it.
Reset `pageIndex` yourself when the data changes in a way that makes the
current page meaningless (switching the grouping, a new filter).

## Row heights

`rowHeightsOptions` works as usual. `defaultHeight: 'auto'` measures each
row, and the measurement stays with the row when expanding or collapsing
moves it. `rowHeights` and `gridStyle.rowClasses` are keyed by **data row
index** (`@rowIndex`), so they follow the row wherever it moves. Group
rows use the default height.

## Virtualization and performance

Only the rows in view (plus overscan) are rendered, so large expanded
trees scroll as smoothly as flat grids. Expanding or collapsing rebuilds
the visible list from the tree, which is cheap. Measured in Chromium (a
tree of 10 children per row, three levels, all expanded):

| Rows | Build the tree | Rebuild visible rows (toggle) | Sort | Group (100 groups) |
| --- | --- | --- | --- | --- |
| 9,990 | 1.0 ms | 0.7 ms | 1.5 ms | 1.4 ms |
| 49,950 | 5.5 ms | 1.3 ms | 2.7 ms | 5.2 ms |

A new `rows` array rebuilds the tree, so keep the array stable between
renders (a tracked property, not a getter building a new array each time).
With `@inMemory`, the off-screen renderer still renders every data row of
every level to read its values. Avoid it for very large trees and sort on
the server.

## Control columns and selection

Leading and trailing control columns render in data rows with `rowIndex`
and `row`, as in flat grids. They render **nothing in group rows**: group
rows have no data row index. Select a parent and its descendants by walking
`row.children` yourself, as the selection demo does.

## Cell popovers, cell actions and copy

Cells of tree rows expand into popovers and show cell actions as usual. The
popover renderers get `@row`. In the toggle column, Enter opens the popover
when the column is expandable. Group rows are not expandable: no popover
and no cell actions. Copying a cell copies its text. In group rows that is
the label and count, or your `renderGroupCell` text. The toggle button
contributes nothing.

## Keyboard

The tree keys work in the **toggle cell**, the cell with the arrow (or the
indentation, for leaf rows). Elsewhere the grid navigates as usual.

| Key | In the toggle cell |
| --- | --- |
| ArrowRight | Expands a collapsed row. On an expanded row or a leaf, moves to the next cell. |
| ArrowLeft | Collapses an expanded row. On a collapsed row or a leaf, moves to the parent row's toggle cell. On a top-level row, moves left (into a control column, if any). |
| Space | Toggles the row. |
| Enter | Opens the cell popover when the column is expandable. Otherwise toggles the row, unless the cell has interactive content (then Enter enters the cell, as in any grid). |

The tree keys are ignored while the cell's popover is open and while focus
is inside the cell's content (an entered cell, an input you are editing).
The toggle button itself is not in the tab order. Clicking it toggles, and
the cell takes focus.

## Accessibility

- The grid gets `role="treegrid"` (instead of `grid`) and
  `aria-rowcount` counts the visible rows.
- Every row has `aria-level` (1 for roots), `aria-setsize` and
  `aria-posinset` (its position among its siblings), and rows with children
  have `aria-expanded`.
- The toggle button is labelled "Expand row" / "Collapse row" (i18n tokens
  `euiDataGridRowToggle.expand` / `.collapse`) and has `aria-expanded`.
  Empty group values read "(empty)" (`euiDataGridGroupRow.emptyValue`).
- Group rows have the `euiDataGridRow--group` class for styling.

</EuiText>

<EuiHorizontalRule />
