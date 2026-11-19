---
title: Sheet
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet"/>
<EuiSpacer @size="l" />

<EuiText>

`@ember-eui/sheet` is an Airtable-like grid for data entry, built on
`EuiDataGrid`. People edit cells with the keyboard, select ranges, and
copy and paste blocks to and from Excel or Google Sheets. It has five
field types (text, number, checkbox, single select, date), and you can
add your own cells and editors.

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

## Undo and redo

Ctrl/Cmd+Z undoes the last change made in the sheet (an edit, a paste, a
clear, a fill, a checkbox toggle, an insert, a duplicate or a delete of
records); Ctrl/Cmd+Shift+Z and Ctrl+Y redo it.
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
  even when your records were re-sorted since. A redo of a delete names
  the record's id; if your server gave the restored record a new id,
  call `remapIds` for it too.
- A change whose records are not in `@records` any more (another page, a
  filter) is skipped. Call `api.clearHistory()` when your data changes
  wholesale.
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
| `@fields` | The columns, in order: `{ id, label?, type?, readOnly?, required?, validate?, ...options of the type }`. `readOnly` and `required` can be functions of the record. |
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
| `@hiddenFields` | Fields that exist but are not columns: shown in the expanded record after `@fields`, copied by duplicate, put back by undo. |
| `@rowNumbers` | The row-number column. Default `true`; `false` hides it. |
| `@rowLabel` | `(record, position) => string`: what a row number shows instead of its position (for example the record's id). The column widens to fit. |
| `@rowNumberOffset` | The position of the first record when `@records` is one page of your data: page 2 of 50 passes `50`. Default `0`. |
| `@canInsert`, `@canDelete` | The add row, Shift+Enter and the menu's insert and duplicate; the menu's delete. Default: `!@readOnly`. Without inserting, a paste stops at the last record. |
| `@newRecordValues` | `({ above, below }) => values`: the values of a new record, from its neighbours. Default `{}`. |
| `@checkedRecordIds`, `@onCheckedChange` | The checked rows. With the handler, the sheet shows exactly `@checkedRecordIds` and calls the handler with the new list; without it, it keeps its own. |
| `@expandedRecordId`, `@onExpandedRecordChange` | The expanded record, controlled the same way. |
| `@expandedRecord` | `'flyout'` (default) or `'modal'`. |
| `@rowActions` | Your items of the row menu: `{ id, label, icon?, color?: 'danger', isDisabled?(records), onSelect(records) }`. |

## The sheet's API

`@registerApi` gives you one object to call from your own controls or
store:

| Method | |
| --- | --- |
| `undo()`, `redo()` | Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z, from outside the sheet. |
| `focusCell({ recordId, fieldId })` | Focuses that cell. Nothing happens when the record is not in `@records` or the field is not shown. |
| `remapIds({ [tempId]: id })` | The ids your store gave to inserted (or restored) records. The undo history, rejected texts and a pending focus are rewritten. |
| `clearHistory()` | Drops the undo and redo history. |
| `expandRecord(id)` | Opens that record (`null` closes it). |
| `insertRecord({ anchor?, values? })` | Emits the insert of one record, next to `anchor` (`{ recordId, position: 'before' or 'after' }`) or at the end. `values` default to `@newRecordValues`. |
| `deleteRecords(ids)` | Emits the delete of those records. |

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
`--euiSheet-textInverse`, `--euiSheet-shadow`, and `--euiSheet-subdued`,
`--euiSheet-border`, `--euiSheet-highlight` for what is coming). To change
one, set it on the sheet itself, which takes attributes
(`<EuiSheet style="--euiSheet-selected: #E6F0FF" …>`) or a more specific
selector; set on a parent element, it loses to the sheet's class. The
expanded record's flyout or modal and the row menu get the class too. An
editor gets that class as `@themeClass`: one that renders a part of
itself outside the sheet (a wormholed list) adds it there; without it
that part uses the light colours.

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

