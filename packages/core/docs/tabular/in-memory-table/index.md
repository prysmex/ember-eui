---
title: In-memory table
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="In-memory table"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiInMemoryTable` is an [EuiBasicTable](../basic-table) that owns its
state: give it all the `@items` and it searches, sorts and pages them in
memory. It takes the basic table's arguments plus:

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

New `@items` (e.g. from a server search) go back to the first page.

### Ember differences

The search bar's tools and hint, and content between the search bar and
the table (upstream `childrenBetween`), are the `<:toolsLeft>`,
`<:toolsRight>`, `<:hint>` and `<:childrenBetween>` blocks.

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

</EuiText>
<!-- api:end -->
