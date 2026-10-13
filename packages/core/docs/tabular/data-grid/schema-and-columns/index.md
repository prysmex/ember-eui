---
title: Data grid schema & columns
order: 2
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid schema & columns"/>
<EuiSpacer @size="l" />

<EuiText>

## Schemas

Schemas are data types you pass to grid columns to affect how the columns
and expansion popovers render. Schemas also allow you to define individual
sorting comparators so that sorts can do more than just A-Z comparisons. By
default, **EuiDataGrid** ships with a few built-in schemas for `numeric`,
`currency`, `datetime`, `boolean` and `json` data. When the `@inMemory`
argument is in use it will automatically try to figure out the best schema
based on the `@inMemory={{hash level=…}}` you set, but this will come with
the caveat that you will need to provide and manage sorting outside the
component. In general we recommend passing schema information to your
columns instead of using auto-detection when you have that knowledge of
your data available during ingestion.

A schema picks the sort comparator, the sort labels ("Low-High"), the
alignment (`numeric` and `currency` cells are right aligned) and the
expansion popover (JSON is pretty printed). Explicit `schema` values on
columns always win over detection. See
[in-memory](/docs/core/docs/tabular/data-grid/in-memory) for schema
detection and sorting.

## Columns

Columns are **EuiDataGridColumn** objects: an `id`, plus optional
`displayAsText` (the header text), `display` (a component rendered as the
header), `schema`, `initialWidth`, `isResizable`, `isExpandable`,
`isSortable`, `defaultSortDirection`, `actions`, `cellActions` and
`visibleCellActions`. The examples below show column widths, column
actions, draggable columns, control columns and the footer row.

</EuiText>

<EuiHorizontalRule />
