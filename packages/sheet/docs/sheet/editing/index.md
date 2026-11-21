---
title: Editing and keyboard
order: 3
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: editing and keyboard"/>
<EuiSpacer @size="l" />

<EuiText>

How the sheet hands you its changes, how undo works, every key, and
the errors a cell can show.

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
sheet with `api.remapIds({ [tempId]: newId })` ([The sheet's API](/docs/sheet/docs/sheet/api#the-sheets-api)), so that undo
still finds it.

With `@canMove`, a row drag ([Records](/docs/sheet/docs/sheet/rows#records)) emits `source: 'move'` and
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

On a group header ([Group by](/docs/sheet/docs/sheet/groups#group-by)): Enter and Space collapse or expand
it (with `@onGroupToggle`), the arrows go on through it, and nothing
else is taken.

On a row number: Space toggles the checkbox, Enter expands the record,
Shift+ArrowUp/Down selects rows, Shift+F10 opens the menu, and Delete
clears the selected rows. Reached with the arrows, a row number has no
selection, so Delete, copy and paste do nothing there. On the add row,
Enter adds a record; typing, Space and Delete do nothing.

With no records (and not `@isLoading`) the sheet shows "No records" under
the grid; the add row stays the way to add one (`@messages` `noRecords`;
an `<:empty>` block replaces the message).
Holding the pointer near an edge of the grid, or past it, scrolls the
grid (faster the farther out) and the range follows.
Select and date cells show a ▾ or calendar button on the hovered or
selected cell; a click on it opens the editor. A click anywhere in a
checkbox cell toggles it. A custom type gets the same with `opener` (an
EUI icon type) and `onCellClick`.

A click on another cell saves the editor's text and closes it. So does
scrolling the grid so that the edited cell leaves the view; a scroll
that keeps it fully in view (the grid bringing a far column into view
when it is focused) moves the editor with it. In a select
editor, typing filters the options, ArrowUp and ArrowDown move, and
Enter, Tab or a click picks. Enter or Tab right after typing picks the
first match.

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
  the text, marked invalid, until the cell is written again (or you
  change the value: the sheet compares with the value it saw). On a
  new record (a paste on the add row or past the end, `appendRows`) it
  compares with the value the record arrives with in `@records`, so a
  default from your `createRecord` (`qty: null`) keeps it shown.
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

</EuiText>

<EuiSpacer @size="xl" />

<EuiText>

## Examples

</EuiText>

[[demos-all]]
