---
order: 1
---

# Field types

<EuiText>

One column of each built-in type. Quantity takes 0 to 100; Item and
Status are `required`. A select option's `color` is any color
`EuiBadge` takes. Type on a Status cell to filter its options; on a Due
cell, Enter opens the browser's date input and a digit opens a text
input (`19/11/2026`). Space toggles Checked. Rows 3 and 5 start with
errors: a quantity over the `max`, missing required values and a date
before the `min`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'item', label: 'Item (text)', required: true, maxLength: 30 },
  { id: 'quantity', label: 'Quantity (number)', type: 'number', min: 0, max: 100 },
  { id: 'checked', label: 'Checked (checkbox)', type: 'checkbox' },
  {
    id: 'status',
    label: 'Status (singleSelect)',
    type: 'singleSelect',
    required: true,
    options: [
      { value: 'todo', label: 'To do' },
      { value: 'doing', label: 'In progress', color: 'primary' },
      { value: 'blocked', label: 'Blocked', color: 'danger' },
      { value: 'done', label: 'Done', color: 'success' },
      { value: 'review', label: 'In review', color: '#E7664C' },
    ],
  },
  { id: 'due', label: 'Due (date)', type: 'date', min: '2026-01-01' },
];

const RECORDS = [
  { id: 'i1', item: 'Fire extinguishers', quantity: 12, checked: true, status: 'done', due: '2026-11-02' },
  { id: 'i2', item: 'First aid kits', quantity: 4, checked: false, status: 'doing', due: '2026-11-20' },
  { id: 'i3', item: 'Safety glasses', quantity: 140, checked: false, status: 'todo', due: '2026-12-01' },
  { id: 'i4', item: 'Emergency lights', quantity: 8, checked: true, status: 'blocked', due: null },
  { id: 'i5', item: '', quantity: null, checked: false, status: null, due: '2025-12-31' },
  { id: 'i6', item: 'Gloves', quantity: 60, checked: false, status: 'review', due: '2026-11-28' },
];

export default class SheetFieldTypes extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{280}}
      @ariaLabel='Inventory'
    />
  </template>
}
```
