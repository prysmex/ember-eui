---
order: 1
---

# A locked field, locked records, a locked sheet

<EuiText>

Three levels of read-only. **ID** is read-only on every record
(`readOnly: true`). A closed inspection is locked: every field but
Status has `readOnly(record)`, true when the status is Closed, so set a
row to Closed and its cells lock, set it back and they open. The switch
passes `@readOnly`: nothing can be edited, inserted or deleted, but
cells can still be selected and copied. Select rows 2 to 4 and paste a
block on them, or press Delete: the locked cells are skipped and the
rest change.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiSpacer, EuiSwitch } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections, SITES, STATUSES } from 'site/utils/sheet-docs-data';

const isClosed = (record) => record.status === 'closed';

const FIELDS = [
  { id: 'id', label: 'ID', readOnly: true },
  { id: 'title', label: 'Title', readOnly: isClosed, width: 220 },
  {
    id: 'site',
    label: 'Site',
    type: 'singleSelect',
    options: SITES,
    readOnly: isClosed,
    width: 170
  },
  { id: 'status', label: 'Status', type: 'singleSelect', options: STATUSES },
  {
    id: 'findings',
    label: 'Findings',
    type: 'number',
    min: 0,
    readOnly: isClosed
  }
];

export default class ReadOnly extends Component {
  getId = (record) => record.id;
  store = localRecords(inspections(), {
    getRecordId: this.getId,
    fields: FIELDS
  });

  @tracked locked = false;

  toggle = (event) => (this.locked = event.target.checked);

  <template>
    <EuiSwitch
      @label='Lock the whole sheet (@readOnly)'
      @checked={{this.locked}}
      @onChange={{this.toggle}}
    />
    <EuiSpacer @size='s' />
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @readOnly={{this.locked}}
      @height={{260}}
      @ariaLabel='Inspections'
    />
  </template>
}
```
