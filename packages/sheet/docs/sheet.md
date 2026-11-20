---
title: Sheet
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet"/>
<EuiSpacer @size="l" />

<EuiText>

`@ember-eui/sheet` is an Airtable-like grid for data entry, built on
`EuiDataGrid`. People edit cells with the keyboard, select ranges, and
copy and paste blocks to and from Excel or Google Sheets. It has
built-in field types for text, numbers, checkboxes, selects, dates,
linked records, users, attachments, currency, percent, duration, rating,
links and long text, and you can add your own cells and editors.

```bash
pnpm add @ember-eui/sheet
```

`@ember-eui/core` is a peer dependency: install and set it up first. The
sheet adds its few styles to the page itself; there is no stylesheet to
import.

## Records in, change sets out

The sheet is controlled. You pass `@records` and `@fields`; the sheet
never changes your records. When someone types, clears or pastes, it
calls `@onChange` with a change set, and you apply it to your own store:

```ts
interface ChangeSet {
  source: 'edit' | 'paste' | 'clear' | 'fill' | 'undo' | 'redo'
    | 'insert' | 'delete' | 'cut' | 'resolve';
  patches: { recordId; fieldId; from; to }[]; // cells of existing records
  inserts: {
    tempId; index; values; // rows pasted past the end, restored rows
    anchor?: { recordId; position: 'before' | 'after' }; // its neighbour
    restore?: { recordId; record }; // an undone delete: the record it was
  }[];
  deletes?: recordId[]; // records to remove
  removed?: { recordId; index; after?; record }[]; // what a delete removed
  rejected: { recordId?; tempId?; fieldId; text; message }[];
  newOptions: { fieldId; option }[]; // options created on paste
}
```

`insert` comes from the add row, Shift+Enter and the row menu (insert,
duplicate), `delete` from the row menu: apply them like the others
(`applyChangeSet` and `localRecords` do). The `cut` and `resolve` sources
are for features that are coming (cut, bulk resolve); your code should
accept them already.

For local data, or a page without a store, `localRecords` is a small
tracked store that applies change sets for you:

