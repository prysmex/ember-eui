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
  source: 'edit' | 'paste' | 'clear';
  patches: { recordId; fieldId; from; to }[]; // cells of existing records
  inserts: { tempId; index; values }[]; // rows pasted past the end
  rejected: { recordId?; tempId?; fieldId; text; message }[];
  newOptions: { fieldId; option }[]; // options created on paste
}
```

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
createRecord? })` returns the new records (patched records are new
objects, the others keep their identity), and `applyNewOptions(fields,
changeSet)` returns the fields with the options created on paste. Both
are pure, and are also exported from `@ember-eui/sheet/core`, which has
no Ember imports.

A pasted row past the end comes as an insert with a `tempId`. By default
`applyChangeSet` uses the `tempId` as the new record's `id`.

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
| Arrows; Home, End (row start, end); Ctrl+Home, Ctrl+End (first, last cell) | Move (the grid's keys) | Move in the text |
| Shift+arrows, Shift+click | Select a range | Move in the text |
| A printable key | Opens the editor with that character. A date opens only on a digit; a checkbox has no editor. | Types |
| Enter, F2, double-click | Opens the editor on the current value (a date: the browser's date input) | Enter saves and goes down |
| Tab, Shift+Tab | Tab moves focus out of the grid, to the next element on the page | Save and go right / left |
| Escape | The grid's | Closes without saving |
| Space | Toggles a checkbox; does nothing elsewhere | Types |
| Delete, Backspace | Clear the selected range | Delete text |
| Ctrl/Cmd+C, Ctrl/Cmd+V | Copy / paste the range as tab-separated text | The input's own |

With the mouse, as in Airtable: a click selects a cell (a blue ring), a
click on the selected cell edits it, and a double-click edits at once.
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
end become inserts.

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

These are not in v0.1:

- Undo and redo, cut (Ctrl/Cmd+X), and a fill handle.
- Selecting a range by dragging the mouse.
- Sorting and filtering UI, frozen columns, row numbers, and buttons to
  add or delete rows.
- Multi-select, linked record, user and attachment fields.
- Resolving pasted text through your API (bulk resolve). A pasted text
  in a field whose type returns `{ unresolved }`, such as the zone
  picker below, is rejected.
- Cells that contain tabs or line breaks: copied and pasted text is
  split on every tab and line break (no quoted cells).
- IME composition, and colours for the dark theme: the selection and
  error colours are fixed.

</EuiText>

<EuiSpacer @size="xl" />

<EuiText>

## Examples

</EuiText>

[[demos-all]]
