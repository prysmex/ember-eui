---
title: Your own store
order: 2
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: your own store"/>
<EuiSpacer @size="l" />

<EuiText>

The sheet never changes your records: it hands every edit to
`@onChange` as a change set, and you apply it. `localRecords` does that
for local data; a store backed by an API applies the change set itself,
with `applyChangeSet`, and tells the sheet the ids the server gave the
new records.

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
sheet with `api.remapIds({ [tempId]: newId })` ([The sheet's API](/docs/sheet/docs/sheet/more/api-reference#the-sheets-api)), so that undo
still finds it.

## Related

- [Editing basics](/docs/sheet/docs/sheet/editing): what makes a change set
- [Undo and redo](/docs/sheet/docs/sheet/editing/undo-redo): undo with your own ids
- [Server checks and rejections](/docs/sheet/docs/sheet/validation/server-checks): errors from saving
- [Row drag and order](/docs/sheet/docs/sheet/rows/drag): the `moves` of a change set
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
