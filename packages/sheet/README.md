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

| Argument                |                                                                                                                                                                    |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `@fields`               | The columns, in order: `{ id, label?, type?, readOnly?, required?, validate?, ...options of the type }`. `readOnly` and `required` can be functions of the record. |
| `@records`              | The rows. Pass a new array when they change.                                                                                                                       |
| `@getRecordId`          | `(record) => id`.                                                                                                                                                  |
| `@onChange`             | `(changeSet) => void`. Apply it to your records.                                                                                                                   |
| `@cellErrors`           | Your own errors: `{ [recordId]: { [fieldId]: message \| messages } }`. Shown last.                                                                                 |
| `@validate`             | Record, cross-row and server rules (below).                                                                                                                        |
| `@fieldTypes`           | Your field types, merged over the built-in ones. Keep the object stable.                                                                                           |
| `@readOnly`             | Every cell read-only (copy still works).                                                                                                                           |
| `@messages`             | Overrides of the built-in messages (below).                                                                                                                        |
| `@height`, `@ariaLabel` | The grid's height; its accessible name (default `Sheet`).                                                                                                          |

## Your own store

`localRecords` is a small tracked store for demos and simple pages. With
your own store, apply the change set yourself:

```ts
interface ChangeSet {
  source: 'edit' | 'paste' | 'clear';
  patches: { recordId; fieldId; from; to }[]; // cells of existing records
  inserts: { tempId; index; values }[]; // rows pasted past the end
  rejected: { recordId?; tempId?; fieldId; text; message }[];
  newOptions: { fieldId; option }[]; // options created on paste
}
```

- `applyChangeSet(records, changeSet, { getRecordId, createRecord? })`
  returns the new records (patched records are new objects; the others
  keep their identity). The default `createRecord` uses the `tempId` as the
  new record's `id`.
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

| Key                     | On a cell                                                                       | In an editor                |
| ----------------------- | ------------------------------------------------------------------------------- | --------------------------- |
| A printable key         | Opens the editor with that character (a date: digits only; never on a checkbox) | Types                       |
| Enter, F2, double-click | Opens the editor on the current value (a date: the browser's date input)        | Enter saves and goes down   |
| Tab, Shift+Tab          | The grid's                                                                      | Saves and goes right / left |
| Escape                  | The grid's                                                                      | Closes without saving       |
| Space                   | Toggles a checkbox; does nothing elsewhere                                      | Types                       |
| Delete, Backspace       | Clears the selected range                                                       | Deletes                     |
| Shift+arrows            | Selects a range                                                                 | Moves in the text           |
| Ctrl/Cmd+C, Ctrl/Cmd+V  | Copies / pastes the range as TSV                                                | Native                      |

In a select editor, typing filters the options, ArrowUp/ArrowDown move,
Enter or a click picks. A click on another cell, or scrolling the grid,
saves the editor's text and closes it.

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
`euiSheet.unresolved` (`{text}`).

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

| Key                 |                                                                                                                                                                       |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cell`              | Display component: `@value @text @field @record @errors @readOnly @onCommit(value)`. It must not render a tabbable element.                                           |
| `editor`            | Editor component: `@value @field @record @draft @initialKey @onDraftChange(text) @onCommit(result?, { move? }) @onCancel @messages`. It focuses itself when inserted. |
| `editorLayout`      | `'cell'` (over the cell, default) or `'panel'` (a panel below or above it).                                                                                           |
| `opensOnKey(key)`   | Whether a printable key opens the editor.                                                                                                                             |
| `handlesKey(event)` | Keys the open editor handles itself (the sheet then leaves them alone; Enter, Tab and Escape are otherwise the sheet's).                                              |

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

## Limits (v0.1)

No undo, fill handle, mouse drag selection, sorting or filtering UI,
fullscreen, row insert or delete buttons, IME composition, quoted TSV
cells or control columns. Pasted text in a field whose type returns
`{ unresolved }` is a rejection (bulk resolve on paste is planned). Colours
are fixed (no dark mode yet).
