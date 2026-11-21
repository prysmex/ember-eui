---
order: 1
---

# Status, area and hazards

<EuiText>

**Status** is a `singleSelect` whose options have colours (a theme name
such as `'success'`, or any CSS colour, as `#E7664C`). **Area** is a
`singleSelect` whose options depend on the record: `options(record)`
lists the areas of its site, so change a row's Site and its Area offers
other options (an area of another site shows as an error). **Hazards** is
a `multiSelect` with `createOnPaste`: paste `Noise, Heat` on a Hazards
cell and Heat becomes a new option (in the change set's `newOptions`,
which `localRecords` adds to the field); typing in its editor only finds
the options there are. Type on a Status cell to filter its options;
Enter or Tab right after typing picks the first match.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections, SITES } from 'site/utils/sheet-docs-data';

const AREAS = {
  mty: ['Dock 2', 'Hall B', 'Paint shop'],
  slp: ['Store 1', 'Building A'],
  qro: ['Press line', 'Mezzanine']
};

const FIELDS = [
  { id: 'title', label: 'Inspection', width: 220 },
  {
    id: 'site',
    label: 'Site',
    type: 'singleSelect',
    options: SITES,
    width: 170
  },
  {
    id: 'area',
    label: 'Area',
    type: 'singleSelect',
    options: (record) =>
      (AREAS[record.site] ?? []).map((area) => ({ value: area, label: area })),
    width: 140
  },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    options: [
      { value: 'open', label: 'Open' },
      { value: 'progress', label: 'In progress', color: 'primary' },
      { value: 'review', label: 'In review', color: '#E7664C' },
      { value: 'closed', label: 'Closed', color: 'success' }
    ]
  },
  {
    id: 'hazards',
    label: 'Hazards',
    type: 'multiSelect',
    createOnPaste: true,
    options: [
      { value: 'noise', label: 'Noise', color: 'warning' },
      { value: 'height', label: 'Height', color: 'danger' },
      { value: 'chemical', label: 'Chemical', color: 'accent' },
      { value: 'traffic', label: 'Traffic' }
    ],
    width: 220
  }
];

const HAZARDS = [
  ['traffic'],
  ['noise', 'height'],
  ['chemical'],
  [],
  ['traffic', 'noise', 'height', 'chemical'],
  ['height']
];

export default class Selects extends Component {
  getId = (record) => record.id;
  store = localRecords(
    inspections().map((record, index) => ({
      ...record,
      hazards: HAZARDS[index]
    })),
    { getRecordId: this.getId, fields: FIELDS }
  );

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{270}}
      @ariaLabel='Inspections'
    />
  </template>
}
```