```gjs
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'name', label: 'Task', required: true },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'done', label: 'Done', type: 'checkbox' },
];

export default class Tasks extends Component {
  getId = (task) => task.id;
  store = localRecords(
    [{ id: 't1', name: 'Inspect line 3', hours: 2, done: false }],
    { getRecordId: this.getId, fields: FIELDS },
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

With your own store, `applyChangeSet(records, changeSet, { getRecordId,
createRecord?, restoreRecord? })` returns the new records (patched
records are new objects, the others keep their identity), and
`applyNewOptions(fields, changeSet)` returns the fields with the options
created on paste. Both are pure, and are also exported from
`@ember-eui/sheet/core`, which has no Ember imports.

A pasted row past the end comes as an insert with a `tempId`. By default
`applyChangeSet` uses the `tempId` as the new record's `id`. Where it
goes:

- `index` is the record's position in the records the sheet was given
  (`@records`), counted after the change set's deletes and with the
  inserts applied in ascending `index`. An index past the end appends.
- `anchor` is its neighbour in `@records` when the insert was made: a
  pasted row is anchored after the last record (and each next one after
  the previous). If your data is larger than what the sheet shows (one
  page of it, sorted elsewhere), position by the anchor: `applyChangeSet`
  does, before the index, and it also finds an anchor that is the
  `tempId` of an insert earlier in the same change set.
- `restore` is set when an undo puts back a deleted record: `record` is
  the object it was, which `applyChangeSet` puts back as it is (pass
  `restoreRecord(insert)` to build it yourself, for example when your
  server gives it a new id; `insert.values` has its field values).

When your store gives a new record another id (a server's id), tell the
sheet with `api.remapIds({ [tempId]: newId })` (below), so that undo
still finds it.

With `@canMove`, a row drag (Records, below) emits `source: 'move'` and
`moves`: one `{ recordId, anchor?, groupKey?, from }` per moved record,
in their final order. Apply them in order: take the record out and put
it back before or after `anchor.recordId` (the first move is anchored to
a record that does not move, each next one after the previous). A move
without an anchor goes into `groupKey`, a group with no loaded record to
anchor to; its patches already wrote the group's values. `from` (the
record before it and its group) is what undo uses. `applyChangeSet` and
`localRecords` apply moves; an owner that ignores them shows nothing
moving, which is why row drag is opt-in. Keep the order in your data: an
order column, or fractional positions (a move then writes one record).

## Undo and redo

Ctrl/Cmd+Z undoes the last change made in the sheet (an edit, a paste, a
clear, a fill, a checkbox toggle, an insert, a duplicate, a delete or a
move of records); Ctrl/Cmd+Shift+Z and Ctrl+Y redo it.
The sheet keeps the last 100 change sets it emitted, per sheet, and an
undo is one more change set through `@onChange`: `source: 'undo'`, each
patch with `from` and `to` swapped, and the rows a paste inserted listed
in `deletes` (a redo emits the original again, `source: 'redo'`, with the
same `tempId`s). `applyChangeSet` and `localRecords` apply `deletes`; with
your own store, remove those records.

- An undo or redo only writes cells that still hold the value the change
  left there. A cell you changed since (from your store, a server or
  another user) is skipped; if nothing is left, nothing is emitted.
- An inserted row is found by its `tempId`. If your store gives the new
  record another id, call `api.remapIds({ [tempId]: newId })`, before or
  with the `@records` that carry the new id, and undo finds it again;
  without it, the row is not removed by undo (it is skipped). A row
  changed since it was inserted is not removed either.
- An undo of a delete puts each record back after the neighbour it had,
  even when your records were re-sorted since. An undo of a move moves
  each record back after the record that was before it (or first), in
  the same order, with the group values it had. A redo of a delete names
  the record's id; if your server gave the restored record a new id,
  call `remapIds` for it too.
- A change whose records are not in `@records` any more (another page, a
  filter) is skipped, and stays on the stack: Ctrl/Cmd+Z does nothing
  until those records are back (the page where you made it), then undoes
  it. Call `api.clearHistory()` when your data changes wholesale (or on a
  page change, if you prefer that).
- Rejected texts are part of the change that made them: undoing a paste
  also removes the texts it could not read (the cells show their values
  again, without the red border), and a redo shows them again on the
  cells that still hold the value they had. A paste where every cell was
  rejected is undone too. The owner gets no change set for that part
  (nothing in the data changes).
- Options created on paste (`createOnPaste`) stay after an undo.
- Changes to `@records` made outside the sheet are not undone, a new
  change clears the redo history, and with `@readOnly` undo and redo do
  nothing. In an open editor, Ctrl/Cmd+Z is the input's own undo.

## Arguments

| Argument | Description |
| --- | --- |
| `@fields` | The visible columns, in order: `{ id, label?, type?, readOnly?, required?, validate?, description?, width?, sortable?, hideable?, manageable?, ...options of the type }`. `readOnly` and `required` can be functions of the record. `description` is a tip in the header and help text in the expanded record; `width` a default width in px; `sortable: false` and `hideable: false` drop those menu items; `manageable: false` drops Edit, Duplicate and Delete field (a system field); `groupable: false` drops "Group by this field". |
| `@records` | The rows. Pass a new array when they change. |
| `@getRecordId` | `(record) => id`. |
| `@onChange` | `(changeSet) => void`. Apply it to your records. |
| `@validate` | Record, cross-row and server rules: `({ records, changed, signal }) => errors`, sync or async. |
| `@cellErrors` | Your own errors: `{ [recordId]: { [fieldId]: message or messages } }`. |
| `@fieldTypes` | Your field types, merged over the built-in ones. Keep the object stable (not created in a template). |
| `@readOnly` | Every cell read-only. Copy still works. |
| `@messages` | Overrides of the built-in messages, for this sheet. |
| `@height` | The grid's height. |
| `@ariaLabel` | The grid's accessible name. Default `Sheet`. |
| `@registerApi` | `(api) => void`: receives the sheet's API once, after the first render (below). |
| `@hiddenFields` | Fields that exist but are not columns: shown in the expanded record after `@fields`, copied by duplicate, put back by undo, given to the blocks (`showField`). |
| `@onHiddenFieldsChange` | `(fieldIds) => void`: the new list of hidden ids after "Hide column" or a block's `hideField` / `showField`. With it, update `@fields` and `@hiddenFields`; without it the sheet hides and shows fields itself. |
| `@onFieldOrderChange` | `(fieldIds) => void`: the visible ids in their new order after "Move left/right" or a header drag. With it, update `@fields`; without it the sheet keeps its own order. |
| `@fieldDrag` | Drag a header to reorder the fields (also Space, the arrows and Space on a focused header). Default `true`; `false` turns it off. |
| `@headerLines` | `1` (default), `2` or `3`: the lines a header label may wrap to. The header row grows to fit; a cut label keeps its full text as the header's tooltip. |
| `@fieldWidths`, `@onFieldWidthChange` | Widths in px by field id (over `field.width`); `(fieldId, width) => void` after a resize. Without the handler the sheet keeps a resized width itself, also when the columns are hidden, shown or moved; keep them in `@fieldWidths` to keep them across renders of the sheet. |
| `@rowHeight`, `@onRowHeightChange` | `'short'` (default, one line), `'medium'` (2 lines), `'tall'` (4), `'extraTall'` (6); changed by a block's `setRowHeight`. With the handler, update `@rowHeight`. |
| `@sort`, `@onSortChange` | Your sort, `[{ field, direction: 'asc' or 'desc' }]`, drawn as header arrows; the menu's "Sort" items call the handler with the whole new sort. Without the handler there are no sort items and no arrows. The sheet never sorts. |
| `@onFilterByField` | `(fieldId) => void`: adds "Filter by this field" to the column menu. |
| `@groups` | The group headers to draw, depth-first in display order (Group by, below). Absent or empty: no groups. |
| `@groupBy` | Your group-by, `[{ field, direction }]`, outermost first: picks the header menu item and names the header labels. |
| `@onGroupByChange` | `(groupBy) => void`: adds "Group by this field" (and "Remove grouping" on a grouped field) to the column menu. |
| `@onGroupToggle` | `(key, collapsed) => void`: gives each group header its toggle. |
| `@onFieldCreate` | `(draft, { index, after?, copyOf? }) => void or Promise`: adds the "+" column at the right, "Insert left/right" and "Duplicate field" to the column menu (Fields, below). |
| `@onFieldUpdate` | `(fieldId, draft, { previous }) => void or Promise`: adds "Edit field". |
| `@onFieldDelete` | `(fieldId) => void or Promise`: adds "Delete field", after a confirmation. |
| `@fieldEditor` | A component that replaces the field editor's content (the sheet keeps its frame). |
| `@creatableFieldTypes` | The types the field editor offers, in order. Default: `text`, `longText`, `number`, `currency`, `percent`, `checkbox`, `singleSelect`, `multiSelect`, `date`, `duration`, `rating`, `url`, `email`, `phone`. `dateTime`, `button` and `barcode` have their options there too (zone, clock and seconds; text, icon and colour); list them to offer them. |
| `@highlight` | A term you searched for: matching text is marked in cells (any case, every match). |
| `@currentMatch` | `{ recordId, fieldId }` or `null`: your current search match. When it changes the sheet scrolls it into view and rings it, without moving focus or the selection (Search matches, below). |
| `@onSelectionChange` | `(selection or null) => void`: the selected cells' records and fields, after render, when they change (Summary bar, below). |
| `@isLoading` | A thin progress bar over the grid; the grid stays usable. |
| `@summary` | `{ [fieldId]: text }` (and `''` for the row-number column): shows the summary bar (below). |
| `@frozenFields` | Leading fields kept in view on horizontal scroll, with the row numbers. Default `0` (off); `1` freezes the first field. |
| `@rowNumbers` | The row-number column. Default `true`; `false` hides it. |
| `@rowLabel` | `(record, position) => string`: what a row number shows instead of its position (for example the record's id). The column widens to fit. |
| `@rowNumberOffset` | The position of the first record when `@records` is one page of your data: page 2 of 50 passes `50`. Default `0`. |
| `@canInsert`, `@canDelete` | The add row (grouped: the groups' add rows), Shift+Enter and the menu's insert and duplicate; the menu's delete. Default: `!@readOnly`. Without inserting, a paste stops at the last record. |
| `@canMove` | Row drag (Records, below): a grip in each row number, and Alt+Shift+ArrowUp/Down, emit change sets with `moves`. Off with `@readOnly`, a non-empty `@sort` or `@rowNumbers={{false}}` (the keys and `api.moveRecords` need no row numbers). Default `false`. |
| `@rowColor` | `(record) => colour or undefined`: a 4 px bar at the row's left edge (Theme, below). `colorByOption(field)` colours by a select's options. |
| `@onButtonPress` | `({ recordId, fieldId, record }, { signal }) => void or Promise`: a button field's press (Field types, below), for every button field. |
| `@newRecordValues` | `({ above, below }) => values`: the values of a new record, from its neighbours. Default `{}`. |
| `@checkedRecordIds`, `@onCheckedChange` | The checked rows. With the handler, the sheet shows exactly `@checkedRecordIds` and calls the handler with the new list; without it, it keeps its own. |
| `@expandedRecordId`, `@onExpandedRecordChange` | The expanded record, controlled the same way. |
| `@expandedRecord` | `'flyout'` (default) or `'modal'`. |
| `@rowActions` | Your items of the row menu: `{ id, label, icon?, color?: 'danger', isDisabled?(records), onSelect(records) }`. |
| `@onResolve` | `(requests, { signal }) => Promise<result>`: resolves typed or pasted text of linked-record, user and your own types through your API (bulk resolve, below). Without it such text is rejected. |
| `@editIn` | Where a click on the selected cell, or Enter, edits: `'cell'` (the editor over the cell), `'record'` (the expanded record, with that field's editor open), or `'auto'` (default: the record on a touch screen when the sheet is narrower than 600 px, else the cell). Typing on a cell always edits in the cell. |

## The owner

The sheet is a view of the rows it is given. It never sorts, filters,
searches, groups, pages or summarizes: those are queries, and they are
yours (a store, a server, an EmberSearchUi driver). The sheet draws your
state and tells you what the user asked for:

| The user | The sheet calls | You |
| --- | --- | --- |
| Sort from a column's menu | `@onSortChange(sort)` | sort `@records`, pass `@sort` (the arrows) |
| "Group by this field", "Remove grouping" | `@onGroupByChange(groupBy)` | group `@records`, pass `@groups` and `@groupBy` |
| Collapses or expands a group | `@onGroupToggle(key, collapsed)` | drop or add its records, pass the header with `collapsed` |
| "Filter by this field" | `@onFilterByField(fieldId)` | open your filter UI |
| Types in your search box | (nothing: the box is yours) | filter `@records`, pass `@highlight` |
| Steps to the next match in your box | (nothing) | pass `@currentMatch` (expand its group or change the page first) |
| Selects cells | `@onSelectionChange(selection)` | show a summary of the selection (`summarizeCells`) |
| Changes page in your pager | (nothing) | pass that page as `@records`, and `@rowNumberOffset` |
| Waits | | pass `@isLoading` |
| Drags a row (with `@canMove`) | `@onChange` with `moves` | put the records in the new order, pass them |
| Presses a button cell | `@onButtonPress({ recordId, fieldId, record }, { signal })` | run your action; a promise shows it pending, a rejection as the cell's error |
| Hides, moves, resizes a column | `@onHiddenFieldsChange`, `@onFieldOrderChange`, `@onFieldWidthChange` | update `@fields`, `@hiddenFields`, `@fieldWidths` |
| Picks a row height in your control | `@onRowHeightChange` (through the block's `setRowHeight`) | update `@rowHeight` |

There is no built-in toolbar. Two blocks take your own controls, inside
the sheet (so they get its theme) and outside the grid (so they are normal
tabbable elements):

```gjs
<EuiSheet @fields={{this.fields}} @records={{this.records}} …>
  <:toolbar as |sheet|>
    {{! a search box, a field picker, a row-height control }}
  </:toolbar>
  <:footer as |sheet|>
    {{! a pager, a count }}
  </:footer>
