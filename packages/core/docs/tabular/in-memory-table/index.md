---
title: In-memory table
order: 2
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="In-memory table"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiInMemoryTable` is a higher level wrapper around
[EuiBasicTable](../basic-table) that handles selection, search, sorting and
pagination in memory for you, within certain preset configurations. It
takes the full set of data, which must include all possible items, and the
basic table's arguments plus:

- `@search`: `true`, or `EuiSearchBar` options (`box`, `filters`,
  `defaultQuery`, a controlled `query`, `onChange`). `box: { schema: true }`
  builds a strict schema from the columns' `field` and `dataType`. A
  `search.onChange` must return `true` to keep filtering in memory.
- `@searchFormat="text"`: a plain text search (no syntax or filters),
  for data with quotes, parentheses or colons.
- `@sorting`: `true`, or `{ sort: { field, direction } }` for the initial
  sort; `@allowNeutralSort={{false}}` removes the unsorted step.
- `@pagination`: `true`, or `{ pageSizeOptions, initialPageSize,
  initialPageIndex }` (`pageIndex`/`pageSize` control them).
- `@onTableChange`: informational `{ page, sort }` callback.
- `@executeQueryOptions`: `{ defaultFields, isClauseMatcher, enabled }`.

New `@items` (e.g. from a server search) go back to the first page unless
the pagination is controlled. Without `pageSizeOptions` or a page size,
the app's page size defaults apply (see
[EuiTable's page size defaults](../table)).

The table sorts a column by its `field`, or by its `name` for computed
columns, so keep computed column names stable.

### Ember differences

The search bar's tools and hint, and content between the search bar and
the table (upstream `childrenBetween`), are the `<:toolsLeft>`,
`<:toolsRight>`, `<:hint>` and `<:childrenBetween>` blocks; a custom
"no items" message is the `<:noItemsMessage>` block. Upstream's
`useEuiBasicTablePanelProps` hook is a plain function returning `{ css,
className }` (pass them to any component's `@css` and `class`), and
`<:childrenBetween>` yields an `EuiBasicTablePanel` component built on it
(see [Custom panels](#custom-panels)).

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiInMemoryTable

An `EuiBasicTable` that owns its state: it filters `@items` with an
optional `EuiSearchBar`, sorts them by the clicked column and pages
them in memory.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@search` | `Search` |  | Search bar: `true` for defaults, or `EuiSearchBar` args (`box`, `filters`, `query`, `defaultQuery`, `onChange`, …). `box.schema: true` derives the schema from the columns. |
| `@searchFormat` | `'eql' \| 'text'` | `'eql'` | `'eql'` (search syntax and filters) or `'text'` (plain text search, filters ignored). |
| `@pagination` | `boolean \| PaginationOptions` |  | `true` or `{ pageSizeOptions, initialPageIndex, initialPageSize, pageIndex, pageSize, showPerPageOptions }`. |
| `@sorting` | `Sorting` |  | `true`, or `{ sort: { field, direction } }` for the initial sort. |
| `@allowNeutralSort` | `boolean` | `true` | Clicking a descending column unsorts it. |
| `@onTableChange` | `(nextValues: Criteria<T>) => void` |  | Informational: called with the new `{ page, sort }` criteria (the table already manages that state). |
| `@executeQueryOptions` |  |  | Options of the in-memory query execution. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiBasicTablePanel

A `<div>` styled with `useEuiBasicTablePanelProps()`: a supporting
panel for a panelled `EuiBasicTable` or `EuiInMemoryTable`, e.g. in the
in-memory table's `<:childrenBetween>` block. Consecutive panels join,
and the table below loses its top radius. Ember convenience over
upstream's hook.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@css` | `EuiCss` |  | Extra styles composed last into the panel's class (like upstream's `css` prop), e.g. padding. |

| Block | Description |
| --- | --- |
| default block | The panel's content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
