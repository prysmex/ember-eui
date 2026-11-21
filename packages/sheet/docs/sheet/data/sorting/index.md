---
title: Sorting
order: 81
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: sorting"/>
<EuiSpacer @size="l" />

<EuiText>

The sheet never sorts: the header menu's "Sort" items call
`@onSortChange`, you sort `@records` and pass `@sort`, which draws the
arrows.

Sorting a local array needs a few lines in your component (the ["View
intents" example](/docs/sheet/docs/sheet/fields/columns) does it with each type's `compare`). For filtering,
search and paging over local data, an EmberSearchUi driver with its
in-memory backend does the work, shown through [the connector](/docs/sheet/docs/sheet/data/search-ui).

## Related

- [EmberSearchUi](/docs/sheet/docs/sheet/data/search-ui): a driver that sorts, filters and pages
- [The owner](/docs/sheet/docs/sheet/more/api-reference#the-owner)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
