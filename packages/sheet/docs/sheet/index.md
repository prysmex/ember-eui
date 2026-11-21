---
title: Getting started
order: 0
manualDemoInsertion: true
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: getting started"/>
<EuiSpacer @size="l" />

<EuiText>

`@ember-eui/sheet` is an Airtable-like grid for data entry, built on
`EuiDataGrid`. People edit cells with the keyboard, select ranges, and
copy and paste blocks to and from Excel or Google Sheets. It has
built-in field types for text, numbers, checkboxes, selects, dates,
linked records, users, attachments, currency, percent, duration, rating,
links and long text, and you can add your own cells and editors.

This page gets a working sheet on screen in five minutes. [The example
app](/docs/sheet/docs/sheet/example-app) then uses the main features
together, and the pages listed under [Next](#next) explain each part.

## Install

```bash
pnpm add @ember-eui/sheet
```

`@ember-eui/core` is a peer dependency: install and set it up first. The
sheet adds its few styles to the page itself; there is no stylesheet to
import.

Import the components in the `.gts` or `.gjs` files that render them:
`import { EuiSheet, EuiSheetImport } from '@ember-eui/sheet'`. The
package adds nothing to your app's tree (no `app-js`), so your app
bundles only what it imports: installed and not rendered, the sheet
costs nothing; `<EuiSheet>` alone does not bring the import screen; and
the barcode scan panel loads when a barcode editor that can scan opens.

A loose-mode template (`.hbs`) does not find `<EuiSheet />` by name. To
use it from one, re-export it in your own app tree; only the components
you re-export are bundled:

```js
// app/components/eui-sheet.js
export { default } from '@ember-eui/sheet/components/eui-sheet';
```

(`app/components/eui-sheet-import.js` the same way for
`<EuiSheetImport />`, from `@ember-eui/sheet/components/eui-sheet-import`.)
Without it, an Embroider build stops with an error that it cannot
resolve `eui-sheet`.

## A sheet in five minutes

A component with a sheet of tasks, for example
`app/components/tasks.gts`:

```gts
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import type { ChangeSet, EuiSheetField } from '@ember-eui/sheet';

interface Task {
  id: string;
  name: string;
  hours: number | null;
  status: string | null;
  billable: boolean;
  due: string | null; // an ISO date, YYYY-MM-DD
}

const FIELDS: EuiSheetField<Task>[] = [
  { id: 'name', label: 'Task', required: true },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    options: [
      { value: 'todo', label: 'To do' },
      { value: 'doing', label: 'Doing', color: 'primary' },
      { value: 'done', label: 'Done', color: 'success' }
    ]
  },
  { id: 'billable', label: 'Billable', type: 'checkbox' },
  { id: 'due', label: 'Due', type: 'date' }
];

const TASKS: Task[] = [
  {
    id: 't1',
    name: 'Inspect line 3',
    hours: 2,
    status: 'done',
    billable: true,
    due: '2026-11-23'
  },
  {
    id: 't2',
    name: 'Order spare belts',
    hours: 1,
    status: 'doing',
    billable: false,
    due: '2026-11-25'
  },
  {
    id: 't3',
    name: 'Train the night shift',
    hours: 6,
    status: 'todo',
    billable: true,
    due: '2026-12-01'
  },
  {
    id: 't4',
    name: 'Update the safety sheet',
    hours: null,
    status: 'todo',
    billable: false,
    due: null
  }
];

export default class Tasks extends Component {
  getId = (task: Task) => task.id;
  store = localRecords(TASKS, { getRecordId: this.getId, fields: FIELDS });

  @tracked lastChange: ChangeSet | null = null;

  onChange = (changeSet: ChangeSet) => {
    this.store.apply(changeSet); // this.store.records are the new records
    this.lastChange = changeSet; // save it to your server here
  };

  get changeText() {
    const change = this.lastChange;
    if (!change) return 'Edit a cell, paste a block or press Delete.';
    return `${change.source}: ${change.patches.length} cells changed, ${change.inserts.length} records added, ${change.rejected.length} texts rejected. ${this.store.records.length} records.`;
  }

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @height={{260}}
      @ariaLabel='Tasks'
    />
    <p>{{this.changeText}}</p>
  </template>
}
```

It runs below, as it is.

- **`localRecords(records, { getRecordId, fields })`** is a small
  tracked store for local data: `store.records` and `store.fields` are
  the current records and fields, and `store.apply(changeSet)` applies
  what the sheet sends. With a store of your own, see [Getting the
  changes](#getting-the-changes).
- **The sheet needs three things**: the fields (`@fields`), the records
  and how to tell them apart (`@records`, and `@getRecordId`, which
  returns a record's id), and what to do with a change (`@onChange`).
  `@height` (the grid's height in px) and `@ariaLabel` (its accessible
  name) are optional; [the API reference](/docs/sheet/docs/sheet/more/api-reference#arguments) lists the
  rest.
- **One field of each common type.** A field is `{ id, label, type }`
  plus the type's options, and the record keeps its value under the
  field's `id`:

| Field    | `type`               | The value in the record       | Try typing or pasting                            |
| -------- | -------------------- | ----------------------------- | ------------------------------------------------ |
| Task     | `text` (the default) | a string                      | anything; `required` marks an empty one          |
| Hours    | `number`             | a number or `null`            | `12`; `abc` is rejected, `-1` breaks `min: 0`    |
| Status   | `singleSelect`       | an option's `value` or `null` | an option's label (`Doing`) or value             |
| Billable | `checkbox`           | `true` or `false`             | Space toggles it; a paste reads `yes`, `x`, `no` |
| Due      | `date`               | `YYYY-MM-DD` or `null`        | `24/12/2026`, `2026-12-24`                       |

[Field types](/docs/sheet/docs/sheet/field-types) has the other types (currency, percent,
users, linked records, attachments, …) and every option.

</EuiText>

[[demos-all]]

<EuiText>

## Getting the changes

The sheet never changes your records. When someone types, pastes,
clears, fills or undoes, it calls `@onChange` with a change set: the
cells that changed (`patches`, each with `recordId`, `fieldId`, `from`
and `to`), the records to add (`inserts`) or remove (`deletes`), and the
texts it could not read (`rejected`). You apply it and pass the new
records back:

- With `localRecords`, call `store.apply(changeSet)` (or pass
  `@onChange={{this.store.apply}}`); `store.records` then has the new
  records, and you can send the change set or the records to your
  server.
- With your own store, `applyChangeSet(records, changeSet, { getRecordId
})` returns the new records, and you pass them as `@records`.

[Your own store](/docs/sheet/docs/sheet/own-store#records-in-change-sets-out) has the
whole change set, [Undo and redo](/docs/sheet/docs/sheet/editing/undo-redo) how undo comes
back through `@onChange`, and [Field rules](/docs/sheet/docs/sheet/validation/field-rules#errors)
the errors a cell can show.

## Next

[The example app](/docs/sheet/docs/sheet/example-app) puts the main
features together in one screen: groups, editing, CSV import and
export, loading more as you scroll and the expanded record, with its
code.

Then each page explains one part of the sheet, with its examples after
its introduction. The pages, by group (also in the side nav):

| Group             | Pages                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Start             | [Example app](/docs/sheet/docs/sheet/example-app); [Your own store](/docs/sheet/docs/sheet/own-store)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Validation        | [Field rules](/docs/sheet/docs/sheet/validation/field-rules); [Whole-record checks](/docs/sheet/docs/sheet/validation/record-checks); [Server checks and rejections](/docs/sheet/docs/sheet/validation/server-checks); [Blocking and warnings](/docs/sheet/docs/sheet/validation/blocking-and-warnings); [Validation while pasting and importing](/docs/sheet/docs/sheet/validation/paste-and-import)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Editing           | [Editing basics](/docs/sheet/docs/sheet/editing); [Keyboard and shortcuts](/docs/sheet/docs/sheet/editing/keyboard); [Undo and redo](/docs/sheet/docs/sheet/editing/undo-redo); [Read-only cells and fields](/docs/sheet/docs/sheet/editing/read-only)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| Field types       | [All field types](/docs/sheet/docs/sheet/field-types); [Text and long text](/docs/sheet/docs/sheet/field-types/text-fields); [Numbers, currency, percent, duration](/docs/sheet/docs/sheet/field-types/numbers); [Dates and times](/docs/sheet/docs/sheet/field-types/dates); [Select, multi-select, colours](/docs/sheet/docs/sheet/field-types/selects); [Checkbox and rating](/docs/sheet/docs/sheet/field-types/checkbox-and-rating); [Email, URL, phone](/docs/sheet/docs/sheet/field-types/email-url-phone); [Linked records](/docs/sheet/docs/sheet/field-types/linked-records); [User](/docs/sheet/docs/sheet/field-types/users); [Attachments and upload progress](/docs/sheet/docs/sheet/field-types/attachments); [Barcode and camera scan](/docs/sheet/docs/sheet/field-types/barcode); [Buttons](/docs/sheet/docs/sheet/field-types/buttons); [Custom field types and editors](/docs/sheet/docs/sheet/field-types/custom-types) |
| Fields            | [Field editor](/docs/sheet/docs/sheet/fields); [Field actions and menus](/docs/sheet/docs/sheet/fields/field-actions); [Hide, reorder, resize, freeze](/docs/sheet/docs/sheet/fields/columns)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Selection         | [Ranges, copy and paste](/docs/sheet/docs/sheet/selection); [Paste rules and new records](/docs/sheet/docs/sheet/selection/paste); [Fill handle](/docs/sheet/docs/sheet/selection/fill-handle); [Touch selection](/docs/sheet/docs/sheet/selection/touch); [Summary footer](/docs/sheet/docs/sheet/selection/summary)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Rows              | [Add, delete, duplicate](/docs/sheet/docs/sheet/rows); [Row drag and order](/docs/sheet/docs/sheet/rows/drag); [Row and cell colours](/docs/sheet/docs/sheet/rows/colours); [Row height](/docs/sheet/docs/sheet/rows/row-height); [Expanded record](/docs/sheet/docs/sheet/rows/expanded-record); [Record footer](/docs/sheet/docs/sheet/rows/record-footer)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Data              | [Groups](/docs/sheet/docs/sheet/data/record-groups); [Sorting](/docs/sheet/docs/sheet/data/sorting); [Load more](/docs/sheet/docs/sheet/data/load-more); [Large data](/docs/sheet/docs/sheet/data/large-sheet); [Search and match stepping](/docs/sheet/docs/sheet/data/search-matches); [EmberSearchUi](/docs/sheet/docs/sheet/data/search-ui)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| Import and export | [CSV export](/docs/sheet/docs/sheet/import-export); [CSV paste and import](/docs/sheet/docs/sheet/import-export/csv-import); [The import screen](/docs/sheet/docs/sheet/import-export/import-screen)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| More              | [Full screen and fit width](/docs/sheet/docs/sheet/more/full-screen); [Translations and messages](/docs/sheet/docs/sheet/more/translations); [Theming and dark mode](/docs/sheet/docs/sheet/more/theme); [API reference](/docs/sheet/docs/sheet/more/api-reference)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |

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
  write them with `setExtension` ([Group by](/docs/sheet/docs/sheet/data/record-groups#group-by)). Sorting, filtering, search,
  paging and grouping are not "not yet": they are the owner's ([The
  owner](/docs/sheet/docs/sheet/more/api-reference#the-owner), and the [EmberSearchUi connector](/docs/sheet/docs/sheet/data/search-ui#embersearchui)), and the sheet draws them.
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