</EuiSheet>
```

Each yields the same object: `api` (the sheet's API, below), `fields` (the
visible ones), `hiddenFields`, `sort`, `rowHeight`, `checkedRecords`,
`selection` (the selected cells, or `null`; Summary bar, below), `groupBy` and `groups` (`@groupBy` and `@groups`, or `[]`), and
`hideField(id)`, `showField(id)`, `setRowHeight(rowHeight)`,
`setSort(sort)`, `setGroupBy(groupBy)` and `toggleGroup(key)`, which call
your handlers (or change the sheet's own state without them; `setSort`,
`setGroupBy` and `toggleGroup` do nothing without `@onSortChange`,
`@onGroupByChange` and `@onGroupToggle`).

### Search matches

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

Sorting a local array needs a few lines in your component (the "View
intents" example does it with each type's `compare`). For filtering,
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
  skipped and stays on the stack (see "Undo and redo").
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
- `EuiSheetSearch` passes the other `EuiSheet` arguments through
  (`@hiddenFields`, `@readOnly`, `@validate`, `@registerApi`, ...). For an
  argument it does not take, use `searchRecords(this, driver, { getRecordId,
  onChange })` with your own `<EuiSheet>`: its properties are the
  arguments (`@records={{search.records}}`, `@onChange={{search.apply}}`,
  `@sort`, `@onSortChange={{search.setSort}}`, `@highlight={{search.term}}`,
  `@isLoading`, `@rowNumberOffset`). It unsubscribes when `this` is
  destroyed and never destroys the driver.

The "Sheet with EmberSearchUi" example below uses EmberSearchUi's own
views (search box, sort menu, filter bar, chips, paging info) in the
blocks.

## Presentation state

Which fields show, their order, their widths and the row height work the
same way: **with a handler, the sheet shows exactly the argument** and only
calls the handler, so if you pass the handler and do not update the
argument, nothing changes on screen (in development the sheet warns once).
**Without a handler, the sheet keeps its own state**, so a sheet with only
`@fields` still lets people hide, move and resize columns: "Hide column"
really hides (the field goes to the hidden list and the expanded record),
and copy and paste skip hidden fields. The first field cannot be hidden or
moved, and nothing can move before it.

Drag a header to move its field (`@fieldDrag`, on by default): the drop
calls `@onFieldOrderChange` with the new order, as "Move left/right" does,
or moves the column itself without the handler. A drop before the first
field puts the field second. With the keyboard, focus a header, press
Space, move it with the arrows and press Space to drop it (Escape
cancels); Enter still opens the header menu. A click on a title still
selects the column. Drags start from a mouse or a pen, not a touch: on a
phone use the menu's "Move left/right". The row-number column cannot be
dragged. `@fieldDrag={{false}}` gives the header the DOM of v0.2 (no drag
wrappers; the column resizer inside the header cell).

`@headerLines={{2}}` (or `3`) lets long header labels wrap instead of
being cut, independently of `@rowHeight`: the header row grows and the
rows start below it.

## Summary bar

Pass `@summary` (even `{}`) to show a footer row under the grid: each
field's text under it, and `@summary['']` under the row numbers (a count,
say). The cells are plain text: no editing, no selection. The sheet
computes nothing, because with paged data a summary of the loaded page
would be wrong: take the values from your backend (its aggregations), or,
when you have every record, compute them with `summarize`:

```js
import { builtInFieldTypes, defaultMessages, summarize } from '@ember-eui/sheet';

summarize({ types: builtInFieldTypes, messages: defaultMessages }, records, field, 'sum');
```

The kinds are `count`, `filled`, `empty`, `percentFilled`, `unique`,
`sum`, `average`, `min`, `max`, `checked` and `unchecked`. Sums and
averages use the type's `toNumber` (numbers have it), minimum and maximum
`toNumber` or else `compare` (dates, text), and the text is formatted with
the type's `format`. What to summarize is your control, in `<:toolbar>`
or `<:footer>`.

**A summary of the selection.** The blocks' `selection`,
`api.getSelection()` and `@onSelectionChange` give the selected cells:
`{ kind: 'cells' or 'rows' or 'columns', records, recordIds, fields,
cellCount }`, records in the order shown and the visible fields in
display order. A focused cell is a selection of one cell; group headers
and add rows inside a range are not in it, and the checked rows stay
separate (`checkedRecords`). `@onSelectionChange` is called after the
render, at most once per run loop, when the record ids, the field ids or
the kind changed (`null` when there is none), so a drag reports each new
rectangle once: keep it cheap, or debounce it. The sheet aggregates
nothing: call `summarize` per field, or `summarizeCells` for one figure
over every cell, as Airtable's bar does:

```js
import { summarizeCells } from '@ember-eui/sheet';

summarizeCells(ctx, selection, 'sum'); // 'count', 'filled', 'sum', 'average', 'min', 'max'
```

Numbers go through each type's `toNumber`; with one field the result
has its `format` (a currency, a percent), with several it is a plain
number with at most two decimals; `''` when no cell has a number. A
selection holds loaded records only, so its summary is exact; a summary
of "all" is yours (`@summary`).

## Group by

The sheet draws groups; it never groups. Like a sort or a page, grouping
is a query, and it is yours: you pass the headers in `@groups` and the
records of the expanded groups in `@records`, in display order. The
sheet tells you what the user asked for: `@onGroupByChange` from the
column menu, `@onGroupToggle` from a header. `localRecords` does all of
it for local data:

```gjs
import { EuiSheet, localRecords } from '@ember-eui/sheet';

class Tasks extends Component {
  store = localRecords(TASKS, {
    getRecordId: (task) => task.id,
    fields: FIELDS,
    groupBy: [{ field: 'status', direction: 'asc' }],
    summaries: { hours: 'sum' }
  });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.view.records}}
      @groups={{this.store.view.groups}}
      @groupBy={{this.store.groupBy}}
      @onGroupByChange={{this.store.setGroupBy}}
      @onGroupToggle={{this.store.toggleGroup}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
    />
  </template>
}
```

`store.view` is `{ records, groups }`, regrouped whenever the records,
the group-by or the collapsed groups change (`store.collapsedGroups`, a
set of keys). It needs `fields`: they are how it finds each level's
type. Without a group-by it is the records and no groups.

### The contract

```ts
interface SheetGroupBy { field: string; direction: 'asc' | 'desc' } // one per level, outermost first

