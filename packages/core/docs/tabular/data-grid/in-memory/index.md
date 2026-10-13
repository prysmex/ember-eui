---
title: Data grid in-memory
order: 9
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid in-memory"/>
<EuiSpacer @size="l" />

<EuiCallOut @title="What is the difference in the examples?" @iconType="info">
  <:body>
    These examples show the same grid built with the four available
    <EuiCode>@inMemory</EuiCode> settings. While they may look the same, look
    at the source to see how they require different levels of data management
    in regards to sorting and pagination.
  </:body>
</EuiCallOut>

<EuiSpacer />

<EuiText>

The grid has levels of **in-memory** settings that can be set. It is in the
consuming application's best interest to put as much of the data grid in
memory as performance allows. Try to use the highest level
`@inMemory={{hash level="sorting"}}` whenever possible. The following values
are available.

- **undefined (default)**: When not in use the grid will not autodetect
  schemas. The sorting and pagination is the responsibility of the
  consuming application.
- **enhancements**: Provides no in-memory operations. If set, the grid will
  try to autodetect schemas only based on the content currently available
  (the current page of data).
- **pagination**: Schema detection works as above and pagination is
  performed in-memory. The pagination callbacks are still triggered on user
  interactions, but the row updates are performed by the grid.
- **sorting (suggested)**: Schema detection and pagination are performed as
  above, and sorting is applied in-memory too. The `onSort` callback is
  still called and the application must own the column sort state, but data
  sorting is done by the grid based on the defined and/or detected schemas.

When enabled, **in-memory** renders cell data off-screen and uses those
values to detect schemas and perform sorting. This detaches the user
experience from the raw data; the data grid never has access to the backing
data, only what is rendered by the `<:cell>` block or `@renderCellValue`.
Detected schemas are `boolean`, `currency`, `datetime`, `numeric` and `json`;
`@schemaDetectors` adds your own (see
[schema & columns](/docs/core/docs/tabular/data-grid/schema-and-columns)).

## Sorting and pagination

`@sorting` (`{ columns, onSort }`) shows the "Sort fields" toolbar popover,
sorting arrows in the headers and the sort actions in each header's column
actions. `@pagination` (`{ pageIndex, pageSize, pageSizeOptions,
onChangePage, onChangeItemsPerPage }`) renders `EuiTablePagination` below
the grid; `pageSize` defaults to 10. Page Up / Page Down change pages from
the keyboard, and the grid's accessible name reports the page. Pagination
is hidden when all rows fit in the smallest page size.

</EuiText>

<EuiHorizontalRule />
