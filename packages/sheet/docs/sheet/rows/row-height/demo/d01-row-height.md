---
order: 1
---

# Row height from a toolbar

<EuiText>

Pick a height in the toolbar: **short** is one line, then 2, 4 and 6. Long notes and a cell's tags wrap and show more lines as the rows grow. The buttons call the block's `setRowHeight`; with no `@onRowHeightChange` the sheet keeps the height itself.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiButtonGroup, EuiSpacer } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const HEIGHTS = [
  { id: 'short', label: 'Short' },
  { id: 'medium', label: 'Medium' },
  { id: 'tall', label: 'Tall' },
  { id: 'extraTall', label: 'Extra tall' }
];

const FIELDS = [
  { id: 'title', label: 'Inspection', required: true, width: 190 },
  {
    id: 'hazards',
    label: 'Hazards',
    type: 'multiSelect',
    options: [
      { value: 'noise', label: 'Noise', color: 'warning' },
      { value: 'height', label: 'Height', color: 'danger' },
      { value: 'chemical', label: 'Chemical', color: 'accent' },
      { value: 'traffic', label: 'Traffic' },
      { value: 'heat', label: 'Heat', color: 'danger' }
    ],
    width: 200
  },
  { id: 'notes', label: 'Notes', type: 'longText', width: 320 }
];

const RECORDS = [
  {
    id: 'n1',
    title: 'Forklift pre-shift check',
    hazards: ['traffic', 'noise'],
    notes:
      'Horn and lights work. Left fork shows wear; schedule a replacement before the next audit. Operator signed the checklist.'
  },
  {
    id: 'n2',
    title: 'Chemical storage',
    hazards: ['chemical', 'heat', 'height', 'noise'],
    notes:
      'Two drums without labels on the top shelf, moved to the quarantine area. Ventilation fan is noisy but within limits.'
  },
  {
    id: 'n3',
    title: 'Emergency exits',
    hazards: ['height'],
    notes:
      'Exit B is blocked by pallets in the afternoon shift. Talk to the dock supervisor and re-check on Friday.'
  },
  {
    id: 'n4',
    title: 'Lockout / tagout, press 4',
    hazards: ['noise', 'heat'],
    notes: 'Tags present, two locks missing. Spare set ordered.'
  }
];

export default class SheetRowHeight extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });
  heights = HEIGHTS;

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{300}}
      @ariaLabel='Inspection notes'
    >
      <:toolbar as |sheet|>
        <EuiButtonGroup
          @legend='Row height'
          @options={{this.heights}}
          @idSelected={{sheet.rowHeight}}
          @onChange={{sheet.setRowHeight}}
          @buttonSize='compressed'
        />
        <EuiSpacer @size='s' />
      </:toolbar>
    </EuiSheet>
  </template>
}
```