interface SheetGroup {
  key: string;          // your id for the group: unique, the same after a re-query
  depth: number;        // 0 for the outermost level: the group belongs to @groupBy[depth]
  value: unknown;       // the value its records share; a record added to the group gets it
  label?: string;       // default: the field type's format(value), or "(Empty)"
  count: number;        // records in the group in your whole data (all pages, collapsed or not)
  loaded?: number;      // how many of @records, taken in order, are directly under it (default 0)
  collapsed?: boolean;  // drawn closed: its records are not in @records, its child groups not in @groups
  summary?: Record<string, string>; // text per field id, in the header row under that column
  rowNumberStart?: number; // the row number of its first loaded record
  continued?: boolean;  // it began on an earlier page: the label says so
}
```

The sheet walks `@groups` once: a header row for the group, then its next
`loaded` records of `@records`, then, when inserting is allowed, the group
is expanded and it is a leaf (the next group is not deeper), an add row.
It reads nothing from the records: it compares no value, counts nothing
and reorders nothing, so the counts are yours. That is also why an edit
of the group field does not move the record at once: the sheet shows
your last answer until you group again (`localRecords` regroups at once).
If the `loaded` add up to fewer than `@records`, the rest are drawn in the
last group and a debug warning (`ember-eui.sheet.groups-loaded-mismatch`)
names both numbers; no record is lost or hidden.

| Case | What you pass |
| --- | --- |
| Expanded, fully loaded | `count: 12, loaded: 12` |
| Collapsed | `collapsed: true, count: 12` (no `loaded`); its 12 records are not in `@records` |
| An empty group you choose to list | `count: 0`: a header and, when inserting is allowed, an add row |
| Records with an empty value | `value: null`: label "(Empty)" |
| Starts on this page, continues on the next | `count: 40, loaded: 15` |
| Continues from the previous page | `count: 40, loaded: 25, continued: true, rowNumberStart: 16` |
| Two levels | the parent `{ depth: 0, count: 30 }` (no `loaded`), then its children `{ depth: 1, loaded: … }` |
| A collapsed parent | the parent with `collapsed: true`; its children are not listed |

### In the grid

- **Header rows.** As tall as a record row, on one opaque background:
  the label (indented 16 px per level), the count and "(continued)".
  The label stays in view on horizontal scroll. Each field's cell shows
  `summary[fieldId]`, subdued and right-aligned. The footer bar
  (`@summary`) stays the whole view's.
- **Toggle.** Only with `@onGroupToggle`: a chevron before the label. A
  click on it or on the title, or Enter or Space on a focused header,
  calls `@onGroupToggle(key, !collapsed)`. Focus stays on the header
  when your new `@groups` move it.
- **Column menu.** With `@onGroupByChange`: "Group by this field" calls
  it with `[{ field, direction: 'asc' }]`, and on a field of `@groupBy`
  "Remove grouping" calls it with `[]`. Not on a field with
  `groupable: false`. A second level comes from your own control, with
  the blocks' `setGroupBy`. The group field may be hidden.
- **Adding.** Each expanded leaf group has its own add row, and the add
  row at the end is not drawn. A click or Enter on it inserts one record
  after the group's last loaded record, with `@newRecordValues` under the
  group's values (the group's and each ancestor's field: the group's
  win) and the insert's `groupKey`. Shift+Enter, the row menu's insert
  above and below, and Duplicate do the same for the record's group. A
  paste on a group's add row inserts every line into that group; a paste
  from a record that runs past the last record inserts the rest into the
  last record's group.
- **Row numbers.** One more than the previous record's, from
  `@rowNumberOffset + 1`; a group's `rowNumberStart` restarts the count
  (`groupRecords` sets it, counting the records of collapsed groups, so
  the numbers are positions in the whole view). `@rowLabel` gets that
  number. Headers and add rows have none.
- **Selecting.** A range is over records: Shift+arrows, a drag and the
  fill handle step over headers, and the outline is drawn per group.
  Copy gives no line for a header; a paste fills the following records
  across groups. Ctrl/Cmd+A selects every record. Checkboxes: headers
  have none; Shift+click across a header checks the records between,
  and the header checkbox checks the loaded records.
- **Keys and the mouse on a header.** The arrows pass through it and
  keep the column. A header keeps no range: typing, F2, Delete, paste and
  Shift+Enter do nothing there, and a click or a Shift+click on it
  focuses it and drops the range. PageUp, PageDown, Ctrl+Home and
  Ctrl+End never land on a header, from a cell or a row number. There is
  no row menu on a header: a right-click shows the browser's.
- **Undo, redo.** By record id. A record in a collapsed group is not in
  `@records`: while some group is collapsed, its undo or redo is emitted
  anyway (you still have the record) without the "changed since" check,
  and nothing is selected. Without a collapsed group nothing changes: a
  change on another page is skipped and kept (Undo and redo).
- **Expanded record.** Previous and next go over `@records`: from a
  group's last record to the next group's first.
- **The API.** `focusCell` does nothing for a record of a collapsed
  group: expand the group first.

The header's cells are grid cells with an `aria-label` ("Status: Open,
12") and, with a toggle, `aria-expanded`; the row is not a `treegrid`
row. Not checked with a screen reader yet.

### Helpers

From `@ember-eui/sheet`, plain functions:

- `groupRecords(ctx, records, { groupBy, fields, collapsed?, summaries?,
  rowNumberOffset? })` gives `{ records, groups }` for an owner that has
  every record (`localRecords.view` is this). Two values are one group
  when the type's `copyText` gives the same text; groups are ordered by
  the type's `compare`, reversed for `'desc'`; keys are `field:text`
  joined by `/` per level (`status:Open/owner:Ana`). It sets `count`,
  `loaded`, `rowNumberStart`, `collapsed` and, with `summaries`, each
  group's `summary` (`summarize` over its records). An owner that pages
  must not call it on a page.
- `applyChangeSetToGroups(groups, records, changeSet, getRecordId)` keeps
  `count` and `loaded` right after a change set (an insert by its
  `groupKey`, else its anchor's group; a delete; a move), until your next
  query.
- `pageGroups(records, groups, groupKeyOf, { offset })` fills `loaded`
  and `continued` of your backend's headers for one page of records.

With EmberSearchUi, `EuiSheetSearch` passes `@groups`, `@groupBy`,
`@onGroupByChange` and `@onGroupToggle` to the sheet. `@groups` may be a
function of the driver's snapshot (your backend's group counts in
`aggregations`, the page's results for `loaded`): the connector keeps it
next to its stable results and runs `applyChangeSetToGroups` on it with
each change set, until Re-apply. Your handlers write the group-by and the
collapsed keys with `driver.setExtension`, which your backend reads. The
driver itself has no group-by yet.

### Cost

Grouping keeps column virtualization: a header's label is the row's
first rendered cell, made sticky by CSS, so no column has to stay
mounted. Measured in the sheet's own test (FZ13: 10,000 records in 200
groups, 30 fields, headless Chromium, 20 scroll steps of 600 px, the
fastest of two rounds):

| | Cells rendered | Ungrouped | Grouped |
| --- | --- | --- | --- |
| Not frozen | 72 | 45.9 ms | 43.5 ms |
| Frozen | 372 | 193.6 ms | 204.8 ms |

That run was on a quiet machine. Two more, under load from other work,
gave 0.75 to 1.26 times the ungrouped time, either way: the difference is
noise. So grouping costs about what not grouping costs; freezing is what
multiplies the work (Frozen field, below). A change of `@groups` rebuilds
the row model and one class entry per header and add row (200 groups:
400 entries).

## Frozen field

With `@frozenFields={{1}}` the first field stays in view when the grid
scrolls sideways, and so do the row numbers, its header and its summary
cell. `@frozenFields={{2}}` freezes two fields. It is off by default
because of its cost (below). A frozen field always has a
width (200 px unless `@fieldWidths` or `field.width` say otherwise), and
resizing it moves the frozen edge. Keyboard focus that would land under
the frozen columns scrolls the cell clear, and focusing a frozen cell
(a click, ArrowLeft into it) does not scroll the grid.

### Performance

Freezing turns off column virtualization. The grid can only keep a cell
pinned while it stays mounted, so while a field is frozen it renders every
column of the rows in view, not only the columns in view. Rows stay
virtualized, so the number of records does not matter. What matters is:

| | Cells rendered |
| --- | --- |
| Not frozen | rows in view × fields in view |
| Frozen | rows in view × every visible field (plus the row numbers) |

Vertical scrolling mounts a new row's cells, so its cost grows with that
count. Horizontal scrolling then mounts nothing, since every column is
already there.

Measured in the sheet's own test (FZ9: 10,000 records × 30 fields, 12 rows
rendered, headless Chromium, 20 scroll steps of 600 px):

| | Cells rendered | Time per scroll step |
| --- | --- | --- |
| Not frozen | 72 | 38–50 ms |
| Frozen | 372 | 182–197 ms |

So five times the cells cost about four times the time. Take the absolute
numbers as a test machine's, not a target; the ratio is what carries over.
The "Large data" example lets you feel it: it has 31 columns, with a
switch to freeze the first one.

What makes it worse, each one multiplied by every column:

- More visible fields. Hide the ones not needed on screen
  (`@hiddenFields`); they stay in the expanded record.
- A taller grid (`@height`), so more rows in view.
- Heavy cells: attachment thumbnails, linked-record chips, your own cell
  components from `@fieldTypes`.

A sheet with a dozen fields barely notices. With thirty or more, freeze
only if users really scroll sideways a lot, and check it on the slowest
device you support. Above 50 visible fields the sheet does not freeze at
all, and `@frozenFields` is ignored.

## The sheet's API

`@registerApi` gives you one object to call from your own controls or
store:

| Method | |
| --- | --- |
| `undo()`, `redo()` | Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z, from outside the sheet. |
| `focusCell({ recordId, fieldId })` | Focuses that cell. Nothing happens when the record is not in `@records` or the field is not shown. |
| `scrollToCell({ recordId, fieldId })` | Scrolls that cell into view without focusing it or changing the selection (`@currentMatch` does this and draws the ring). |
| `getSelection()` | The selection now (Summary bar, above), or `null`. |
| `remapIds({ [tempId]: id })` | The ids your store gave to inserted (or restored) records. The undo history, rejected texts and a pending focus are rewritten. |
| `clearHistory()` | Drops the undo and redo history. |
| `expandRecord(id)` | Opens that record (`null` closes it). |
| `insertRecord({ anchor?, values? })` | Emits the insert of one record, next to `anchor` (`{ recordId, position: 'before' or 'after' }`) or at the end. `values` default to `@newRecordValues`. |
| `deleteRecords(ids)` | Emits the delete of those records. |
| `showShortcuts()` | Opens the shortcut list (as Ctrl/Cmd+/ on the grid). The blocks have `showShortcuts()` too, for a toolbar button. |
| `addField({ index? })` | Opens the field editor to add a field at `index` among the visible fields (default: the end; never before the first field). With `@onFieldCreate`. The blocks have `addField()` too. |
| `moveRecords(ids, { recordId, position })` | Emits the move of those records before or after a record of `@records`, as a drag there would. With `@canMove`. |
| `editField(fieldId)` | Opens the field editor on a field, also a hidden one (it opens under the "+" header then). With `@onFieldUpdate`. |

When you replace `@records` with records the sheet did not change
(another sort, another page, a reload), the selection follows its record:
it collapses to the focused cell's record, wherever it is now (or the same
row, when that record is gone), and an open editor stays on its record (it
is closed without saving when the record is gone).

## Theme

The sheet takes its colours (selection, focus, errors, the editor's input
and the checkbox) from the EUI theme, so it follows light and dark: put
it inside an `EuiEmotionProvider` with `@colorMode="dark"` (or set the
`eui-emotion` service's `colorMode`). The colours are CSS custom
properties set by a class on the sheet's wrapper (`--euiSheet-primary`,
`--euiSheet-selected`, `--euiSheet-hover`, `--euiSheet-plain`,
`--euiSheet-text`, `--euiSheet-textSubdued`, `--euiSheet-danger`,
`--euiSheet-textDanger`, `--euiSheet-dangerFilled`,
`--euiSheet-textInverse`, `--euiSheet-shadow`, `--euiSheet-subdued`,
`--euiSheet-border`, `--euiSheet-link` (link text and file names),
`--euiSheet-star` (a rating's stars), `--euiSheet-checked` (checked rows),
`--euiSheet-elevation` (the open editor's and the row menu's shadow),
`--euiSheet-textSuccess` (a success button's text), `--euiSheet-match`
(the current search match's ring, the theme's warning), the row colours
`--euiSheet-rowPrimary`, `-rowAccent`, `-rowSuccess`, `-rowWarning`,
`-rowDanger` and `-rowNeutral`, and `--euiSheet-highlight` for what is
coming). `--euiSheet-selected`, the
range tint, is the theme's primary at 12 % (20 % in dark). To change
one, set it on the sheet itself, which takes attributes
(`<EuiSheet style="--euiSheet-selected: #E6F0FF" …>`) or a more specific
selector; set on a parent element, it loses to the sheet's class. The
expanded record's flyout or modal, the row menu, the field editor and the
panel editors (`editorLayout: 'panel'`: the selects, linked records,
users, attachments, an app type's picker) are rendered at the end
of `<body>`, placed by their cell or header (below it, above it when there
is no room below in the window), so a card, panel or tab with
`overflow: hidden` around the sheet does not cut them off. They get the
class too, and the overrides set on the sheet's own `style` when they
open; CSS for an app's panel editor should not be scoped under
`.euiSheet`. An editor gets that class as `@themeClass`: one that renders a part of
itself outside the sheet (a wormholed list) adds it there; without it
that part uses the light colours.

**Row colours.** `@rowColor={{this.colorOf}}` returns a colour per
record, drawn as a 4 px bar at the row's left edge: on the row-number
cell (sticky with it when fields are frozen), or on the first field's
cell without row numbers. `'primary'`, `'accent'`, `'success'`,
`'warning'`, `'danger'` and `'neutral'` are the theme's
(`--euiSheet-row<Name>`), so dark mode follows; any other value is a CSS
colour used as given (yours to fit dark mode); `undefined` draws none.
`colorByOption(field)` returns the record's option's `color` of a select
field (the badge's colour; `'default'` is `'neutral'`). The colour has
no text: a screen reader does not hear it, so put its meaning in a field
too. `@rowColor` is called for each rendered row: keep it cheap.

## Records

A row-number column comes first. It shows each row's position (with
`@rowNumberOffset` added, so page 2 goes on from page 1), or what
`@rowLabel` returns. The number is the position, not the record's id:
pass `@rowLabel={{(record) => record.id}}`, or add the id as a field, to
show ids. Hovering a row shows its checkbox and an expand icon.

- **Selecting rows**: a click on a row number selects the whole row,
  Shift+click or a drag over the numbers selects more. A click on a
  column's title selects its cells (Shift+click: more columns); the
  column's actions button keeps its own menu. Delete, copy and paste use
  that selection like any other.
- **Checkboxes**: a click toggles a row, Shift+click every row from the
  last one toggled, and the header's checkbox all rows or none. Checked
  rows are what the row menu and your `@rowActions` act on; with none
  checked, the selected rows.
- **Adding**: the last row of the grid is an "Add record" row: a click,
  or Enter on it, adds a record at the end and focuses its first editable
  cell. Shift+Enter on a cell adds one below it. A paste on the add row
  adds its lines as records.
- **The row menu**: right-click a cell or a row number, or press
  Shift+F10 or the ContextMenu key. It has Insert record above and below,
  Duplicate, Expand record (for one record), Copy (the rows as
  tab-separated text), your `@rowActions` and Delete. Escape or a click
  outside closes it. There is no delete key for rows: Delete and
  Backspace clear cells.

- **Moving** (with `@canMove`): each row number has a grip (shown on
  hover and focus, always on a touch screen; the column is 12 px wider).
  Drag it: a line shows where the rows go, the grid scrolls near its
  edges, Escape cancels, and the release emits one change set. The
  pressed row moves, or all the checked rows when it is checked, or the
  rows of a selection of whole rows; they keep their order and are
  selected after the move. Alt+Shift+ArrowUp / ArrowDown on a row number
  (or with whole rows selected) moves them one record. A drop that
  changes nothing emits nothing. With a `@sort` there is no grip: the
  order is the sort's. With groups, a drop on a header goes to the start
  of its group (a collapsed one: into it, with no anchor), on a group's
  add row to its end, and a drop in another group also writes that
  group's values; it is not allowed (a red line) when one of those
  fields is read-only for a moved record. A drag stays on the page the
  sheet has. Not by touch in v0.3 (a touch drag scrolls): on a phone use
  the keys or `api.moveRecords`.

Each of these is a change set (`insert`: `inserts` with `index` and
`anchor`; `delete`: `deletes` and `removed`; `move`: `moves`) and one
undo step: an undone delete puts the same records back where they were,
an undone move puts them back in their old place.

All of this works on the rows the sheet has: with a paging owner, the
checkboxes and the selection are those of the page shown.

## Fields

The owner owns `@fields`. Adding, editing, duplicating and deleting a
field from the grid are three intents, as in Airtable's grid; each
handler shows its own controls, and without it there are none (there is
no local fallback: fields are your data model). A bare app passes
`localRecords`' handlers:

```hbs
<EuiSheet
  @fields={{store.fields}}
  @records={{store.records}}
  @getRecordId={{this.getId}}
  @onChange={{store.apply}}
  @onFieldCreate={{store.createField}}
  @onFieldUpdate={{store.updateField}}
  @onFieldDelete={{store.deleteField}}
