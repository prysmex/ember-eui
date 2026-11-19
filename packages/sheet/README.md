# @ember-eui/sheet

An Airtable-like data-entry grid for Ember, built on `EuiDataGrid` from
[`@ember-eui/core`](https://github.com/prysmex/ember-eui). It is
controlled: you pass the records in, and the sheet calls `@onChange` with
a change set (what the user typed, cleared or pasted); you apply it to your
own store. It edits with the keyboard, selects ranges, copies and pastes
blocks as TSV (to and from spreadsheets), and shows cell errors. It has
five field types (text, number, checkbox, single select, date), and you
can add your own cells and editors.

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

| Argument                                                          |                                                                                                                                                                    |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `@fields`                                                         | The columns, in order: `{ id, label?, type?, readOnly?, required?, validate?, ...options of the type }`. `readOnly` and `required` can be functions of the record. |
| `@records`                                                        | The rows. Pass a new array when they change.                                                                                                                       |
| `@getRecordId`                                                    | `(record) => id`.                                                                                                                                                  |
| `@onChange`                                                       | `(changeSet) => void`. Apply it to your records.                                                                                                                   |
| `@cellErrors`                                                     | Your own errors: `{ [recordId]: { [fieldId]: message \| messages } }`. Shown last.                                                                                 |
| `@validate`                                                       | Record, cross-row and server rules (below).                                                                                                                        |
| `@fieldTypes`                                                     | Your field types, merged over the built-in ones. Keep the object stable.                                                                                           |
| `@readOnly`                                                       | Every cell read-only (copy still works).                                                                                                                           |
| `@messages`                                                       | Overrides of the built-in messages (below).                                                                                                                        |
| `@height`, `@ariaLabel`                                           | The grid's height; its accessible name (default `Sheet`).                                                                                                          |
| `@registerApi`                                                    | `(api) => void`: the sheet's API, once, after the first render (below).                                                                                            |
| `@hiddenFields`                                                   | Fields that are not columns: listed in the expanded record, copied by duplicate.                                                                                   |
| `@rowNumbers`, `@rowLabel`, `@rowNumberOffset`                    | The row-number column (default on); `(record, position) => text` to show something else than the position; the first record's position on a page.                  |
| `@canInsert`, `@canDelete`                                        | Adding (add row, Shift+Enter, menu) and deleting (menu) records. Default `!@readOnly`.                                                                             |
| `@newRecordValues`                                                | `({ above, below }) => values` of a new record.                                                                                                                    |
| `@checkedRecordIds`, `@onCheckedChange`                           | Checked rows; controlled with the handler, local without it.                                                                                                       |
| `@expandedRecordId`, `@onExpandedRecordChange`, `@expandedRecord` | The expanded record (controlled the same way), in a `'flyout'` (default) or a `'modal'`.                                                                           |
| `@rowActions`                                                     | Your row menu items: `{ id, label, icon?, color?, isDisabled?(records), onSelect(records) }`.                                                                      |

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
  `@records` (another page) is skipped; `api.clearHistory()` drops the
  history when your data changes wholesale.
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
`fillDown` and `tileMatrix`, and for records `insertRecords`,
`deleteRecords` and `duplicateRecords` (the change sets the add row and the
row menu emit).

## The sheet's API

`@registerApi={{this.registerApi}}` receives one object:

| Method                               |                                                                                                                       |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `undo()`, `redo()`                   | As Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z.                                                                                   |
| `focusCell({ recordId, fieldId })`   | Focuses that cell; nothing when the record is not in `@records` or the field is not shown.                            |
| `remapIds({ [tempId]: id })`         | The ids your store gave to inserted or restored records: the undo history, rejected texts and a pending focus follow. |
| `clearHistory()`                     | Drops the undo and redo history.                                                                                      |
| `expandRecord(id)`                   | Opens the expanded record (`null` closes it).                                                                         |
| `insertRecord({ anchor?, values? })` | Emits the insert of one record, next to `anchor` or at the end.                                                       |
| `deleteRecords(ids)`                 | Emits the delete of those records.                                                                                    |

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
`--euiSheet-border`, `--euiSheet-highlight`) set by a class on the sheet's
wrapper. To change one, set it on the sheet itself (`<EuiSheet
style="--euiSheet-selected: #E6F0FF" …>`) or with a more specific
selector: set on a parent element it loses to the sheet's class. Editors
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
duplicate, expand, copy the rows, your `@rowActions`, delete. Each is one
change set and one undo step. Delete and Backspace never delete rows.

## Expanded record

Space on a cell, Enter on a row number, the expand icon or the menu open
the record in a flyout (`@expandedRecord="modal"`: a modal): `@fields`, then
`@hiddenFields`, each with the grid's cell in a box. A click, Enter, F2 or
typing on a box opens the field's editor in place; Enter saves and goes to
the next field, Tab moves on, Escape cancels; Escape on a box closes, and
focus returns to the cell. Saves are change sets like grid edits (validated,
undoable with Ctrl/Cmd+Z there too). While an editor is open the shell's
focus trap is off, so a wormholed calendar works.

