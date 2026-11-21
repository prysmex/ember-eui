---
order: 1
---

# A narrow sheet and where it edits

<EuiText>

The sheet sits in a 360 px box, like a phone. The selection handles (the
round dots on the selected cell's corners) show on touch screens only, so
with a mouse you will not see them: open your browser's devtools, turn on
touch emulation (device toolbar) and reload to try them. Tap a cell, then
drag a handle to extend the range. `@editIn` says where a second tap (or
Enter) edits: "cell" is the editor over the cell, "record" the expanded
record, and "auto" the record on a touch screen narrower than 600 px,
else the cell.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButtonGroup, EuiSpacer } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Title', required: true, width: 180 },
  { id: 'area', label: 'Area', width: 120 },
  { id: 'findings', label: 'Findings', type: 'number', min: 0, width: 100 },
  { id: 'passed', label: 'Passed', type: 'checkbox', width: 100 }
];

const OPTIONS = [
  { id: 'auto', label: 'auto' },
  { id: 'cell', label: 'cell' },
  { id: 'record', label: 'record' }
];

export default class SheetTouchEditIn extends Component {
  getId = (record) => record.id;
  store = localRecords(inspections(), {
    getRecordId: this.getId,
    fields: FIELDS
  });
  options = OPTIONS;

  @tracked editIn = 'auto';

  setEditIn = (id) => {
    this.editIn = id;
  };

  onChange = (changeSet) => {
    this.store.apply(changeSet);
  };

  <template>
    <EuiButtonGroup
      @legend='Edit in'
      @options={{this.options}}
      @idSelected={{this.editIn}}
      @onChange={{this.setEditIn}}
      @buttonSize='compressed'
    />
    <EuiSpacer @size='s' />
    <div style='max-width: 360px'>
      <EuiSheet
        @fields={{this.store.fields}}
        @records={{this.store.records}}
        @getRecordId={{this.getId}}
        @onChange={{this.onChange}}
        @editIn={{this.editIn}}
        @height={{260}}
        @ariaLabel='Inspections on a narrow screen'
      />
    </div>
  </template>
}
```
