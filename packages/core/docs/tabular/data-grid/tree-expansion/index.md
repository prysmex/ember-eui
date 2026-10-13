---
title: Data grid tree expansion
order: 11
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid tree expansion"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="Ember EUI extension" @iconType="info">
  Part of the nested rows and grouping guide. See the
  <a href="/docs/core/docs/tabular/data-grid/grouping">overview</a>.
</EuiCallOut>

<EuiSpacer />

<EuiText>

## Uncontrolled (the default)

By default the grid keeps the expanded ids itself and every row starts
collapsed. `defaultExpandedRowIds` sets the initial state: `'all'`, or a list
of row ids. It is only read until the user first toggles a row. For groups,
use `defaultExpandedGroupIds` in `@grouping`.

```hbs
<EuiDataGrid @rowTree={{hash rows=this.rows defaultExpandedRowIds="all"}} … />
<EuiDataGrid @rowTree={{hash rows=this.rows defaultExpandedRowIds=(array "src" "src/components")}} … />
```

## Controlled

Pass `expandedRowIds` and update it in `onExpandedChange`. The grid then
shows exactly the ids you pass. `onExpandedChange(ids)` receives the full new
list (not a diff), whether a click, a key, or an API call made the change. It
is called in uncontrolled mode too, which is handy for logging or persisting
the state without owning it.

```js
@tracked expandedRowIds = [];
onExpandedChange = (ids) => (this.expandedRowIds = ids);
```

```hbs
<EuiDataGrid
  @rowTree={{hash rows=this.rows expandedRowIds=this.expandedRowIds onExpandedChange=this.onExpandedChange}}
  …
/>
```

Ids are strings: `row.id` (stringified) or the result of `getRowId`. A row
whose id you list but that has no children is ignored. Ids of rows that no
longer exist are harmless too.

## Persisting the state

Controlled ids can be saved anywhere: a query param, a service, or
`localStorage` as in the second demo. Use stable row ids (not the default
index fallback), so saved ids still point at the same rows later.

## The toggle column

The indentation and the toggle go in the first data column. `toggleColumnId`
picks another one, e.g. when the first column is narrow or holds an icon.
Only that column's cells handle the tree keys.

## Imperative API

`@registerApi` gets `expandRow(id)`, `collapseRow(id)`, `expandAll()` and
`collapseAll()` besides upstream's methods. They go through the same path
as clicks: `onExpandedChange` is called, and with controlled ids nothing
changes until you apply them. `setFocusedCell({ rowIndex, colIndex })` and
`openCellPopover` take a *data* row index and expand its collapsed
ancestors first, changing page if needed. `scrollToItem({ rowIndex })`
takes a *visible* row index (as upstream: the position in the grid).

</EuiText>

<EuiHorizontalRule />
