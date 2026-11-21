---
order: 4
---

# Expanded record

<EuiText>

Press Space on a cell (or Enter on a row number, or click a row's expand
icon) to open the record. It lists the columns and then the fields the
grid does not show (`@hiddenFields`: here "Notes" and the read-only
"Created by"). Click a box, or press Enter or type on it, to edit it in
place; Enter saves and goes to the next field, Escape cancels, and Escape
on a box closes the record and puts focus back on its cell. The arrows in
the header go to the previous and next record. The switch shows it in a
modal instead of a flyout (`@expandedRecord`).

Edits there are change sets like any other: "abc" in Hours is rejected
and shown under the box and in the grid, and Ctrl/Cmd+Z undoes.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import {
  EuiCodeBlock,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch,
  EuiTitle,
} from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const STATUS = [
  { value: 'open', label: 'Open' },
  { value: 'review', label: 'In review', color: 'warning' },
  { value: 'closed', label: 'Closed', color: 'success' },
];

const FIELDS = [
  { id: 'title', label: 'Finding', required: true },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'status', label: 'Status', type: 'singleSelect', options: STATUS },
  { id: 'due', label: 'Due', type: 'date' },
  { id: 'urgent', label: 'Urgent', type: 'checkbox' },
];

const HIDDEN = [
  { id: 'notes', label: 'Notes' },
  { id: 'createdBy', label: 'Created by', readOnly: true },
];

const RECORDS = [
  { id: 'f1', title: 'Guard missing on press 2', hours: 3, status: 'open', due: '2026-11-24', urgent: true, notes: 'Seen on the night shift', createdBy: 'Ana' },
  { id: 'f2', title: 'Fire extinguisher expired', hours: 1, status: 'review', due: '2026-11-21', urgent: false, notes: '', createdBy: 'Luis' },
  { id: 'f3', title: 'Spill near loading dock', hours: 2, status: 'closed', due: null, urgent: false, notes: 'Cleaned, cause pending', createdBy: 'Marta' },
  { id: 'f4', title: 'Blocked emergency exit', hours: null, status: 'open', due: '2026-11-20', urgent: true, notes: '', createdBy: 'Jorge' },
];

export default class SheetExpandedRecord extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, {
    getRecordId: this.getId,
    fields: [...FIELDS, ...HIDDEN],
  });
  hiddenFields = HIDDEN;

  @tracked modal = false;
  @tracked changeSets = [];

  get shell() {
    return this.modal ? 'modal' : 'flyout';
  }

  get fields() {
    return this.store.fields.filter((field) => !HIDDEN.some((hidden) => hidden.id === field.id));
  }

  toggleModal = (event) => {
    this.modal = event.target.checked;
  };

  onChange = (changeSet) => {
    this.store.apply(changeSet);
    this.changeSets = [changeSet, ...this.changeSets].slice(0, 3);
  };

  get log() {
    return this.changeSets.length
      ? JSON.stringify(this.changeSets, null, 2)
      : '// press Space on a cell, then edit the record';
  }

  <template>
    <EuiFlexGroup @gutterSize='l' @wrap={{true}}>
      <EuiFlexItem @grow={{2}}>
        <EuiSwitch @label='In a modal' @checked={{this.modal}} @onChange={{this.toggleModal}} />
        <EuiSpacer @size='s' />
        <EuiSheet
          @fields={{this.fields}}
          @hiddenFields={{this.hiddenFields}}
          @records={{this.store.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.onChange}}
          @expandedRecord={{this.shell}}
          @height={{260}}
          @ariaLabel='Findings'
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{1}}>
        <EuiTitle @size='xxs'><h4>Last change sets</h4></EuiTitle>
        <EuiCodeBlock @language='json' @fontSize='s' @paddingSize='s' @overflowHeight={{300}}>{{this.log}}</EuiCodeBlock>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
