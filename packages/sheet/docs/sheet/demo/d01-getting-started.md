---
order: 1
---

# Tasks

<EuiText>

The component above, as it is. Edit a cell (type, or Enter to open the
editor), paste a block from a spreadsheet, select a range and press
Delete, then Ctrl/Cmd+Z: the line under the sheet shows the last change
set the sheet sent. Paste `abc` on Hours: the cell keeps the text, marked
invalid, and the change set lists it in `rejected`. Space on a cell opens
the record.

</EuiText>

```gts component
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
