---
title: Data grid schema and sorting
order: 2
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid schema and sorting"/>
<EuiSpacer @size="l" />

<EuiText>

Pass `@sorting` (`{ columns, onSort }`) to show the "Sort fields" toolbar
popover, sorting arrows in the headers and the sort actions in each header's
column actions. The grid does not sort your data by itself: either sort it
in `onSort`, or let the grid read the rendered values with
`@inMemory={{hash level="sorting"}}`.

With `@inMemory`, the grid also detects each column's schema (`boolean`,
`currency`, `datetime`, `numeric`, `json`) from the rendered text. A schema
picks the sort comparator, the sort labels ("Low-High"), the alignment and
the expansion popover (JSON is pretty printed). `@schemaDetectors` adds your
own types. Explicit `schema` values on columns always win.

</EuiText>

<EuiHorizontalRule />