## Field types

| Type             | Value                         | Accepted text                                                                           | Options                                                           |
| ---------------- | ----------------------------- | --------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `text` (default) | string                        | anything                                                                                | `maxLength`, `pattern`, `patternMessage`                          |
| `number`         | number or `null`              | `12`, `-1.5`, `1,234.5` (no exponent, currency or `%`)                                  | `min`, `max`, `decimalSeparator` (`'.'` or `','`)                 |
| `checkbox`       | boolean                       | `true 1 yes y x ✓ si sí`, `false 0 no n` and empty                                      |                                                                   |
| `singleSelect`   | an option's `value` or `null` | an option's label (any case) or value                                                   | `options` (an array or a function of the record), `createOnPaste` |
| `date`           | ISO `YYYY-MM-DD` or `null`    | `2026-11-19` (also with a time), `2026/11/19`, `19/11/2026`, `19-11-2026`, `19.11.2026` | `dateOrder` (`'dmy'` default, or `'mdy'`), `min`, `max` (ISO)     |

Dates are shown as `DD/MM/YYYY` (or `MM/DD/YYYY`) and copied as ISO.

## Keyboard

| Key                                  | On a cell                                                                                                   | In an editor                |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------- | --------------------------- |
| A printable key                      | Opens the editor with that character (a date: digits only; never on a checkbox)                             | Types                       |
| Enter, F2, double-click              | Opens the editor on the current value (a date: the browser's date input)                                    | Enter saves and goes down   |
| Tab, Shift+Tab                       | The grid's                                                                                                  | Saves and goes right / left |
| Escape                               | The grid's                                                                                                  | Closes without saving       |
| Space                                | Toggles a checkbox; elsewhere expands the record                                                            | Types                       |
| Shift+Enter                          | Adds a record below (as Enter when inserting is off)                                                        | Saves and goes down         |
| Shift+F10, ContextMenu               | Opens the row menu                                                                                          |                             |
| Home, Ctrl+Home                      | The first field of the row, of the sheet (ArrowLeft from it: the row number)                                | Native                      |
| Delete, Backspace                    | Clears the selected range                                                                                   | Deletes                     |
| Shift+arrows                         | Selects a range                                                                                             | Moves in the text           |
| Ctrl/Cmd+A                           | Selects every cell (focus stays)                                                                            | Native                      |
| Ctrl/Cmd+C, Ctrl/Cmd+V               | Copies / pastes the range as TSV (cells with tabs or line breaks quoted, as Excel does)                     | Native                      |
| Ctrl/Cmd+D                           | Fill down: each column's top value into the range's cells below it; on one row, the value of the cell above | Native                      |
| Ctrl/Cmd+Z; Ctrl/Cmd+Shift+Z, Ctrl+Y | Undo; redo                                                                                                  | Native                      |

In a select editor, typing filters the options, ArrowUp/ArrowDown move,
Enter or a click picks. A click on another cell, or scrolling the grid,
saves the editor's text and closes it.

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
neither edits nor toggles a checkbox, and Shift+arrows continue from it (no
scrolling at the grid's edge yet). Select
and date cells show a ▾ or calendar button on the hovered or selected cell
that opens the editor in one click; a click anywhere in a checkbox cell
toggles it. A field type gets the same with two optional properties:

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
`close` (all under `euiSheet.`).

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
`isEmpty`, `compare`, `navKey` (a key that sets the value without an
editor). The Ember layer adds optional components and key rules:

| Key                 |                                                                                                                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cell`              | Display component: `@value @text @field @record @errors @readOnly @onCommit(value)`. It must not render a tabbable element.                                                       |
| `editor`            | Editor component: `@value @field @record @draft @initialKey @onDraftChange(text) @onCommit(result?, { move? }) @onCancel @messages @themeClass`. It focuses itself when inserted. |
| `editorLayout`      | `'cell'` (over the cell, default) or `'panel'` (a panel below or above it).                                                                                                       |
| `opensOnKey(key)`   | Whether a printable key opens the editor.                                                                                                                                         |
| `handlesKey(event)` | Keys the open editor handles itself (the sheet then leaves them alone; Enter, Tab and Escape are otherwise the sheet's).                                                          |

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
`singleSelectType`, `dateType`, and `builtInSheetFieldTypes`) so you can
change one part of them.

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

## Limits

No cut, fill handle, fill right, auto-scroll while dragging, sorting or
filtering UI, hiding columns from the sheet, fullscreen or IME composition
yet. Pasted text in a field whose type returns
`{ unresolved }` is a rejection (bulk resolve on paste is planned).