/>
```

- **The "+" column** (with `@onFieldCreate`) is the last header: a click,
  or Enter or Space on it (ArrowRight from the last header reaches it),
  opens the field editor to add a field at the end. Its body cells are
  empty: a click there selects the row's last field, and ArrowRight and
  End stop at the last field.
- **The column menu** has Edit field, Duplicate field, Insert left,
  Insert right and Delete field (last, in red). Nothing is inserted to
  the left of the first field and the first field cannot be deleted (it
  stays first). Duplicate calls `@onFieldCreate` at once, with the
  field's draft, the label "Name copy", the next index and `copyOf`: you
  decide whether values are copied. Delete asks first.
- **The field editor** opens under the header it belongs to: the name
  (required; Enter saves), the type (`@creatableFieldTypes`, each labelled
  by `type.label`), the type's options (a select's options and colours, a
  currency's code and decimals, a percent's decimals, a rating's stars, a
  date's day/month order, a duration's format), a description and
  Required. Escape and Cancel close it and focus the header; a click
  outside or a scroll of the grid cancels it. `@fieldEditor` replaces its
  content: your component gets `mode` (`'create'` or `'edit'`), `field`,
  `draft`, `types`, `isSaving`, `error`, `onSave(draft)`, `onCancel()`,
  `messages` and `themeClass`.

The **draft** is plain data: `{ label, type, description?, required?,
...type options }`, without `id` and without the parts that are
functions (`options(record)`, `validate`): the editor hides those, so
`{ ...previous, ...draft }` keeps them. Build the field from it (`{ id,
...draft }` on create), pass the new `@fields`, and for a create put it
at `after` (the visible field before it) or `index` (among the visible
fields). A handler that returns a promise keeps the editor open and busy;
when the promise rejects, the editor stays open and shows
`error.message` (a name your server refused).

**Changing a type changes no value.** The cells show the stored values
through the new type, whatever they are. To convert them, apply
`convertField(ctx, records, previous, next)`: the change set that writes
each value as the new type reads it, through the paste path (the old
type's copy text, then the new type's `parse`). What could be pasted
converts; what could not becomes empty, with a `rejected` entry (the
text and the reason) so you can say what was lost; select options a
`createOnPaste` field would create are in `newOptions`.
`localRecords.updateField` does exactly that and keeps the change set in
`log`.

**Field operations are not undoable from the sheet**: undo holds values
by record and field, and only you have every value of a deleted field.
When a field leaves `@fields` and `@hiddenFields`, or its type changes,
the sheet drops that field from its undo history (an entry left empty is
removed), its rejected texts and pending cells, and closes an editor on
it. You can make them undoable in your own UI.

## Expanded record

Space on a cell, Enter on a row number, the expand icon, the menu, or
`api.expandRecord(id)` open a record: in a flyout by default, or in a
modal with `@expandedRecord="modal"`. It lists the fields of `@fields`
and then those of `@hiddenFields`, each a label and a box with the same
cell the grid shows, and its errors under it. Its title is the first
field's text; the arrows go to the previous and next record.

- A box opens the field's editor in place: a click, Enter, F2 or typing
  (as on a cell). Space and a checkbox's click toggle it; Delete clears
  it. One editor is open at a time.
- In the editor, Enter saves and goes to the next field, Tab and
  Shift+Tab save and move on, Escape cancels (it does not close the
  record). Ctrl/Cmd+Z undoes, as in the grid.
- Every save is a change set like an edit in the grid: validated, with
  rejected texts shown in the box and in the cell.
- Escape on a box, the close button, or the record leaving `@records`
  close it; focus goes back to the cell it was opened from.
- While an editor is open, the flyout's or modal's focus trap is off, so
  an editor that renders part of itself elsewhere on the page (a
  calendar) works there too.

## Field types

| Type | Value | Accepted text | Options |
| --- | --- | --- | --- |
| `text` (default) | string | anything | `maxLength`, `pattern`, `patternMessage` |
| `number` | number or `null` | `12`, `-1.5`, `1,234.5` (no exponent, currency or `%`) | `min`, `max`, `decimalSeparator` (`'.'` or `','`) |
| `checkbox` | boolean | `true 1 yes y x ✓ si sí`, `false 0 no n` and empty | |
| `singleSelect` | an option's `value` or `null` | an option's label (any case) or value | `options` (an array or a function of the record), `createOnPaste` |
| `date` | ISO `YYYY-MM-DD` or `null` | `2026-11-19` (also with a time), `2026/11/19`, `19/11/2026`, `19-11-2026`, `19.11.2026` | `dateOrder` (`'dmy'` default, or `'mdy'`), `min`, `max` (ISO) |
| `multiSelect` | an array of option values (`[]` when empty) | labels (any case) or values separated by `,`; a part in double quotes keeps its commas | `options` (an array or a function of the record), `createOnPaste` |
| `linkedRecord` | an array of `{ id, label }` | resolved by `@onResolve`: the text is split on `,` | `search(query, { record, signal })` (the picker's list, a promise), `multiple` (default `true`) |
| `user` | `{ id, label, avatarUrl? }` or `null`; an array with `multiple` | with `options`: a label or an `email` (any case); without: resolved by `@onResolve` | `options` or `search`, `multiple` (default `false`) |
| `attachment` | an array of `{ id, name, url, type?, size?, thumbnailUrl? }` | none: text is rejected; files are uploaded (picker, drop, paste of files) | `upload(files, { record, field, signal, onProgress })`, `accept`, `maxFiles` |
| `currency` | number or `null` | `$1,234.50`, `MXN 12`, `12`: the symbol, the code and spaces are dropped | `currency` (ISO code), `locale`, `precision` (default 2), `min`, `max`, `decimalSeparator` |
| `percent` | a fraction or `null` (`0.25` is 25%) | `25%` or `25` | `precision` (default 0), `min`, `max` (fractions), `decimalSeparator` |
| `duration` | seconds or `null` | `1:30`, `1:30:00`, `1h 30m`, `1.5h`, `45s`, `90` (minutes; seconds with `'h:mm:ss'`) | `durationFormat` (`'h:mm'` default, or `'h:mm:ss'`) |
| `rating` | a whole number from 1 to `max`, or `null` | `0` (none) to `max` | `max` (default 5) |
| `url`, `email`, `phone` | string | anything (checked by validation: a web address, `x@y.z`, digits and `+ ( ) -`) | `maxLength` |
| `longText` | string, with line breaks | anything | `maxLength` |
| `dateTime` | an instant as a UTC ISO string (`2026-11-19T15:30:00.000Z`) or `null` | an ISO string with `Z` or an offset (that instant); an ISO string without one, `19/11/2026 15:30`, `19/11/2026 3:30 pm` (also `-` and `.`, seconds), or a date alone (midnight): in the field's zone | `timeZone` (`'local'` default, `'utc'`, or an IANA name such as `'America/Mexico_City'`), `dateOrder`, `hour12`, `seconds`, `min`, `max` (instants) |
| `button` | none | none: a text is rejected (paste, fill, clear and cut skip the column) | `buttonLabel` (a string or a function of the record; default the label), `icon`, `color` (`'primary'`, `'success'`, `'warning'`, `'danger'`, `'text'`), `disabled(record)`, `url(record)` |
| `barcode` | string or `null` | anything, trimmed | `pattern` (a RegExp source, tested as text fields do), `patternMessage`, `formats` (for a scan), `scan({ formats, signal })` |

Dates are shown as `DD/MM/YYYY` (or `MM/DD/YYYY`) and copied as ISO.
Currencies are shown with `Intl.NumberFormat` and copied as plain numbers;
percentages are shown with `precision` decimals and copied exactly;
durations are shown as `1:30` (whole minutes) or `1:30:15`. Multi-select,
linked-record and user cells copy their labels joined by `, `, quoting a
label that has a comma. Attachment cells copy their URLs (so pasting them
back is rejected: text is not a file).

- **Multi-select**: chips (three, then "+N"). Its editor is a list with
  a search field: a click or Enter toggles an option and the editor stays
  open; Tab or a click elsewhere saves, Escape cancels.
- **Linked record and user**: chips, or an avatar and the name. The
  picker lists `search`'s results (or a user field's `options`), the
  chosen ones first. With `multiple` a pick toggles, as in a
  multi-select; without it a pick saves. A search typed and left without
  a pick is resolved through `@onResolve`.
- **Attachment**: thumbnails (`thumbnailUrl`, or `url` for an `image/*`
  file), else a file icon and the name. The editor (the paperclip button,
  Enter or a double-click) lists the files with links that open them in a
  new tab and remove buttons, and has a file picker when the field has
  `upload`; each upload or removal is saved at once and the editor stays
  open. Files dropped on a cell, or pasted on one, are uploaded too: the
  cell shows as pending, then the new files are added to its value as it
  is then; a failed upload marks the cell "Upload failed". An `upload`
  that calls `onProgress(fraction)` (0 to 1 for the whole call, for
  example from `XMLHttpRequest`'s `upload.onprogress`) shows a 2 px bar
  along the cell's bottom edge and "Uploading… 40%" as its title, and the
  editor and the expanded record show the same value in a progress bar;
  calls after the upload settled or was aborted are ignored. One that
  never calls it shows the cell pending, as before. Only `http:`,
  `https:`, `blob:` and `data:image/` URLs are used as links or images.
- **Rating**: stars. A click on a star sets it, on the current one clears
  it; on a focused cell the digits 0 to `max` set it. No editor.
- **URL, email, phone**: link-styled text. A click on the text opens the
  link in a new tab (`mailto:` and `tel:` for email and phone); a click
  beside it selects the cell as usual. The row menu has "Open link", and
  the expanded record a button next to the box. Only `http:`, `https:`,
  `mailto:` and `tel:` links are opened, so a `javascript:` value opens
  nothing (and fails validation).
- **Date and time**: one stored format, an instant in UTC, so it orders
  as text and any backend reads it; the zone is the field's, not the
  value's. Shown as `DD/MM/YYYY HH:mm` (or the field's order, a 12-hour
  clock, seconds) in `timeZone`, and copied as the ISO string, so a copy
  pasted into another zone's column is the same instant. Typed text is
  never read with `Date` (it depends on the browser's locale). A wall
  clock that does not exist in the zone (the hour skipped when DST
  starts) moves forward by the gap; one that happens twice (when DST
  ends) is the first. An unknown zone name shows the values in UTC and
  makes every value invalid. Typing a digit opens a text input; Enter,
  F2, a double-click or the calendar icon the browser's date-and-time
  picker, in the field's zone. A fill continues one value by a day (the
  same time in the zone), two or more by their step. `date` is unchanged.
- **Button**: a button with the field's text, icon and colour; a click
  on it, or Enter or Space on the selected cell, calls `@onButtonPress`
  with the record (route by `fieldId`), or, without it, opens
  `url(record)` in a new tab. A promise shows a spinner and ignores
  presses until it settles; a rejection's message is the cell's error
  until the next press. `disabled(record)` draws it disabled; with
  neither a handler nor a `url` every button is disabled (and a warning
  says so once). A press is not a change set and is not undoable. It
  copies its text, so a copied range lines up. In the expanded record it
  is a real button.
- **Barcode**: the text in a monospace font. Typing or pasting writes it;
  a USB or Bluetooth scanner types it like a keyboard and presses Enter,
  so a column can be scanned row by row. Where the field can scan (its
  own `scan`, for example a zxing wrapper, or the browser's
  `BarcodeDetector`, in Chromium-based browsers on Android, ChromeOS and
  macOS), the cell has a camera icon: it opens the editor with a scan
  panel, which reads the rear camera until a code decodes and saves it;
  Cancel or Escape stop the camera. The camera needs a secure page and
  the user's permission. The symbology is not stored.
- **Long text**: the lines, clamped to the row height. The editor is a
  text area that starts at the cell, at least 240 px wide, and grows with
  its lines (up to 240 px, then it scrolls). Shift+Enter or Alt+Enter adds
  a line; Enter saves and goes down.

Array and object values are compared by content (a type's `equals`), so
writing an equal array is no change, and undo is not blocked by an owner
that replaced a value with an equal copy. The sheet never changes a value
in place; your store should not either (fill down, paste and duplicate
may put the same array in two records).

Numbers, dates and checkboxes give their column a grid `schema`, so number
columns are right-aligned and the column menu's sort items read "Sort
Low-High", "Sort Old-New" and "Sort False-True" (text: "Sort A-Z"). An app
type sets `schema` the same way, and may add `toNumber(value)` for
`summarize`. A type's `cell` component also gets `@highlight` (the sheet's
term) to mark matches itself.

### In the field editor

A type can name itself in the field editor's type select with `label`
(default: the built-in name, "Single line text", "Single select", …) and
add its own part of the editor with `fieldOptions`, a component that gets
`draft`, `field` (on edit), `messages` and `onChange(patch)`, which merges
keys into the draft. List the type in `@creatableFieldTypes` to offer it.
`linkedRecord`, `user` and `attachment` are not offered by default: they
need `search` or `upload` functions, which a draft cannot hold; list them
and complete the field in your handler.

## Bulk resolve

Pasted (or typed) text that a type cannot read alone, such as names in a
linked-record field, needs your API. With `@onResolve`, a paste writes
what it can at once (other columns, new rows) and shows those cells as
pending, with their text; the sheet then calls `@onResolve` once, with
one request per field and the distinct texts to look up:

```js
onResolve = async (requests, { signal }) => {
  const result = {};
  for (const { fieldId, texts } of requests) {
    const found = await api.lookup(fieldId, texts, { signal }); // [{ id, label }]
    result[fieldId] = Object.fromEntries(
      texts.map((text) => [text, found.find((r) => r.label === text) ?? null])
    );
  }
  return result; // { [fieldId]: { [text]: value or null } }
};
```

Each request is `{ fieldId, texts, cells: [{ text, recordId or tempId,
record }] }`. The resolved cells arrive as a second change set (source
`'resolve'`, patching a new row by its `tempId`), and one Ctrl/Cmd+Z undoes
both. A text answered `null` is a rejection ("could not be resolved"), and
so is every cell of a call whose promise rejects. Writing a pending cell
again (typing, Delete, another paste) drops its result; when no cell of a
call is left pending, or the sheet goes away, the call's `signal` is
aborted. A pending cell whose record leaves `@records` is dropped too.

A field type opts in by returning `{ unresolved: text }` from `parse`. It
may also say how one cell's text splits into texts to look up and how
their values make the cell's value (`resolve: { parts, combine }`); by
default the whole text is one part and its value is the cell's value.

## Keyboard

| Key | On a cell | In an editor |
| --- | --- | --- |
| Arrows; Home, End (row start, end); Ctrl+Home, Ctrl+End (first, last cell) | Move (the grid's keys). Home and Ctrl+Home go to the first field; ArrowLeft from it reaches the row number | Move in the text |
| Ctrl/Cmd+arrows | Jump to the edge of the data, as in Excel: to the last filled cell of a block, else to the next filled cell, else to the last cell. With Shift, extend the range to it | Move in the text |
| PageUp, PageDown | Move by the rows in view (with Shift, extend the range) | |
| Shift+arrows, Shift+click, a mouse drag | Select a range: its far corner moves, the active cell (where the range started) keeps focus | Move in the text |
| Shift+Home, Shift+End; Ctrl/Cmd+Shift+Home, Ctrl/Cmd+Shift+End | Extend the range to the row's first or last field; to the first or the last record's last cell | Select text |
| Ctrl/Cmd+A | Select every cell | Select the text |
| A printable key | Opens the editor with that character. A date opens only on a digit; a checkbox has no editor. | Types |
| Enter, F2, double-click | Opens the editor on the current value (a date: the browser's date input) | Enter saves and goes down |
| Tab, Shift+Tab | Tab moves focus out of the grid, to the next element on the page | Save and go right / left |
| Escape | Ends the dashed mark of a copy; collapses a range to the active cell | Closes without saving |
| Space | Toggles a checkbox; presses a button; elsewhere expands the record | Types |
| Enter, Space on a button cell | Presses it (no editor) | |
| Alt+Shift+ArrowUp, Alt+Shift+ArrowDown (on a row number, or with whole rows selected) | With `@canMove`: moves the rows one record up or down | |
| A digit | Sets a rating | |
| Shift+Enter | Adds a record below and goes to it (without inserting: as Enter) | Saves and goes down; in long text, adds a line (also Alt+Enter) |
| Shift+F10, ContextMenu | Opens the row menu | |
| Delete, Backspace | Clear the selected range | Delete text |
| Ctrl/Cmd+C, Ctrl/Cmd+V | Copy / paste the range as tab-separated text (a cell with a tab or a line break is quoted, as Excel does) | The input's own |
| Ctrl/Cmd+X | Cut: copies the range, then clears it (one undo step; with `@readOnly` it only copies) | The input's own |
| Ctrl/Cmd+D | Fill down: the top row of the range into the cells below it; on one row, the row above into it | The browser's |
| Ctrl/Cmd+R | Fill right: the left column of the range into the cells right of it; on one column, the column to its left into it. Taken from the browser's reload while a cell has focus | The browser's |
| Ctrl/Cmd+Z; Ctrl/Cmd+Shift+Z, Ctrl+Y | Undo; redo | The input's own |
| Ctrl/Cmd+/ | Opens the shortcut list | |

Ctrl/Cmd+/ on a cell, a row number or a header opens the shortcut list:
every key of this table, by section, without the rows of features that
are off (`@readOnly`, `@canInsert`, row numbers, column drag,
`@canMove`). Escape
closes it and focus goes back to the cell. Its texts are messages
(`euiSheet.shortcuts`, `euiSheet.shortcutFillDown`, key names such as
`euiSheet.shortcutKeyEnter`), so `@messages` and `eui-i18n` translate it.
`?` is not a shortcut: it is a printable key and opens the editor.

On a header: Enter opens the header menu, and Space lifts the column to
move it with the arrows (Space drops it, Escape cancels).

On a group header (Group by, above): Enter and Space collapse or expand
it (with `@onGroupToggle`), the arrows go on through it, and nothing
else is taken.

On a row number: Space toggles the checkbox, Enter expands the record,
Shift+ArrowUp/Down selects rows, Shift+F10 opens the menu, and Delete
clears the selected rows. Reached with the arrows, a row number has no
selection, so Delete, copy and paste do nothing there. On the add row,
Enter adds a record; typing, Space and Delete do nothing.

With the mouse, as in Airtable: a click selects a cell (a blue ring), a
click on the selected cell edits it, and a double-click edits at once.
Pressing on a cell and dragging over others selects that range (the
release does not edit or toggle); Shift+arrows then continue from it.

The active cell stays where a range started, as in Airtable and
spreadsheets: a drag, Shift+click, Shift+arrows and the Shift+Ctrl/Cmd
jumps move only the range's far corner, which is scrolled into view, and
the ring stays on the first cell. Typing or Enter edits that cell; a
plain arrow or click moves it and collapses the range; Delete, copy, cut,
paste and fill use the whole range. A range of more than one cell has a
3 px outline, and the active cell inside it keeps a plain background. The
headers of the range's columns and the numbers of its rows are marked in
the primary colour; a selected column's header and a selected row's
number also get a 3 px bar. Checked rows have a light tint.

After a copy or a cut the copied cells keep a dashed outline until
Escape, a change or the next copy. The cells a paste, fill, undo or redo
changed flash briefly (not with reduced motion). While the fill handle is
dragged, its target area has a dashed outline. A right-click (or a long
press) on a cell or a row number opens the row menu, on a header the
header menu; Shift+F10 opens the row menu from the keyboard.

With no records (and not `@isLoading`) the sheet shows "No records" under
the grid; the add row stays the way to add one (`@messages` `noRecords`;
an `<:empty>` block replaces the message).
Holding the pointer near an edge of the grid, or past it, scrolls the
grid (faster the farther out) and the range follows.
Select and date cells show a ▾ or calendar button on the hovered or
selected cell; a click on it opens the editor. A click anywhere in a
checkbox cell toggles it. A custom type gets the same with `opener` (an
EUI icon type) and `onCellClick`.

The fill handle is the small square at the bottom-right corner of the
selected range. Drag it down, up, right or left: the cells it covers
are outlined, and the release fills them from the range. Numbers
(number, currency, percent, duration, rating) with a constant step
continue it (`1, 2` gives `3, 4`); one date continues by a day, and two
or more dates with a constant step continue it (weekly stays weekly);
anything else repeats in order. Hold Ctrl or Alt (Option) when you
release to repeat instead. Escape during the drag cancels it. Values are
copied as they are (an array too: do not change it in place); across
fields of different types they go through text, like a paste. A fill is
one undo step. The handle is for a mouse; Ctrl/Cmd+D and Ctrl/Cmd+R
are the keyboard's fills. A custom type continues its own values with
`series(samples, count, field, direction)`.

A click on another cell saves the editor's text and closes it. So does
scrolling the grid so that the edited cell leaves the view; a scroll
that keeps it fully in view (the grid bringing a far column into view
when it is focused) moves the editor with it. In a select
editor, typing filters the options, ArrowUp and ArrowDown move, and
Enter, Tab or a click picks. Enter or Tab right after typing picks the
first match.

A paste starts at the top left cell of the selection. Columns past the
last field are dropped, read-only cells are skipped, and rows past the
end become inserts. When the selection is larger than the copied block
and its height and width are whole multiples of the block's, the block
is repeated over the whole selection, as in Excel: one copied cell
fills every selected cell. Otherwise the block is pasted once.

## Touch

On a phone or a tablet, a tap selects a cell and a tap on the selected
cell edits it. A drag scrolls. After a tap the selected cell has two
round handles, at its top-left and bottom-right corners (as in Google
Sheets): drag the bottom-right one to extend the range, the top-left one
to move its other corner; near the grid's edges the drag scrolls. A
handle hides while its corner is scrolled out of view or under the
frozen fields, and the handles never show after a mouse press (a hybrid
device). Row numbers, column titles and Ctrl/Cmd+A still select too. A
long press on a range opens the menu with Copy and Paste (the
clipboard's text over the range; the browser may ask for permission).
A long
press on a cell or a row number opens the row menu (Android Chrome fires
its own context menu event; on iOS Safari the sheet's 500 ms timer opens
it; a press that moves more than 10 px is a scroll). The ▾ and calendar
buttons, the row checkbox and the expand icon are always shown on touch
screens, with larger touch areas. With `@editIn` at its default, a sheet
narrower than 600 px on a touch screen edits in the expanded record,
with the tapped field's editor open. The fill handle is not shown on
touch screens (the selection handles take its place). None of this was
tried on a real phone yet: the handles were checked with synthetic touch
events and Chromium's touch emulation only.

## IME and dead keys

A composition starts in a hidden input over the cell: with a dead key
(`´` then `e` on a Spanish or Mac keyboard) or an IME (Japanese,
Pinyin), typing on a cell opens the editor with the composed text (`é`,
`日本`), not with the first key. Escape during it returns to the cell.
Inside an open editor, the Enter that confirms a composition is the
IME's: it does not save. This was checked with synthetic events only;
real IMEs and dead keys on macOS (Chrome, Safari, Firefox) are still to
be tried.

## Errors

A cell with an error has a red border. When it has focus, its messages
show in a box under it (and are announced to screen readers); hovering
it shows them too.
There are three kinds:

- **Rejected text**: a text the type cannot read, such as `abc` in a
  number field, typed or pasted. It makes no patch: the record keeps
  its value, the change set lists it in `rejected`, and the cell shows
  the text, marked invalid, until the cell is written again.
- **Validation errors**: a stored value that breaks a rule: `required`,
  the type's options (`min`, `max`, `maxLength`, `pattern`, an unknown
  option, a bad date), `field.validate(value, record)`, and `@validate`
  for rules that need the whole record, other rows or a server. They
  never block a change.
- **`@cellErrors`**: your own errors, for example from saving to your
  API. Shown last.

A cell shows its messages in that order. A rejected cell shows only its
rejection and `@cellErrors`: the other rules would describe the old
value.

## Not yet

These are not in yet:

- Dragging rows and columns by touch (a touch drag scrolls; the keys,
  the header menu's "Move left/right" and `api.moveRecords` work on a
  phone).
- Managing fields inside the expanded record, and reordering a select's
  options in the field editor.
- On group headers: checkboxes, collapsing without the owner's
  `@onGroupToggle`, taller headers, a colour per level.
- A group-by in EmberSearchUi's own state (its driver and memory
  backend): today the connector forwards your groups and your handlers
  write them with `setExtension` (Group by). Sorting, filtering, search,
  paging and grouping are not "not yet": they are the owner's (above,
  and the EmberSearchUi connector), and the sheet draws them.
- Date and time values without a zone ("floating" times).
- A tint of the whole row (`@rowColor` draws a bar).
- Undo of field operations (adding, editing or deleting a field).
- From v0.2: dead keys and IMEs in the expanded record's boxes,
  re-measuring the fill handle on a window resize, a keyboard way to
  choose copy over series in a fill, a cell larger than the visible body,
  one `@onResolve` answer per text, and a message when `maxFiles` drops
  files; and the checks on a Mac and on real phones.

Out of scope: formulas, rollups and lookups, comments, co-editing, and
other kinds of views (calendar, kanban, gallery).

</EuiText>

<EuiSpacer @size="xl" />

<EuiText>

## Examples

</EuiText>

[[demos-all]]