Each of these is a change set (`insert`: `inserts` with `index` and
`anchor`; `delete`: `deletes` and `removed`) and one undo step: an undone
delete puts the same records back where they were.

All of this works on the rows the sheet has: with a paging owner, the
checkboxes and the selection are those of the page shown.

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

Dates are shown as `DD/MM/YYYY` (or `MM/DD/YYYY`) and copied as ISO.

## Keyboard

| Key | On a cell | In an editor |
| --- | --- | --- |
| Arrows; Home, End (row start, end); Ctrl+Home, Ctrl+End (first, last cell) | Move (the grid's keys). Home and Ctrl+Home go to the first field; ArrowLeft from it reaches the row number | Move in the text |
| Shift+arrows, Shift+click, a mouse drag | Select a range | Move in the text |
| Ctrl/Cmd+A | Select every cell | Select the text |
| A printable key | Opens the editor with that character. A date opens only on a digit; a checkbox has no editor. | Types |
| Enter, F2, double-click | Opens the editor on the current value (a date: the browser's date input) | Enter saves and goes down |
| Tab, Shift+Tab | Tab moves focus out of the grid, to the next element on the page | Save and go right / left |
| Escape | The grid's | Closes without saving |
| Space | Toggles a checkbox; elsewhere expands the record | Types |
| Shift+Enter | Adds a record below and goes to it (without inserting: as Enter) | Saves and goes down |
| Shift+F10, ContextMenu | Opens the row menu | |
| Delete, Backspace | Clear the selected range | Delete text |
| Ctrl/Cmd+C, Ctrl/Cmd+V | Copy / paste the range as tab-separated text (a cell with a tab or a line break is quoted, as Excel does) | The input's own |
| Ctrl/Cmd+D | Fill down: the top row of the range into the cells below it; on one row, the row above into it | The browser's |
| Ctrl/Cmd+Z; Ctrl/Cmd+Shift+Z, Ctrl+Y | Undo; redo | The input's own |

On a row number: Space toggles the checkbox, Enter expands the record,
Shift+ArrowUp/Down selects rows, Shift+F10 opens the menu, and Delete
clears the selected rows. Reached with the arrows, a row number has no
selection, so Delete, copy and paste do nothing there. On the add row,
Enter adds a record; typing, Space and Delete do nothing.

With the mouse, as in Airtable: a click selects a cell (a blue ring), a
click on the selected cell edits it, and a double-click edits at once.
Pressing on a cell and dragging over others selects that range (the
release does not edit or toggle); Shift+arrows then continue from it.
Select and date cells show a ▾ or calendar button on the hovered or
selected cell; a click on it opens the editor. A click anywhere in a
checkbox cell toggles it. A custom type gets the same with `opener` (an
EUI icon type) and `onCellClick`.

A click on another cell, or scrolling the grid, saves the editor's text
and closes it. In a select
editor, typing filters the options, ArrowUp and ArrowDown move, and
Enter, Tab or a click picks. Enter or Tab right after typing picks the
first match.

A paste starts at the top left cell of the selection. Columns past the
last field are dropped, read-only cells are skipped, and rows past the
end become inserts. When the selection is larger than the copied block
and its height and width are whole multiples of the block's, the block
is repeated over the whole selection, as in Excel: one copied cell
fills every selected cell. Otherwise the block is pasted once.

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

- Cut (Ctrl/Cmd+X), a fill handle, and fill right (Ctrl/Cmd+R).
- Scrolling the grid while a drag reaches its edge: drag within the
  visible rows, or use Shift+click.
- Sorting and filtering UI, frozen columns, hiding columns from the
  sheet (`@hiddenFields` is an input for now).
- Multi-select, linked record, user and attachment fields.
- Resolving pasted text through your API (bulk resolve). A pasted text
  in a field whose type returns `{ unresolved }`, such as the zone
  picker below, is rejected.
- IME composition.

</EuiText>

<EuiSpacer @size="xl" />

<EuiText>

## Examples

</EuiText>

[[demos-all]]
