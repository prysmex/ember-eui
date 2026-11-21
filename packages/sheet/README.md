# @ember-eui/sheet

An Airtable-like data-entry grid for Ember, built on `EuiDataGrid` from
[`@ember-eui/core`](https://github.com/prysmex/ember-eui). It is
controlled: you pass the records in, and the sheet calls `@onChange` with
a change set (what the user typed, cleared or pasted); you apply it to your
own store. It edits with the keyboard, selects ranges, copies and pastes
blocks as TSV (to and from spreadsheets), and shows cell errors. It has
built-in field types for text, numbers, checkboxes, selects, dates,
dates with a time in a zone, linked records, users, attachments,
currency, percent, duration, rating, links, long text, buttons that run
your action and barcodes (typed, pasted or scanned), and you can add
your own cells and editors. Rows can be dragged to a new order (a change
set with `moves`, opt-in with `@canMove`) and coloured by record
(`@rowColor`), and cells by your rule (`@cellColor`). It shows your current search match (`@currentMatch`),
gives you the selection to summarize (`@onSelectionChange`,
`summarizeCells`), selects ranges by touch with two handles, and shows
upload progress. Fields
can be added, edited, duplicated and deleted from the grid (the "+" column
and the column menu), through your handlers. Records can be drawn in
groups, with collapsible headers, counts and per-group summaries, from the
groups you pass.

**New to the sheet?** Start with [Getting started](https://ember-eui.vercel.app/docs/sheet/docs/sheet): a working
sheet in five minutes, with a link to each topic page of the docs.
Then [the example app](https://ember-eui.vercel.app/docs/sheet/docs/sheet/example-app)
uses groups, editing, import, CSV export, loading more and the expanded
record together.

## Install

```sh
pnpm add @ember-eui/sheet
```

`@ember-eui/core` is a peer dependency: install and set it up first.

## Usage

```gts
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import type { EuiSheetField } from '@ember-eui/sheet';

interface Task {
  id: string;
  name: string;
  hours: number | null;
  done: boolean;
  status: string | null;
  due: string | null;
}

const FIELDS: EuiSheetField<Task>[] = [
  { id: 'name', label: 'Task', required: true },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'done', label: 'Done', type: 'checkbox' },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    createOnPaste: true,
    options: [
      { value: 'open', label: 'Open' },
      { value: 'closed', label: 'Closed', color: 'success' }
    ]
  },
  { id: 'due', label: 'Due', type: 'date' }
];

export default class Tasks extends Component {
  getId = (task: Task) => task.id;
  store = localRecords<Task>(
    [
      {
        id: 't1',
        name: 'Inspect line 3',
        hours: 2,
        done: false,
        status: 'open',
        due: '2026-11-19'
      }
    ],
    { getRecordId: this.getId, fields: FIELDS }
  );

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{400}}
    />
  </template>
}
```

Arguments of `EuiSheet`:

| Argument                                                          |                                                                                                                                                                                                                                        |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@fields`                                                         | The visible columns, in order: `{ id, label?, type?, readOnly?, required?, validate?, description?, width?, sortable?, hideable?, importAliases?, ...options of the type }`. `readOnly` and `required` can be functions of the record. |
| `@records`                                                        | The rows. Pass a new array when they change.                                                                                                                                                                                           |
| `@getRecordId`                                                    | `(record) => id`.                                                                                                                                                                                                                      |
| `@onChange`                                                       | `(changeSet) => void`. Apply it to your records.                                                                                                                                                                                       |
| `@cellErrors`                                                     | Your own errors: `{ [recordId]: { [fieldId]: message \| messages } }`. Shown last.                                                                                                                                                     |
| `@validate`                                                       | Record, cross-row and server rules (below).                                                                                                                                                                                            |
| `@fieldTypes`                                                     | Your field types, merged over the built-in ones. Keep the object stable.                                                                                                                                                               |
| `@readOnly`                                                       | Every cell read-only (copy still works).                                                                                                                                                                                               |
| `@messages`                                                       | Overrides of the built-in messages (below).                                                                                                                                                                                            |
| `@height`, `@ariaLabel`                                           | The grid's height; its accessible name (default `Sheet`).                                                                                                                                                                              |
| `@registerApi`                                                    | `(api) => void`: the sheet's API, once, after the first render (below).                                                                                                                                                                |
| `@hiddenFields`                                                   | Fields that are not columns: listed in the expanded record, copied by duplicate.                                                                                                                                                       |
| `@onHiddenFieldsChange`, `@onFieldOrderChange`                    | The new hidden ids after a hide or show; the visible ids after a move or a header drag. With them, update `@fields` / `@hiddenFields`; without them the sheet keeps its own.                                                           |
| `@fieldDrag`, `@headerLines`                                      | Drag a header to reorder (default `true`; also Space, the arrows and Space on a focused header); `1` (default), `2` or `3` lines a header label may wrap to.                                                                           |
| `@fieldWidths`, `@onFieldWidthChange`                             | Widths by field id; `(fieldId, width)` after a resize or a fit to content (without it the sheet keeps the width itself).                                                                                                               |
| `@fullScreen`, `@onFullScreenChange`                              | The sheet fills the window (below); controlled with the handler, local without it.                                                                                                                                                     |
| `@rowHeight`, `@onRowHeightChange`                                | `'short'` (default), `'medium'`, `'tall'`, `'extraTall'`; controlled with the handler, local without.                                                                                                                                  |
| `@sort`, `@onSortChange`                                          | Your sort (`[{ field, direction }]`), drawn as arrows; the column menu's sort items call the handler. No handler: no sort items. The sheet never sorts.                                                                                |
| `@onFilterByField`                                                | Adds "Filter by this field" to the column menu: `(fieldId) => void`.                                                                                                                                                                   |
| `@highlight`, `@isLoading`                                        | A searched term, marked in cells; a progress bar over the grid.                                                                                                                                                                        |
| `@currentMatch`                                                   | `{ recordId, fieldId }` or `null`: your current search match, scrolled into view and ringed; focus stays in your search box.                                                                                                           |
| `@onSelectionChange`                                              | `(selection or null) => void`: the selected records and fields, after render, when they change.                                                                                                                                        |
| `@onVisibleRangeChange`                                           | `({ first, last, count }) => void`: the records on screen (positions in `@records`), after render, when they change. For loading more as the user scrolls.                                                                             |
| `@summary`                                                        | `{ [fieldId]: text }` (`''`: the row-number column): the summary bar.                                                                                                                                                                  |
| `@frozenFields`                                                   | Leading fields kept in view on horizontal scroll, with the row numbers. Default `0` (off); `1` freezes the first field.                                                                                                                |
| `@rowNumbers`, `@rowLabel`, `@rowNumberOffset`                    | The row-number column (default on); `(record, position) => text` to show something else than the position; the first record's position on a page.                                                                                      |
| `@rowColor`, `@cellColor`                                         | `(record) => colour` and `(record, field) => colour` (or `undefined`): a 4 px bar at a row's left edge; a 3 px bar along a cell's bottom edge. Keep them cheap, no lookups across rows.                                                |
| `@canInsert`, `@canDelete`                                        | Adding (add row, Shift+Enter, menu) and deleting (menu) records. Default `!@readOnly`.                                                                                                                                                 |
| `@newRecordValues`                                                | `({ above, below }) => values` of a new record.                                                                                                                                                                                        |
| `@checkedRecordIds`, `@onCheckedChange`                           | Checked rows; controlled with the handler, local without it.                                                                                                                                                                           |
| `@expandedRecordId`, `@onExpandedRecordChange`, `@expandedRecord` | The expanded record (controlled the same way), in a `'flyout'` (default) or a `'modal'`.                                                                                                                                               |
| `@rowActions`                                                     | Your row menu items: `{ id, label, icon?, color?, isDisabled?(records), onSelect(records) }`.                                                                                                                                          |
| `@fieldActions`                                                   | Your header menu items, on every visible field before "Delete field": `{ id, label, icon?, color?, isDisabled?(field), onSelect(field) }`. Keep the array stable.                                                                      |
| `@copyWithFieldNames`                                             | Adds "Copy with field names" to the row menu (default `false`).                                                                                                                                                                        |
| `@onResolve`                                                      | `(requests, { signal }) => Promise<{ [fieldId]: { [text]: value \| null } }>`: bulk resolve of typed or pasted text (linked records, users, your types). Without it such text is rejected.                                             |
| `@editIn`                                                         | Where a click on the selected cell, or Enter, edits: `'cell'`, `'record'` (the expanded record with that field's editor open) or `'auto'` (default: the record on a touch screen narrower than 600 px, else the cell).                 |

Blocks: `<:toolbar as |sheet|>` (above the grid) and `<:footer as |sheet|>`
(below it) take your own controls. Both yield `{ api, fields, hiddenFields,
sort, rowHeight, checkedRecords, selection, isFullScreen, hideField(id),
showField(id), setRowHeight(height), setSort(sort), showShortcuts(),
setFullScreen(on) }`. `<:empty>` replaces the "No records" message shown
when `@records` is empty. `<:recordFooter as |record sheet|>` goes below
the expanded record's fields (below).

## The owner: queries and presentation

The sheet is a view of `@records` as given: it never sorts, filters,
searches, groups, pages or summarizes. It draws your state (`@sort` as
arrows, `@highlight`, `@isLoading`, `@summary`) and emits intents
(`@onSortChange`, `@onFilterByField`). There is no built-in toolbar: put
your search box, field picker or pager in the blocks.

Presentation state (visible fields and their order, widths, row height) is
controlled with a handler (the sheet shows exactly the argument and calls
the handler; update the argument, or nothing changes) and local without
one ("Hide column" hides, "Move" or a header drag moves). The first field
cannot be hidden or moved. `@fieldDrag={{false}}` turns the header drag
off; `@headerLines={{2}}` lets long labels wrap.

The summary bar shows `@summary`'s texts. Compute them from your backend,
or over every record with `summarize(ctx, records, field, kind)` (`count`,
`filled`, `empty`, `percentFilled`, `unique`, `sum`, `average`, `min`,
`max`, `checked`, `unchecked`; sums use the type's `toNumber`).

The selection is yours to summarize: the blocks' `selection`,
`api.getSelection()` and `@onSelectionChange` give `{ kind, records,
recordIds, fields, cellCount }` (header and add rows left out, checked
rows separate), and `summarizeCells(ctx, selection, kind)` gives `count`,
`filled`, `sum`, `average`, `min` or `max` over every cell (one field:
its format; several: a plain number). `@onSelectionChange` runs after
render, at most once per run loop, when the records, fields or kind
changed: keep it cheap.

Paging is yours, and so is loading more as the user scrolls:
`@onVisibleRangeChange` gets `{ first, last, count }`, the first and
last records on screen as positions in `@records` (group headers and add
rows skipped) and `@records.length`. It runs after render, at most once
per run loop, when one of them changed (a scroll, a resize, `@records`
growing). Load the next page when `last` nears `count`, guarded by your
own loading flag, pass `@isLoading`, and append to `@records`: the scroll,
the selection and focus stay.

```js
onVisibleRangeChange = ({ last, count }) => {
  if (this.hasMore && !this.isLoading && last >= count - 20) this.loadMore();
};
```

Search is yours too, but the sheet shows your current match:
`@currentMatch={{this.match}}` scrolls it into view (clear of the frozen
fields) and draws a ring (`--euiSheet-match`) without taking focus from
your search box. `findMatches(ctx, records, fields, term)` lists the
cells whose shown text contains the term, for an owner with every
record; step through them on Enter. A match not in `@records` (another
page, a collapsed group) draws nothing until you show it.

`@frozenFields={{1}}` freezes the first field (off by default): it, its
header, its summary cell and the row numbers stay in view on horizontal
scroll. While a field is frozen the grid renders the frozen columns
besides the columns in view; the other columns stay virtualized, and so
do the rows, so the number of fields and records hardly matters. At the
left edge both render the same cells (72 in the sheet's test with 10,000
records and 30 fields) and a scroll step takes about the same time; on
the docs' Large data page (10,000 records) a scroll pass had the same
frame p90 frozen and not (50 ms), and about 7 % more busy time frozen.
Scrolled sideways, a row renders its frozen cells more. Above 50 visible
fields the sheet does not freeze. The docs' [Large data](https://ember-eui.vercel.app/docs/sheet/docs/sheet/large-data#performance-with-frozen-fields)
page has the numbers.

### Group by

The sheet draws groups and never groups: pass the headers in `@groups`
(depth-first, each with `key`, `depth`, `value`, `count`, `loaded`,
`collapsed`, `summary`) and the expanded groups' records in `@records`, in
display order. `localRecords` does it for local data:

```gjs
const store = localRecords(records, { getRecordId, fields, groupBy: [{ field: 'status', direction: 'asc' }] });

<EuiSheet
  @fields={{store.fields}}
  @records={{store.view.records}}
  @groups={{store.view.groups}}
  @groupBy={{store.groupBy}}
  @onGroupByChange={{store.setGroupBy}}
  @onGroupToggle={{store.toggleGroup}}
  @getRecordId={{getRecordId}}
  @onChange={{store.apply}}
/>
```

`@onGroupByChange` adds "Group by this field" and "Remove grouping" to the
column menu (not on a field with `groupable: false`); `@onGroupToggle`
gives each header its chevron (and Enter or Space on it). Each expanded
group has its own add row, and a record added there, or next to a record
of the group (Shift+Enter, insert, duplicate), gets the group's values and
`groupKey`. Counts are yours: the sheet reads nothing from the records.
`groupRecords`, `applyChangeSetToGroups` and `pageGroups` help an owner
build `@groups`; `EuiSheetSearch` forwards the four arguments. Grouping
keeps column virtualization, so it costs about what an ungrouped sheet
costs. The docs' [Group by](https://ember-eui.vercel.app/docs/sheet/docs/sheet/groups#group-by) section has the contract.

## Full screen

Full screen is a toolbar button of yours: the block's `setFullScreen(on)`
and `isFullScreen`. The sheet (toolbar, grid, footer) fills the window,
`@height` is ignored, the page does not scroll, a fixed `EuiHeader` goes
below it (as with the grid's own full screen); menus, editors, the
expanded record and the shortcut list open above it. Escape on a cell
ends it once nothing else uses the key (an editor, a menu, the copy mark
and a range come first). Tab can leave the sheet: add your own focus trap
if you need one.

```hbs
<:toolbar as |sheet|>
  <EuiButtonEmpty
    @iconType={{if sheet.isFullScreen 'fullScreenExit' 'fullScreen'}}
    {{on 'click' (fn sheet.setFullScreen (if sheet.isFullScreen false true))}}
  >{{if sheet.isFullScreen 'Exit full screen' 'Full screen'}}</EuiButtonEmpty>
</:toolbar>
```

## CSV export and import

Both are helpers your toolbar calls; the sheet draws no button.
`toCsv(ctx, records, fields, { delimiter?, headers?, escapeFormulas? })`
writes the records as CSV: each cell is the text a copy gives, quoted
as RFC 4180 says, a first line of labels, and a leading `'` on a cell a
spreadsheet would run as a formula (`=SUM(A1)`, `@x`, `-cmd`; numbers
such as `-5` stay). `ctx` is `{ types, messages }`, as for `summarize`.

An import takes three steps and goes through the paste path of the add
row: types read the texts, `@onResolve` resolves linked records and
users, unreadable texts show as rejections, and one Ctrl/Cmd+Z removes
it.

```js
const matrix = parseCsv(await file.text()); // `,` `;` or tab, detected
const { rows, fieldIds, unmatched } = importMatrix(matrix, [
  ...sheet.fields,
  ...sheet.hiddenFields
]);
api.appendRows(rows, fieldIds); // false with @canInsert={{false}}
```

Headers match a field's `importAliases`, then its label, then its id,
ignoring case, accents, spaces, `_` and `-` (`matchHeader`); `mapping`
overrides the match. Columns go to their fields by id, also hidden
ones; fields with no column get `@newRecordValues`. `appendRows`'
`fields` option reads columns with fields `@fields` does not have yet or
with a per-column copy (`{ ...field, dateOrder: 'mdy' }`), never stored.
`appendRows` does not chunk: call it per 1,000 lines for large files
(each chunk is one undo step), and import with no group by (the last
group's values would win).

`<EuiSheetImport>` is an import screen for the step in between (it
renders inline; place it in your modal): it maps the file's columns to
fields (a saved mapping, then aliases, label, id), guesses each
column's type, lets the user pick a field, a new field or nothing, a
transform you define, the date order, decimal separator and a value
map, and shows a preview and the totals of a dry run over every line,
with a download of the lines with errors. `@onCreateFields(drafts)`
creates new fields on Import; `@onImport(result)` gets the lines:
`api.appendRows(result.rows, result.fieldIds, { fields: result.fields })`.
It takes no sheet, so any target described by fields works
(`result.values`). See the docs, [Import from CSV](https://ember-eui.vercel.app/docs/sheet/docs/sheet/import-export#import-from-csv).

## EmberSearchUi

`@ember-eui/sheet/search-ui` shows an
[EmberSearchUi](https://github.com/bengala-tech/ember-search-ui) driver's
results in a sheet. The driver owns the query; neither package depends on
the other (the connector is typed against the few `SearchDriver` members it
uses, `SheetSearchDriver`).

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
      {{! your views; sheet.search is the connector }}
    </:toolbar>
  </EuiSheetSearch>
</template>
```

- `@records` are the last successful results with your edits since then on
  top; `@sort`/`@onSortChange` are the driver's sort; `@highlight` its query
  term; `@isLoading` its loading state; `@rowNumberOffset` the page of the
  shown rows. The footer has an `EuiTablePagination` under offset paging
  (`@paging={{false}}` drops it). `@fields` defaults to
  `fieldsFromSchema(driver.schema)`.
- **Stable while editing**: `@onChange` persists the change set (it may
  return a promise) and the connector does not search again, so rows do not
  move under the user. A "Re-apply" button (message `reapply`) waits for
  pending saves and calls `driver.refresh()`; any other search does the
  same. `@refreshOnChange={{true}}` re-applies after each change set.
- A rejected save keeps the edit shown and re-throws the error; undo works by
  record id across searches (a change on another page is skipped and stays
  on the stack).
- The blocks yield the sheet's block API plus `search` (`records`, `sort`,
  `term`, `isLoading`, `error`, `total`, `page`, `rowNumberOffset`,
  `isStale`, `setSort`, `setPage`, `setPerPage`, `reapply`, `apply`). Your
  toolbar content comes after "Re-apply", your footer content after the
  pager.
- For an `EuiSheet` argument the component does not pass on, use
  `searchRecords(this, driver, { getRecordId, onChange })` with your own
  `<EuiSheet>` (`@records={{search.records}}`, `@onChange={{search.apply}}`,
  ...).

`ember-search-ui-driver` is not a dependency of this package: install
EmberSearchUi in your app.

## Your own store

`localRecords` is a small tracked store for demos and simple pages. With
your own store, apply the change set yourself:

```ts
interface ChangeSet {
  source:
    | 'edit'
    | 'paste'
    | 'clear'
    | 'fill'
    | 'undo'
    | 'redo'
    | 'insert' // coming: row buttons
    | 'delete'
    | 'cut'
    | 'resolve'; // coming: bulk resolve of pasted text
  patches: { recordId; fieldId; from; to }[]; // cells of existing records
  inserts: {
    tempId;
    index; // position in @records, inserts applied in ascending order
    values;
    anchor?: { recordId; position: 'before' | 'after' }; // its neighbour then
    restore?: { recordId; record }; // an undone delete: the record it was
  }[];
  deletes?: recordId[]; // records to remove
  removed?: { recordId; index; after?; record }[]; // what a delete removed
  rejected: { recordId?; tempId?; fieldId; text; message }[];
  newOptions: { fieldId; option }[]; // options created on paste
}
```

- `applyChangeSet(records, changeSet, { getRecordId, createRecord?,
restoreRecord? })` returns the new records (patched records are new
  objects; the others keep their identity; records whose id is in
  `deletes` are removed). The default `createRecord` uses the `tempId` as
  the new record's `id`. An insert goes right after (or before) its
  `anchor` when that record is there, else at `index` (past the end: at
  the end). A pasted row is anchored after the last record, so a store
  whose data is larger than `@records` (one page, sorted elsewhere) can
  position it by the anchor. An insert with `restore` (an undone delete)
  puts back `restore.record` as it is, or what `restoreRecord(insert)`
  returns (`insert.values` has its field values).
- When your store gives a new record another id, call
  `api.remapIds({ [tempId]: newId })` before (or with) the `@records` that
  carry it, so that undo still finds the row.
- `applyNewOptions(fields, changeSet)` returns the fields with the options
  created on paste (`createOnPaste`). Pass the result as `@fields`.
- `rejected` lists texts a field type could not read (`abc` in a number
  field). They make no patch: the record keeps its value, and the sheet
  shows the text in the cell, marked invalid, until the cell is written
  again. A rejection in a pasted row is shown once a record with the
  `tempId` as its id exists; if your store assigns other ids, show it
  through `@cellErrors`.

The helpers and every type are also exported from `@ember-eui/sheet/core`,
which has no Ember imports.

## Undo and redo

Ctrl/Cmd+Z undoes the last change made in the sheet (an edit, a paste, a
clear, a fill, a checkbox toggle); Ctrl/Cmd+Shift+Z and Ctrl+Y redo it. Each
sheet keeps the last 100 change sets it emitted. An undo is a change set
like any other, through `@onChange` (so `@validate` and rejections work as
usual):

- `source: 'undo'`, each patch with `from` and `to` swapped, and the rows a
  paste inserted in `deletes` (their `tempId`s). A redo emits the original
  again with `source: 'redo'`, re-inserting with the same `tempId`s and
  values.
- Only cells that still hold the value the change left there are written;
  a cell changed since (by your store, a server, another user) is skipped.
  When nothing is left, nothing is emitted.
- An inserted row is found by its `tempId`: if your store gives the new
  record another id, call `api.remapIds` (below); without it undo cannot
  remove the row (the deletion is skipped). A row changed since it was
  inserted is not removed either.
- An undone delete puts each record back after the neighbour it had, even
  when the records were re-sorted since. A change whose records are not in
  `@records` (another page) is skipped and stays on the stack, for when they
  are back; `api.clearHistory()` drops the history when your data changes
  wholesale.
- A change's rejected texts are part of it: undoing a paste removes the
  texts it could not read too (also a paste where every cell was rejected),
  and redo shows them again where the cell still holds the value it had.
  The owner gets no change set for that part.
- Options created on paste (`createOnPaste`) are not removed by undo.
- Changes you make to `@records` are not history; a new change clears the
  redo history; with `@readOnly`, undo and redo do nothing. In an open
  editor, Ctrl/Cmd+Z is the input's own undo.

The pure parts are exported: `invertChangeSet`, `withoutConflicts`,
`undoChangeSet`, `redoChangeSet`, `mergeChangeSets`, for ranges
`fillDown`, `fillRight`, `fillRange` (the fill handle, with series) and
`tileMatrix`, `edgeTarget` (Ctrl/Cmd+arrow), and for records `insertRecords`,
`deleteRecords` and `duplicateRecords` (the change sets the add row and the
row menu emit).

## The sheet's API

`@registerApi={{this.registerApi}}` receives one object:

| Method                                    |                                                                                                                       |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `undo()`, `redo()`                        | As Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z.                                                                                   |
| `focusCell({ recordId, fieldId })`        | Focuses that cell; nothing when the record is not in `@records` or the field is not shown.                            |
| `scrollToCell({ recordId, fieldId })`     | Scrolls that cell into view without focusing it.                                                                      |
| `getSelection()`                          | The selection now, or `null`.                                                                                         |
| `remapIds({ [tempId]: id })`              | The ids your store gave to inserted or restored records: the undo history, rejected texts and a pending focus follow. |
| `clearHistory()`                          | Drops the undo and redo history.                                                                                      |
| `expandRecord(id)`                        | Opens the expanded record (`null` closes it).                                                                         |
| `insertRecord({ anchor?, values? })`      | Emits the insert of one record, next to `anchor` or at the end.                                                       |
| `deleteRecords(ids)`                      | Emits the delete of those records.                                                                                    |
| `showShortcuts()`                         | Opens the shortcut list (as Ctrl/Cmd+/).                                                                              |
| `addField({ index? })`                    | Opens the field editor to add a field (with `@onFieldCreate`).                                                        |
| `editField(fieldId)`                      | Opens the field editor on a field, also a hidden one (with `@onFieldUpdate`).                                         |
| `fitField(fieldId)`, `fitFields()`        | Fits one visible field's width, or every one's, to its content.                                                       |
| `setFullScreen(on)`                       | Full screen on or off.                                                                                                |
| `appendRows(rows, fieldIds, { fields? })` | Adds the rows as records after the last one, as a paste on the add row (CSV export and import, above).                |

When you replace `@records` with records the sheet did not change (a new
sort, another page, a reload), the selection collapses to the focused
cell's record wherever it is now (the same row when it is gone), and an
open editor stays on its record (closed without saving when it is gone).

## Theme

The colours (selection, focus, errors, the editor's input, the checkbox)
come from the EUI theme, so the sheet follows light and dark: put it in an
`EuiEmotionProvider @colorMode="dark"`, or set the `eui-emotion` service's
`colorMode`. They are custom properties (`--euiSheet-primary`,
`--euiSheet-selected`, `--euiSheet-hover`, `--euiSheet-plain`,
`--euiSheet-text`, `--euiSheet-textSubdued`, `--euiSheet-danger`,
`--euiSheet-textDanger`, `--euiSheet-dangerFilled`,
`--euiSheet-textInverse`, `--euiSheet-shadow`, `--euiSheet-subdued`,
`--euiSheet-border`, `--euiSheet-link`, `--euiSheet-star`,
`--euiSheet-textSuccess`, `--euiSheet-match`, the row colours `--euiSheet-rowPrimary`,
`-rowAccent`, `-rowSuccess`, `-rowWarning`, `-rowDanger`, `-rowNeutral`,
and `--euiSheet-highlight`) set by a class on the sheet's wrapper.
`@rowColor={{this.colorOf}}` draws a 4 px bar at a row's left edge: a
named colour (`'danger'`, …) is the theme's, any other a CSS colour as
given; `colorByOption(field)` colours by a select's option colours. `@cellColor={{this.cellColor}}`, called with the record and the field, draws a 3 px bar along a cell's bottom edge in the same colours (an overdue date in `'danger'`); it is called for each rendered cell, so keep it cheap, with no lookups across rows. To change one, set it on the sheet itself (`<EuiSheet
style="--euiSheet-selected: #E6F0FF" …>`) or with a more specific
selector: set on a parent element it loses to the sheet's class. The row
menu, the field editor and the panel editors render at the end of
`<body>` (a card with `overflow: hidden` around the sheet does not cut
them off) and get the class and those overrides too. Editors
get that class as
`@themeClass`: an editor that renders part of itself elsewhere (a
wormholed list) adds it there, or that part falls back to light colours.

## Records

The first column shows each row's position (`@rowNumberOffset + index + 1`,
or `@rowLabel`'s text), and on hover a checkbox and an expand icon. A click
on a row number selects the row (Shift+click, a drag: more rows); a click on
a column's title selects the column. Checked rows (click, Shift+click for a
run, the header box for all) are what the row menu acts on, else the
selected rows. The last grid row adds a record (click or Enter; a paste
there adds its lines); Shift+Enter adds one below the cell. Right-click,
Shift+F10 or the ContextMenu key open the row menu: insert above/below,
duplicate, expand, copy the rows (with `@copyWithFieldNames`, also after
a line of the field names), your `@rowActions`, delete. Each is one
change set and one undo step. Delete and Backspace never delete rows.

With `@canMove` each row number has a grip: drag it (a line shows where
the rows go; checked rows, or selected whole rows, move together; Escape
cancels), or press Alt+Shift+ArrowUp/Down on a row number. The change
set has `source: 'move'` and `moves` (`{ recordId, anchor?, groupKey?,
from }`, in order: put each record next to its anchor); grouped, a drop in
another group also patches its group fields. `applyChangeSet` and
`localRecords` apply moves; your backend keeps the order (an order
column). Undo moves them back. Off with a `@sort` or `@readOnly`;
`api.moveRecords(ids, { recordId, position })` does the same.

## Fields

The owner owns `@fields`; adding, editing, duplicating and deleting one
are intents, and each handler shows its controls (none without it):
`@onFieldCreate` the "+" column and the column menu's Insert left/right
and Duplicate field, `@onFieldUpdate` Edit field, `@onFieldDelete` Delete
field (after a confirmation). The field editor has the name, the type
(`@creatableFieldTypes`), the type's options, a description and Required;
`@fieldEditor` replaces its content. A handler may return a promise: the
editor stays open and busy, and shows the rejection's message. A bare app
passes `localRecords`' handlers:

```hbs
<EuiSheet
  @fields={{this.store.fields}}
  @records={{this.store.records}}
  @getRecordId={{this.getId}}
  @onChange={{this.store.apply}}
  @onFieldCreate={{this.store.createField}}
  @onFieldUpdate={{this.store.updateField}}
  @onFieldDelete={{this.store.deleteField}}
/>
```

The draft is plain data (`{ label, type, description?, required?, ...type
options }`); build the field from it and pass the new `@fields`. The sheet
changes no value on a type change: `convertField(ctx, records, previous,
next)` returns the change set that converts them through the paste path,
with what could not convert in `rejected` (`localRecords.updateField`
applies it). Field changes are not on the sheet's undo stack; a deleted or
retyped field's edits are dropped from it. A type names itself in the
editor with `label` and adds its options form with `fieldOptions`.

The header menu (also called the column menu) has "Fit to content" on
every field that has a menu. It, a double-click on a column's resize
edge, `api.fitField(fieldId)` and `api.fitFields()` size columns to
their header and their widest loaded cell (the first 2,000 records),
between 80 and 480 px; the width goes out as a resize's
(`@onFieldWidthChange`, or the sheet keeps it). A type whose cell is not
text gives `contentWidth(value, field, measure, context)`.

`@fieldActions` adds your items to every visible field's header menu,
before "Delete field"; `onSelect(field)` runs once the menu has closed and
focus is back on the header's button:

```js
fieldActions = [
  {
    id: 'history',
    label: 'Show history',
    icon: 'clock',
    onSelect: (field) => this.openHistory(field.id)
  }
];
```

## Expanded record

Space on a cell, Enter on a row number, the expand icon or the menu open
the record in a flyout (`@expandedRecord="modal"`: a modal): `@fields`, then
`@hiddenFields`, each with the grid's cell in a box. A click, Enter, F2 or
typing on a box opens the field's editor in place; Enter saves and goes to
the next field, Tab moves on, Escape cancels; Escape on a box closes, and
focus returns to the cell. Saves are change sets like grid edits (validated,
undoable with Ctrl/Cmd+Z there too). While an editor is open the shell's
focus trap is off, so a wormholed calendar works.

`<:recordFooter as |record sheet|>` draws your block below the fields,
after a line, in the flyout and the modal (the arrows re-render it with
the next record): your comments or history. The sheet stores none of it.
Typing in the block types there, and Escape in its text box does not
close the record.

```hbs
<:recordFooter as |record|>
  <MyComments @recordId={{record.id}} />
</:recordFooter>
```

## Field types

| Type                    | Value                                                            | Accepted text                                                                           | Options                                                                               |
| ----------------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `text` (default)        | string                                                           | anything                                                                                | `maxLength`, `pattern`, `patternMessage`                                              |
| `number`                | number or `null`                                                 | `12`, `-1.5`, `1,234.5` (no exponent, currency or `%`)                                  | `min`, `max`, `decimalSeparator` (`'.'` or `','`)                                     |
| `checkbox`              | boolean                                                          | `true 1 yes y x ✓ si sí`, `false 0 no n` and empty                                      |                                                                                       |
| `singleSelect`          | an option's `value` or `null`                                    | an option's label (any case) or value                                                   | `options` (an array or a function of the record), `createOnPaste`                     |
| `date`                  | ISO `YYYY-MM-DD` or `null`                                       | `2026-11-19` (also with a time), `2026/11/19`, `19/11/2026`, `19-11-2026`, `19.11.2026` | `dateOrder` (`'dmy'` default, or `'mdy'`), `min`, `max` (ISO)                         |
| `multiSelect`           | an array of option values                                        | labels or values separated by `,` (a quoted part keeps its commas)                      | `options`, `createOnPaste`                                                            |
| `linkedRecord`          | an array of `{ id, label }`                                      | resolved by `@onResolve`                                                                | `search(query, { record, signal })`, `multiple` (default `true`)                      |
| `user`                  | `{ id, label, avatarUrl? }` or `null` (an array with `multiple`) | with `options`: a label or an `email`; else resolved by `@onResolve`                    | `options` or `search`, `multiple`                                                     |
| `attachment`            | an array of `{ id, name, url, type?, size?, thumbnailUrl? }`     | none (files are uploaded: picker, drop, pasted files)                                   | `upload(files, { record, field, signal, onProgress })`, `accept`, `maxFiles`          |
| `currency`              | number or `null`                                                 | `$1,234.50`, `MXN 12`, `12`                                                             | `currency`, `locale`, `precision`, `min`, `max`                                       |
| `percent`               | a fraction or `null`                                             | `25%` or `25` (both `0.25`)                                                             | `precision`, `min`, `max`                                                             |
| `duration`              | seconds or `null`                                                | `1:30`, `1:30:00`, `1h 30m`, `90` (minutes; seconds with `'h:mm:ss'`)                   | `durationFormat` (`'h:mm'` or `'h:mm:ss'`)                                            |
| `rating`                | 1 to `max`, or `null`                                            | `0` to `max`                                                                            | `max` (default 5)                                                                     |
| `url`, `email`, `phone` | string                                                           | anything (validated: a web address, `x@y.z`, digits and `+ ( ) -`)                      | `maxLength`                                                                           |
| `longText`              | string with line breaks                                          | anything                                                                                | `maxLength`                                                                           |
| `dateTime`              | a UTC ISO instant (`2026-11-19T15:30:00.000Z`) or `null`         | ISO with `Z` or an offset; ISO without, `19/11/2026 15:30`, `3:30 pm`: in the zone      | `timeZone` (`'local'`, `'utc'`, IANA), `dateOrder`, `hour12`, `seconds`, `min`, `max` |
| `button`                | none                                                             | none (paste, fill, clear and cut skip it)                                               | `buttonLabel`, `icon`, `color`, `disabled(record)`, `url(record)`                     |
| `barcode`               | string or `null`                                                 | anything, trimmed                                                                       | `pattern`, `patternMessage`, `formats`, `scan({ formats, signal })`                   |

Dates are shown as `DD/MM/YYYY` (or `MM/DD/YYYY`) and copied as ISO.

Multi-select: chips and a list editor (a click or Enter toggles, Tab or a
click elsewhere saves). Linked record and user: chips or avatars and a
picker over `search` (or `options`). Attachment: thumbnails, an editor with
links, remove buttons and a file picker; files dropped or pasted on a cell
are uploaded; a copy gives the URLs. Rating: stars, a click or a digit sets
it. URL, email, phone: link-styled text; a click on it opens the link in a
new tab (only `http:`, `https:`, `mailto:`, `tel:`), the row menu has "Open
link". Long text: a text area that grows from the cell; Shift+Enter or
Alt+Enter adds a line, Enter saves.

Date and time: shown in `timeZone` as `DD/MM/YYYY HH:mm` (or 12-hour,
seconds), copied as the ISO instant; typing opens a text input, Enter the
browser's date-and-time picker in the field's zone; a wall clock in a DST
gap moves forward, one in an overlap is the first. Button: a click on it,
or Enter or Space on the selected cell, calls `@onButtonPress({ recordId,
fieldId, record }, { signal })` (or opens `url(record)` without it); a
promise shows it pending, a rejection is the cell's error until the next
press; not a change set. Barcode: monospace text; a USB scanner types it;
with `field.scan` or the browser's `BarcodeDetector` the camera icon opens
a scan panel.

Array values are compared by content (`equals`); the sheet never changes a
value in place, and your store should not either.

### Bulk resolve

With `@onResolve`, a paste writes what it can at once and shows the cells
that need your API as pending; then the sheet calls `@onResolve` once, one
request per field (`{ fieldId, texts, cells }`), and writes the answers as
a second change set (source `'resolve'`), undone together with the paste.
A text answered `null`, or a call that rejects, is a rejection. Writing a
pending cell again drops its result; when no cell of a call is left, or
the sheet is destroyed, its `signal` is aborted.

```ts
onResolve = async (requests, { signal }) => {
  const result = {};
  for (const { fieldId, texts } of requests) {
    const found = await api.lookup(fieldId, texts, { signal });
    result[fieldId] = Object.fromEntries(
      texts.map((t) => [t, found.find((r) => r.label === t) ?? null])
    );
  }
  return result;
};
```

## Keyboard

| Key                                            | On a cell                                                                                                                                                | In an editor                                                    |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| A printable key                                | Opens the editor with that character (a date: digits only; never on a checkbox)                                                                          | Types                                                           |
| Enter, F2, double-click                        | Opens the editor on the current value (a date: the browser's date input)                                                                                 | Enter saves and goes down                                       |
| Tab, Shift+Tab                                 | The grid's                                                                                                                                               | Saves and goes right / left                                     |
| Escape                                         | The grid's                                                                                                                                               | Closes without saving                                           |
| Space                                          | Toggles a checkbox; presses a button; elsewhere expands the record                                                                                       | Types                                                           |
| Alt+Shift+ArrowUp/Down                         | With `@canMove`, on a row number (or with whole rows selected): moves the rows one record                                                                |                                                                 |
| A digit                                        | Sets a rating (0 clears)                                                                                                                                 |                                                                 |
| Shift+Enter                                    | Adds a record below (as Enter when inserting is off)                                                                                                     | Saves and goes down; in long text, adds a line (also Alt+Enter) |
| Shift+F10, ContextMenu                         | Opens the row menu                                                                                                                                       |                                                                 |
| Home, Ctrl+Home                                | The first field of the row, of the sheet (ArrowLeft from it: the row number)                                                                             | Native                                                          |
| Delete, Backspace                              | Clears the selected range                                                                                                                                | Deletes                                                         |
| Shift+arrows                                   | Selects a range                                                                                                                                          | Moves in the text                                               |
| Ctrl/Cmd+A                                     | Selects every cell (focus stays)                                                                                                                         | Native                                                          |
| Ctrl/Cmd+C, Ctrl/Cmd+V                         | Copies / pastes the range as TSV (cells with tabs or line breaks quoted, as Excel does)                                                                  | Native                                                          |
| Ctrl/Cmd+D                                     | Fill down: each column's top value into the range's cells below it; on one row, the value of the cell above                                              | Native                                                          |
| Ctrl/Cmd+R                                     | Fill right: each row's left value into the range's cells right of it; on one column, the value of the cell to its left (taken from the browser's reload) | Native                                                          |
| Ctrl/Cmd+X                                     | Cut: copies the range, then clears it (one undo step; with `@readOnly` it only copies)                                                                   | Native                                                          |
| Ctrl/Cmd+arrows                                | Jumps to the edge of the data (Excel's rule); with Shift, extends the range to it                                                                        | Native                                                          |
| Shift+Home, Shift+End; Ctrl/Cmd+Shift+Home/End | Extends the range to the row's first or last field; to the first, or the last record's last, cell                                                        | Native                                                          |
| PageUp, PageDown                               | Moves by the rows in view; with Shift, extends the range                                                                                                 |                                                                 |
| Ctrl/Cmd+Z; Ctrl/Cmd+Shift+Z, Ctrl+Y           | Undo; redo                                                                                                                                               | Native                                                          |
| Ctrl/Cmd+/                                     | Opens the shortcut list (also on a row number or a header)                                                                                               |                                                                 |
| Space on a header                              | Lifts the column: the arrows move it, Space drops it, Escape cancels (Enter opens the header menu)                                                       |                                                                 |

In a select editor, typing filters the options, ArrowUp/ArrowDown move,
Enter or a click picks. A click on another cell saves the editor's text and
closes it; so does a scroll that takes the edited cell out of view (a scroll
that keeps it in view moves the editor with it).

A paste starts at the selection's top-left cell. When the selection is
larger than the copied block and its height and width are whole multiples
of the block's, the block is repeated over the whole selection (one copied
cell fills every selected cell); otherwise it is pasted once. Read-only
cells are skipped. Fill down copies the stored values as they are (no
parsing) and also skips read-only cells.

## Mouse

As in Airtable: a click selects a cell, a click on the selected cell edits
it, a double-click edits at once, and Shift+click extends the range. A click
on a row number or a column title selects the row or column, the row's
checkbox and expand icon do what they show, a click on the last row adds a
record, and a right-click opens the row menu (see Records).
Pressing on a cell and dragging over others selects that range; the release
neither edits nor toggles a checkbox, and Shift+arrows continue from it. The
active cell (the ring) stays where the range started; only its far corner
moves. A right-click on a header opens the header menu. A copy marks the
copied cells dashed until Escape or a change.
Holding the pointer near the grid's edge, or past it, scrolls it and the
range follows. The fill handle (the square at the range's bottom-right
corner) fills the cells it is dragged over: a constant number step or a date
step continues (`1, 2` → `3, 4`; one date goes on by a day), anything else
repeats; Ctrl or Alt held at the release repeats; Escape cancels. Values are
copied by reference (do not mutate them); across types they go through text,
like a paste. Select
and date cells show a ▾ or calendar button on the hovered or selected cell
that opens the editor in one click; a click anywhere in a checkbox cell
toggles it. A click on a rating's star sets it; a click on a link's text
opens it (a click beside it selects). Files dragged onto an attachment cell
are uploaded; an `upload` that calls `onProgress(fraction)` shows a bar
along the cell's bottom edge, and a progress bar in the editor and the
expanded record. A field type gets the same with two optional properties:

```ts
const zoneType: EuiSheetFieldType<Zone | null> = {
  // …parse, format, editor…
  opener: 'arrowDown' // an EUI icon type: a button that opens the editor
};

const ratingType: EuiSheetFieldType<number | null> = {
  // …
  onCellClick: (value) => ({ value: ((value ?? 0) % 5) + 1 }) // a click saves this value
};
```

## Errors

A cell with errors has a red border and the messages as its title. While
it has focus (and no editor is open), the messages also show in a box
under the cell, inside a `role="status"` region so screen readers
announce them.

- **Rejections**: a text the type cannot read. No patch; the cell shows the
  text, marked invalid, with the message as its title.
- **Validation errors**: a stored value that breaks a rule: `required`, the
  type's rules (`min`, `max`, `maxLength`, `pattern`, an unknown option, a
  bad date), and your `field.validate(value, record)`. They never block a
  change.
- **`@validate`**: rules that need the record or other rows, sync or async.
  It runs on the first render, when `@records` changes and after each
  change set (debounced). A newer run aborts the older one's `signal`, and
  a late result of an older run is discarded:

  ```ts
  validate = async ({ records, changed, signal }) => {
    const errors = {};
    for (const r of records) {
      if (r.end && r.start && r.end < r.start) {
        errors[r.id] = { end: 'Must be after the start date' };
      }
    }
    const taken = await fetch('/api/check-emails', {
      signal,
      method: 'POST',
      body: JSON.stringify(records.map((r) => r.email))
    }).then((res) => res.json());
    for (const id of taken)
      errors[id] = { ...errors[id], email: 'Already registered' };
    return errors;
  };
  ```

- **`@cellErrors`**: your own errors, shown last.

A cell shows its messages in order: rejection (or required, type and field
rules), `@validate`, `@cellErrors`. A rejected cell shows only its
rejection and `@cellErrors` (the other rules would describe the old value).

## Messages and translations

The built-in messages go through `@ember-eui/core`'s `eui-i18n` service,
like EUI's own, with English defaults and these tokens:
`euiSheet.required`, `euiSheet.notANumber` (`{text}`),
`euiSheet.notACheckbox` (`{text}`), `euiSheet.notAnOption` (`{text}`),
`euiSheet.notADate` (`{text}`), `euiSheet.min` (`{min}`), `euiSheet.max`
(`{max}`), `euiSheet.maxLength` (`{max}`), `euiSheet.pattern`,
`euiSheet.unresolved` (`{text}`), and for records `euiSheet.addRecord`,
`insertAbove`, `insertBelow`, `duplicateRecord`, `duplicateRecords`
(`{count}`), `expandRecord`, `copyRow`, `copyRows` (`{count}`),
`deleteRecord`, `deleteRecords` (`{count}`), `selectRow`, `selectAllRows`,
`rowNumber` (`{n}`), `recordTitle` (`{n}`), `previousRecord`, `nextRecord`,
`close`, `filterByField`, `reapply` (the EmberSearchUi connector's
button), and for the field types of v0.2 `notAnAttachment`, `uploadFailed`,
`notAUrl` (`{text}`), `notAnEmail` (`{text}`), `notAPhone` (`{text}`),
`notADuration` (`{text}`), `openLink`, `removeFile`, `addFiles`,
`loading`, `noMatches`, `searchFailed`, and for v0.4 `fitToContent`,
`fitAllFields`, `enterFullScreen`, `exitFullScreen`, `copyWithFieldNames`
(all under `euiSheet.`; `sheetMessageTokens` lists every one).

```ts
this.euiI18n.addTranslations({
  euiSheet: { required: 'Obligatorio', notANumber: '"{text}" no es un número' }
});
```

`@messages` (for example `{ required: () => 'Falta' }`) wins over the
translations, for one sheet.

## Custom field types

A field type is an object: `parse(text, field, context)` returns
`{ value }`, `{ error }` (a rejection) or `{ unresolved }`; `format(value,
field, context)` gives the cell's text; optional `copyText`, `validate`,
`isEmpty`, `compare`, `toNumber` (for `summarize`), `navKey` (a key that
sets the value without an editor), `equals(a, b)` (needed for array or
object values), `resolve: { parts, combine }` (how a cell's text splits for
`@onResolve`, and how the answers make its value; default: one part, its
value), `link(value, field)` (the link a click opens), and
`series(samples, count, field, direction)` (the values the fill handle
continues `samples` with, nearest first; `undefined` repeats them). The Ember layer
adds optional components and key rules:

| Key                 |                                                                                                                                                                                                                                                                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cell`              | Display component: `@value @text @field @record @errors @readOnly @onCommit(value) @highlight @link`. It must not render a tabbable element (a link is a `<span role="link" data-eui-sheet-link>`, never `<a href>`).                                                                                                             |
| `editor`            | Editor component: `@value @field @record @draft @initialKey @onDraftChange(text) @onDraftValue(value) @onSave(value) @onUpload(files) @onCommit(result?, { move? }) @onCancel @messages @themeClass`. It focuses itself when inserted. `@onDraftValue` reports a value to save when focus leaves; `@onSave` saves and stays open. |
| `editorLayout`      | `'cell'` (over the cell, default), `'panel'` (a panel below or above it) or `'expand'` (from the cell's box, growing).                                                                                                                                                                                                            |
| `opensOnKey(key)`   | Whether a printable key opens the editor.                                                                                                                                                                                                                                                                                         |
| `handlesKey(event)` | Keys the open editor handles itself (the sheet then leaves them alone; Enter, Tab and Escape are otherwise the sheet's).                                                                                                                                                                                                          |
| `schema`            | The grid schema of the column (`'numeric'`, `'datetime'`, `'boolean'`, `'currency'`): the column menu's sort labels and the alignment. Built-ins: number, date, checkbox.                                                                                                                                                         |

Register types with `@fieldTypes={{this.fieldTypes}}` and use them with
`type: 'name'`. An editor that renders part of itself elsewhere (a
wormholed list or calendar) marks that part with the class
`euiSheetEditorSurface` or the attribute `data-eui-sheet-editor-surface`,
so focus moving there does not close it.

A Prysmex-style zone picker with async search:

```ts
import type { EuiSheetFieldType } from '@ember-eui/sheet';
import ZoneEditor from './zone-editor.gts';

type Zone = { id: string; label: string };

export const zoneType: EuiSheetFieldType<Zone | null> = {
  parse: (text) =>
    text.trim() === '' ? { value: null } : { unresolved: text.trim() },
  format: (value) => value?.label ?? '',
  isEmpty: (value) => value == null,
  editor: ZoneEditor, // an EuiSelectable with @isPreFiltered, loading from the store
  editorLayout: 'panel',
  handlesKey: (e) => ['Enter', 'ArrowUp', 'ArrowDown'].includes(e.key)
};
```

The built-in types are exported (`textType`, `numberType`, `checkboxType`,
`singleSelectType`, `dateType`, `multiSelectType`, `linkedRecordType`,
`userType`, `attachmentType`, `currencyType`, `percentType`, `durationType`,
`ratingType`, `urlType`, `emailType`, `phoneType`, `longTextType`, and
`builtInSheetFieldTypes`) so you can change one part of them.

## Using another date picker (e.g. @ember-eui/flatpickr)

The date type's editor is the browser's `<input type="date">` (and a text
input when the user starts by typing a digit). To use another picker, keep
the date type and replace its editor under the `date` name (or register it
under another name):

```gts
import Component from '@glimmer/component';
import { dateType, SheetInputEditor } from '@ember-eui/sheet';
import type { SheetEditorSignature } from '@ember-eui/sheet';
import EuiFlatpickr from '@ember-eui/flatpickr/components/eui-flatpickr';

class FlatpickrDateEditor extends Component<
  SheetEditorSignature<string | null>
> {
  // flatpickr appends its calendar to <body>: mark it as part of the editor
  onReady = (
    _dates: Date[],
    _text: string,
    instance: { calendarContainer: HTMLElement }
  ) => instance.calendarContainer.classList.add('euiSheetEditorSurface');

  // the editor focuses itself when inserted
  focus = (input: HTMLInputElement) => input.focus();

  pick = (_dates: Date[], iso: string) =>
    this.args.onCommit({ value: iso || null });

  <template>
    {{#if @initialKey}}
      {{! typing a digit: the text input, parsed by the date type }}
      <SheetInputEditor
        @value={{@value}}
        @field={{@field}}
        @record={{@record}}
        @draft={{@draft}}
        @initialKey={{@initialKey}}
        @onDraftChange={{@onDraftChange}}
        @onCommit={{@onCommit}}
        @onCancel={{@onCancel}}
        @messages={{@messages}}
        @themeClass={{@themeClass}}
      />
    {{else}}
      <EuiFlatpickr
        @date={{@value}}
        @dateFormat='Y-m-d'
        @inputRef={{this.focus}}
        @onReady={{this.onReady}}
        @onChange={{this.pick}}
      />
    {{/if}}
  </template>
}

export const fieldTypes = {
  date: { ...dateType, editor: FlatpickrDateEditor }
};
```

```gts
<EuiSheet @fieldTypes={{fieldTypes}} … />
```

The value stays an ISO date, so parsing, display, copy and paste are the
date type's. Check the argument names against the `@ember-eui/flatpickr`
version you use; this package does not depend on it.

## Touch and IME

On touch screens a tap selects and a tap on the selected cell edits, a drag
scrolls, and a long press opens the row menu (with Copy and Paste on a
range). After a tap the cell has two round handles at its corners: drag
them to extend the range (they never show after a mouse press). The ▾ buttons, row checkboxes and expand icons are always shown there,
with 32 px touch areas, and the fill handle is not. `@editIn` (default
`'auto'`) edits in the expanded record on a touch screen narrower than
600 px. Dead keys and IMEs compose in a hidden input over the cell, so the
editor opens with the composed text (`é`, `日本`). Neither was tried on real
devices or real IMEs yet.

## Limits

No row or column drag by touch, floating (zoneless) date-times or undo of
field operations yet. Sorting, filtering, search and paging
are the owner's (see above, and the EmberSearchUi connector).
