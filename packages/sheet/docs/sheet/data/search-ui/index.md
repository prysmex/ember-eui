---
title: EmberSearchUi
order: 85
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: EmberSearchUi"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiSheetSearch` shows an EmberSearchUi driver's results in a sheet: the
driver owns the query (filter, search, sort, paging), the sheet edits
the results.

## EmberSearchUi

`@ember-eui/sheet/search-ui` renders the sheet as an
[EmberSearchUi](https://github.com/bengala-tech/ember-search-ui) results
view. The driver owns the query (filter, search, sort, paging, over a
server or `memoryBackend`); the sheet shows its results and edits them.
Neither package depends on the other: the connector is typed against the
few driver members it uses (`SheetSearchDriver`), which
`ember-search-ui-driver`'s `SearchDriver` has.

```gjs
import { EuiSheetSearch } from '@ember-eui/sheet/search-ui';

<template>
  <EuiSheetSearch
    @driver={{this.driver}}
    @getRecordId={{this.getId}}
    @onChange={{this.save}}
    @fields={{this.fields}}
  >
    <:toolbar as |sheet|>
      {{! EmberSearchUi views, a field picker; sheet.search is the connector }}
    </:toolbar>
  </EuiSheetSearch>
</template>
```

What it maps:

| Sheet | Driver |
| --- | --- |
| `@records` | the last successful results, with your edits since then on top |
| `@sort`, header "Sort" items | `state.sort`, `driver.setSort` (back to page 1) |
| `@highlight` | `state.query.term` |
| `@isLoading` | `result.status === 'loading'` (the rows stay meanwhile) |
| `@rowNumberOffset` | `(page - 1) * perPage` of the page the rows came from |
| the pager in the footer | `EuiTablePagination` on `driver.setPage`, `driver.setPerPage` (offset paging only) |
| `@fields` (default) | `fieldsFromSchema(driver.schema)` |
| `@onChange` | your `@onChange` only: the driver has no write method |

**Stable while editing.** `@onChange` persists the change set (an API
call, or writing the docs a `memoryBackend` reads); it may return a
promise. The connector shows the edit at once over the last results and
does not search again, so rows do not move, vanish or re-sort under the
user. A **Re-apply** button (message `reapply`) appears in the toolbar;
it waits for your pending `@onChange` promises and calls
`driver.refresh()`, and the rows come back as the query puts them. Any
other search (a sort, a page, a filter) does the same. A search that
finishes while a save is still running is followed by one more refresh
when the save settles. With `@refreshOnChange={{true}}` the connector
re-applies after each change set (a live view).

- Inserted rows show at their place until the next search, under their
  `tempId` (`createRecord(values, tempId)` builds them; default `{ id:
  tempId, ...values }`). A server that gives them real ids tells the sheet
  with `api.remapIds` (from `@registerApi`), as with any owner.
- A rejected `@onChange` promise leaves the edit shown and re-throws the
  error to your error handling; nothing is undone (call `api.undo()` if
  you want that).
- Undo works by record id across searches: a change on another page is
  skipped and stays on the stack (see [Undo and redo](/docs/sheet/docs/sheet/editing/undo-redo#undo-and-redo)).
- The blocks yield the sheet's block API plus `search`: `records`,
  `sort`, `term`, `isLoading`, `error`, `total`, `page` (`{ page, perPage,
  pageCount }`, offset paging only), `rowNumberOffset`, `isStale`,
  `apply`, `setSort`, `setPage`, `setPerPage`, `reapply`. Your
  `<:toolbar>` content comes after "Re-apply", your `<:footer>` content
  after the pager; `@paging={{false}}` drops the pager (with cursor paging
  there is none: page in `<:footer>`).
- `fieldsFromSchema` turns `keyword` with options into `singleSelect`,
  `number` into `number`, `date` into `date`, `boolean` into `checkbox`,
  anything else into `text`, with the schema's label; it leaves out nested
  and `geo` fields and dotted paths (a sheet field reads one key). It sets
  no widths, rules or read-only flags: real apps pass `@fields`.
- `@summary` is not mapped: turn `result.aggregations` into texts
  yourself.
- `EuiSheetSearch` passes every other `EuiSheet` argument through
  (`@hiddenFields`, `@readOnly`, `@validate`, `@registerApi`,
  `@onVisibleRangeChange`, `@fullScreen`, `@cellColor`, ...) and the
  `<:empty>` and `<:recordFooter>` blocks (their block API, like the
  toolbar's and footer's, has `search`). The search owns `@records`,
  `@sort`, `@onSortChange`, `@highlight`, `@isLoading` and
  `@rowNumberOffset`. For more control, use `searchRecords(this, driver,
  { getRecordId, onChange })` with your own `<EuiSheet>`: its properties
  are the arguments (`@records={{search.records}}`, `@onChange={{search.apply}}`,
  `@sort`, `@onSortChange={{search.setSort}}`, `@highlight={{search.term}}`,
  `@isLoading`, `@rowNumberOffset`). It unsubscribes when `this` is
  destroyed and never destroys the driver.

The "Sheet with EmberSearchUi" example on this page uses EmberSearchUi's own
views (search box, sort menu, filter bar, chips, paging info) in the
blocks.

## Related

- [Search and match stepping](/docs/sheet/docs/sheet/data/search-matches)
- [Groups](/docs/sheet/docs/sheet/data/record-groups): groups with EmberSearchUi
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
