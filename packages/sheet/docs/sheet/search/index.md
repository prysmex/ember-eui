---
title: Search and EmberSearchUi
order: 10
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: search and EmberSearchUi"/>
<EuiSpacer @size="l" />

<EuiText>

The sheet does not search: it shows your term and your current
match. An EmberSearchUi driver can own the whole query.

## Search matches

The sheet does not search, but it shows your current match:
`@currentMatch={{this.match}}` scrolls that cell into view (below the
header, clear of the frozen fields) and draws a ring inside it
(`--euiSheet-match`), over `@highlight`'s marks. Focus stays in your
search box, so typing goes on. Keep your matches and an index, pass
`matches[index]`, and step on Enter and Shift+Enter; `api.focusCell` is
for when the user leaves the box. A match that is not in `@records` (on
another page, in a collapsed group) or whose field is hidden draws
nothing: change the page, expand the group (`toggleGroup`) or show the
field first; the sheet scrolls to it once its record arrives. An owner
that holds every record lists its matches with `findMatches`:

```js
import { builtInFieldTypes, defaultMessages, findMatches } from '@ember-eui/sheet';

const ctx = { types: builtInFieldTypes, messages: defaultMessages, getRecordId: (r) => r.id };
findMatches(ctx, records, fields, 'ana'); // [{ recordId, fieldId }, …], by row then field
```

It matches what `@highlight` marks: each type's shown text, ignoring
case and accents. An owner that pages gets its matches from its backend.
With groups, list them over the records in display order with every
group expanded (`groupRecords` without `collapsed`), as the "Search
navigation" example does.

Sorting a local array needs a few lines in your component (the ["View
intents" example](/docs/sheet/docs/sheet/layout) does it with each type's `compare`). For filtering,
search and paging over local data, an EmberSearchUi driver with its
in-memory backend does the work, shown through the connector below.

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
  skipped and stays on the stack (see [Undo and redo](/docs/sheet/docs/sheet/editing#undo-and-redo)).
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

The "Sheet with EmberSearchUi" example below uses EmberSearchUi's own
views (search box, sort menu, filter bar, chips, paging info) in the
blocks.

</EuiText>
