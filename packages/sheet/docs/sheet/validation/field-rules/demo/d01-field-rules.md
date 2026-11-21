---
order: 1
---

# Rules on each field

<EuiText>

An inspection log where every rule is on its field: Title is `required`
and at most 40 characters; Permit must match `pattern` (`PER-` and four
digits, with its own `patternMessage`); the Date must be in 2026 (`min`,
`max`); the Score is a `percent` from 0 to 100% (`min: 0`, `max: 1`, as
fractions); Findings is a `number` from 0 to 50 that must also be whole,
a rule of its own (`validate`); and Contact and Report must be an email
and a web address. The last three rows start with errors: click a red
cell to read its message under it. Type `abc` on Findings: the text is
rejected (not stored); type `2.5`: it is stored, and the cell says why
it is wrong.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Title', required: true, maxLength: 40, width: 220 },
  {
    id: 'permit',
    label: 'Permit',
    pattern: /^PER-\d{4}$/,
    patternMessage: 'Use PER- and four digits, as PER-0042'
  },
  {
    id: 'date',
    label: 'Date',
    type: 'date',
    min: '2026-01-01',
    max: '2026-12-31'
  },
  { id: 'score', label: 'Score', type: 'percent', min: 0, max: 1 },
  {
    id: 'findings',
    label: 'Findings',
    type: 'number',
    min: 0,
    max: 50,
    validate: (value) =>
      Number.isInteger(value) ? undefined : 'A whole number of findings'
  },
  { id: 'contact', label: 'Contact', type: 'email' },
  { id: 'report', label: 'Report', type: 'url' }
];

const RECORDS = inspections().map((record, index) => ({
  ...record,
  permit: `PER-${String(index + 41).padStart(4, '0')}`,
  contact: record.inspector?.email ?? null,
  report: `https://reports.example.com/${record.id}`
}));

// three rows that break a rule each way
Object.assign(RECORDS[3], {
  permit: 'P-42',
  score: 1.2,
  findings: 2.5,
  report: 'reports'
});
Object.assign(RECORDS[4], {
  date: '2025-12-30',
  contact: 'ana(at)prysmex.com'
});
Object.assign(RECORDS[5], { title: '', findings: 60 });

export default class FieldRules extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{280}}
      @ariaLabel='Inspections'
    />
  </template>
}
```
