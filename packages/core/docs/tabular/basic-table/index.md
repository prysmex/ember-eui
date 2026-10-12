---
title: Basic table
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Basic table"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiBasicTable` renders a table from `@items` and `@columns`. It shows
the sorting, pagination and selection you pass and calls `@onChange` with
the new `{ page: { index, size }, sort: { field, direction } }` criteria,
so your component (or a server) decides what the next page holds. Use
[EuiInMemoryTable](../in-memory-table) to let the table sort, page and
search the items itself.

```hbs
<EuiBasicTable
  @items={{this.pageOfItems}}
  @itemId="id"
  @columns={{this.columns}}
  @pagination={{hash pageIndex=this.pageIndex pageSize=5 totalItemCount=this.total}}
  @sorting={{hash sort=this.sort}}
  @selection={{hash onSelectionChange=this.onSelectionChange}}
  @onChange={{this.onTableChange}}
/>
```

Columns are plain objects:

- **Field columns** `{ field, name, dataType, sortable, render, component,
  align, truncateText, mobileOptions, footer }` show `item[field]`
  (nested `a.b` paths work). `dataType` (`'string'`, `'number'`,
  `'boolean'`, `'date'`, `'auto'`) picks the default format and alignment;
  `render(value, item)` returns text (or `htmlSafe` HTML) and `component`
  renders an Ember component receiving `@item`, `@value` and `@column`.
- **Computed columns** `{ name, render(item) | component, sortable(item) }`.
- **Actions columns** `{ name, actions }`: each action is `{ name,
  description, onClick(item, event), href, type: 'icon', icon, color,
  available(item), enabled(item), isPrimary, showOnHover }` or a custom
  `{ component }` receiving `@item` and `@enabled`. With more than two
  actions they move to an "All actions" menu (primary ones stay inline on
  hover). Actions are disabled while rows are selected.

`@rowProps` and `@cellProps` (objects or functions of the item) add
attributes to rows and cells; a row `onClick` makes rows clickable.
Expanded rows come from `@itemIdToExpandedRowMap` and the
`<:expandedRow as |item itemId value|>` block.

### Ember differences

React nodes become text, `htmlSafe` strings or components: column
`render` returns text, `component` renders a component, `footer` is text
or a function returning text, `name` is text (`nameTooltip` adds an icon
tip). Custom actions are components. Sticky actions columns and the
copy-to-clipboard markers of upstream are not supported.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiBasicTable

A table built from `@items` and `@columns` (field, computed and actions
columns), with optional sorting, pagination, selection and expanded
rows. It renders the state you pass and calls `@onChange` with the new
`{ page, sort }` criteria; use `EuiInMemoryTable` to let the table own
that state.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@items` (required) | `T[]` |  | The rows' items. |
| `@columns` (required) | `Array<EuiBasicTableColumn<T>>` |  | The columns: field data (`{ field, name, dataType, render, component, sortable, … }`), computed (`{ render \| component, name }`) and actions (`{ actions, name }`). |
| `@itemId` | `ItemId<T>` |  | How to get a unique id of an item (a key or a function), for selection and expanded rows. |
| `@itemIdToExpandedRowMap` | `Record<string, unknown>` |  | Expanded rows by item id: a text, or any truthy value rendered by the `<:expandedRow>` block. |
| `@cellProps` | `EuiTableElementProps \| CellPropsCallback<T>` |  | Attributes of every row cell, or a function of the item and column. |
| `@rowProps` | `EuiTableElementProps \| RowPropsCallback<T>` |  | Attributes of every row (`onClick` makes rows clickable), or a function of the item. |
| `@error` | `string` |  | Error message shown instead of the rows. |
| `@tableCaption` | `string` | "Data table" | Describes the table for screen readers. |
| `@rowHeader` | `string` |  | The `field` of the column whose cells are the rows' headers (`<th scope="row">`). |
| `@loading` | `boolean` |  | Shows a loading line above the rows. |
| `@panelled` | `boolean` |  | Panelled look of the table and its pagination, for tables outside EUI containers (like `EuiPanel` or `EuiFlyout`). |
| `@noItemsMessage` | `string` | "No items found" | Message when there are no items. |
| `@onChange` |  |  | Called with the new `{ page, sort }` criteria when the user pages or sorts (required with `@pagination` or `@sorting`). |
| `@pagination` | `Pagination` |  | `{ pageIndex, pageSize, totalItemCount, pageSizeOptions, showPerPageOptions }`. |
| `@selection` | `EuiTableSelectionType<T>` |  | `{ onSelectionChange, selectable, selectableMessage, initialSelected, selected }`. |
| `@sorting` | `EuiTableSortingType<T>` |  | `{ sort: { field, direction }, enableAllColumns, readOnly }`. |
| `@tableLayout` | `'fixed' \| 'auto'` | `'fixed'` | `'fixed'` or `'auto'`. |
| `@compressed` | `boolean` |  | Smaller text and padding. |
| `@responsiveBreakpoint` | `TableResponsiveBreakpoint` | `'m'` | Breakpoint below which rows become cards (`true` always, `false` never). |
| `@hasBackground` | `boolean` | `true` | The table's plain background. |
| `@scrollableInline` | `boolean` |  | Lets the table scroll inline (upstream beta). |

| Block | Description |
| --- | --- |
| `<:expandedRow>` | Content of an expanded row; yields the item, its id and its map value. |
| `<:noItemsMessage>` | Content shown when there are no items (instead of `@noItemsMessage`). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
