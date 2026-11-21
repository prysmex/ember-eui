---
order: 1
---

# Rules across fields and rows

<EuiText>

Work permits. Two rules come from the record itself: **Closed by** is
required only on a closed permit (`required` as a function of the
record), and **Reason** is read-only unless the permit was rejected
(`readOnly` as a function). Two more need the whole record or every
row, so they are in `@validate`, which the sheet runs on the first
render and after each change: **Ends** must not be before **Starts**,
and a **Permit no.** may be used once. Set a permit to Closed and its
Closed by cell turns red; change row 2's Ends to after its start and the
error goes away; type `PER-0101` on another row. The line under the
sheet counts the runs and the cells each one was told about
(`changed`).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { INSPECTORS } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'number', label: 'Permit no.', required: true },
  { id: 'work', label: 'Work', width: 200 },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    options: [
      { value: 'requested', label: 'Requested' },
      { value: 'approved', label: 'Approved', color: 'primary' },
      { value: 'rejected', label: 'Rejected', color: 'danger' },
      { value: 'closed', label: 'Closed', color: 'success' }
    ]
  },
  { id: 'starts', label: 'Starts', type: 'date' },
  { id: 'ends', label: 'Ends', type: 'date' },
  {
    id: 'closedBy',
    label: 'Closed by',
    type: 'user',
    options: INSPECTORS,
    required: (permit) => permit.status === 'closed'
  },
  {
    id: 'reason',
    label: 'Reason',
    readOnly: (permit) => permit.status !== 'rejected',
    width: 200
  }
];

const PERMITS = [
  {
    id: 'w1',
    number: 'PER-0101',
    work: 'Welding, dock 2',
    status: 'closed',
    starts: '2026-11-02',
    ends: '2026-11-03',
    closedBy: INSPECTORS[0],
    reason: null
  },
  {
    id: 'w2',
    number: 'PER-0102',
    work: 'Roof access, hall B',
    status: 'approved',
    starts: '2026-11-10',
    ends: '2026-11-08',
    closedBy: null,
    reason: null
  },
  {
    id: 'w3',
    number: 'PER-0103',
    work: 'Confined space, tank 4',
    status: 'rejected',
    starts: '2026-11-12',
    ends: '2026-11-12',
    closedBy: null,
    reason: 'No gas test on file'
  },
  {
    id: 'w4',
    number: 'PER-0103',
    work: 'Electrical, panel 7',
    status: 'closed',
    starts: '2026-11-14',
    ends: '2026-11-15',
    closedBy: null,
    reason: null
  },
  {
    id: 'w5',
    number: 'PER-0105',
    work: 'Hot work, press line',
    status: 'requested',
    starts: '2026-11-20',
    ends: null,
    closedBy: null,
    reason: null
  }
];

function addError(errors, id, fieldId, message) {
  const record = (errors[id] ??= {});
  record[fieldId] = [...(record[fieldId] ?? []), message];
}

export default class RecordChecks extends Component {
  getId = (permit) => permit.id;
  store = localRecords(PERMITS, { getRecordId: this.getId, fields: FIELDS });

  @tracked runs = 0;
  @tracked changed = 0;

  validate = ({ records, changed }) => {
    this.runs++;
    this.changed = changed.length;
    const errors = {};
    const seen = new Map();

    for (const permit of records) {
      // a rule over two fields of one record
      if (permit.starts && permit.ends && permit.ends < permit.starts) {
        addError(errors, permit.id, 'ends', 'Ends before it starts');
      }
      // a rule over every row
      const number = permit.number?.trim().toUpperCase();
      if (number) seen.set(number, [...(seen.get(number) ?? []), permit.id]);
    }
    for (const ids of seen.values()) {
      if (ids.length > 1)
        for (const id of ids)
          addError(errors, id, 'number', 'Another permit has this number');
    }
    return errors;
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @validate={{this.validate}}
      @height={{250}}
      @ariaLabel='Work permits'
    />
    <p>@validate has run
      {{this.runs}}
      times; the last run was told about
      {{this.changed}}
      changed cells.</p>
  </template>
}
```
