---
order: 2
---

# Messages for one sheet

<EuiText>

`@messages` replaces single texts for this sheet only, without touching
the translations. Each message is a function (the ones with
placeholders get an argument). Keep the object stable, here a class
field, so the sheet is not given a new one on every render. Click the
red cell, look at the add row's label and at the empty state: delete
every record to see it.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Inspection', required: true, width: 220 },
  { id: 'area', label: 'Area', width: 130 },
  { id: 'date', label: 'Date', type: 'date', width: 120 },
  { id: 'findings', label: 'Findings', type: 'number', min: 0, width: 100 }
];

export default class SheetOwnMessages extends Component {
  getId = (record) => record.id;
  store = localRecords(
    inspections()
      .slice(0, 3)
      .map((record, i) => (i === 1 ? { ...record, title: '' } : record)),
    { getRecordId: this.getId, fields: FIELDS }
  );

  // stable: one object for the life of this sheet
  messages = {
    required: () => 'Fill this in',
    addRecord: () => 'Add inspection',
    noRecords: () => 'No inspections yet'
  };

  <template>
    <EuiSheet
      @fields={{FIELDS}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @messages={{this.messages}}
      @height={{220}}
      @ariaLabel='Inspections with own messages'
    />
  </template>
}
```
