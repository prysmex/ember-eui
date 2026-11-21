---
order: 1
---

# Records: add, delete, duplicate, the row menu

<EuiText>

The first column numbers the rows. Hover a row for its checkbox and its
expand icon; click a number to select the row (Shift+click or drag for
more), or a column's title to select the column. Click the last row, or
press Enter on it, to add a record; Shift+Enter on a cell adds one below.
Right-click a cell or a number (or press Shift+F10) for the row menu:
insert above or below, duplicate, expand, copy, an app action ("Mark
done", from `@rowActions`) and delete. Checked rows are what the menu acts
on; with none checked, the selected rows. Each of the sheet's actions is
one change set, shown on the right, and one Ctrl/Cmd+Z ("Mark done" is the
app's own change to its store, so it is not in the sheet's undo history).

New records get a city from the row above them (`@newRecordValues`). The
"Ids as row labels" switch passes `@rowLabel`, so the column shows each
record's id instead of its position.

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

const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  { id: 'city', label: 'City' },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'done', label: 'Done', type: 'checkbox' },
];

const RECORDS = Array.from({ length: 8 }, (_, i) => ({
  id: `w${i + 1}`,
  name: ['Ana', 'Luis', 'Marta', 'Jorge'][i % 4] + ` ${i + 1}`,
  city: ['Monterrey', 'Madrid', 'Lima'][i % 3],
  hours: (i * 5) % 30,
  done: false,
}));

export default class SheetRecords extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  @tracked changeSets = [];
  @tracked showIds = false;
  @tracked checked = [];

  newRecordValues = ({ above }) => ({ city: above?.city ?? 'Monterrey', done: false });

  rowActions = [
    {
      id: 'markDone',
      label: 'Mark done',
      icon: 'check',
      isDisabled: (records) => records.every((record) => record.done),
      onSelect: (records) =>
        this.onChange({
          source: 'edit',
          patches: records
            .filter((record) => !record.done)
            .map((record) => ({ recordId: record.id, fieldId: 'done', from: record.done, to: true })),
          inserts: [],
          rejected: [],
          newOptions: [],
        }),
    },
  ];

  get rowLabel() {
    return this.showIds ? (record) => record.id : undefined;
  }

  toggleIds = (event) => {
    this.showIds = event.target.checked;
  };

  onCheckedChange = (ids) => {
    this.checked = ids;
  };

  onChange = (changeSet) => {
    this.store.apply(changeSet);
    this.changeSets = [changeSet, ...this.changeSets].slice(0, 3);
  };

  get log() {
    return this.changeSets.length
      ? JSON.stringify(this.changeSets, (key, value) => (key === 'record' ? '…' : value), 2)
      : '// add, delete or duplicate a record';
  }

  <template>
    <EuiFlexGroup @gutterSize='l' @wrap={{true}}>
      <EuiFlexItem @grow={{2}}>
        <EuiSwitch @label='Ids as row labels' @checked={{this.showIds}} @onChange={{this.toggleIds}} />
        <EuiSpacer @size='s' />
        <EuiSheet
          @fields={{this.store.fields}}
          @records={{this.store.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.onChange}}
          @rowLabel={{this.rowLabel}}
          @newRecordValues={{this.newRecordValues}}
          @rowActions={{this.rowActions}}
          @checkedRecordIds={{this.checked}}
          @onCheckedChange={{this.onCheckedChange}}
          @height={{360}}
          @ariaLabel='Workers'
        />
        <EuiSpacer @size='s' />
        <p>Checked: {{if this.checked.length this.checked.length 'none'}}</p>
      </EuiFlexItem>
      <EuiFlexItem @grow={{1}}>
        <EuiTitle @size='xxs'><h4>Last change sets ({{this.store.records.length}} records)</h4></EuiTitle>
        <EuiCodeBlock @language='json' @fontSize='s' @paddingSize='s' @overflowHeight={{360}}>{{this.log}}</EuiCodeBlock>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
