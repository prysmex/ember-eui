---
order: 1
---

# Your own column menu items

<EuiText>

Open the menu (the arrow) of any header. "Summarize" and "Show history"
are the app's `@fieldActions`; "Summarize" is disabled on fields that
are not numbers (`isDisabled`). "Filter by this field" calls
`@onFilterByField`, and the message below shows what the owner got.
Hover the info icon of "Findings" and "Score" for the field's
`description`. "Area" has `hideable: false` (no "Hide column"; the
first field never has one), and "Date" has `manageable: false`: the
other fields have Edit, Duplicate and Delete field (the `localRecords`
handlers are passed), "Date" has none, as a system field.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiCallOut, EuiSpacer } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Title', required: true },
  { id: 'area', label: 'Area', hideable: false },
  { id: 'date', label: 'Date', type: 'date', manageable: false },
  {
    id: 'findings',
    label: 'Findings',
    type: 'number',
    min: 0,
    description: 'Open findings raised in this walk-through'
  },
  {
    id: 'score',
    label: 'Score',
    type: 'number',
    min: 0,
    max: 1,
    description: 'Compliance score, from 0 to 1'
  },
  { id: 'passed', label: 'Passed', type: 'checkbox' }
];

export default class SheetFieldActions extends Component {
  getId = (record) => record.id;
  store = localRecords(inspections(), {
    getRecordId: this.getId,
    fields: FIELDS
  });

  @tracked message = 'Open a column menu and pick an item.';

  // stable: the columns are built from this array
  fieldActions = [
    {
      id: 'summarize',
      label: 'Summarize',
      icon: 'visBarVertical',
      isDisabled: (field) => field.type !== 'number',
      onSelect: (field) => {
        const values = this.store.records.map((record) =>
          Number(record[field.id] ?? 0)
        );
        const sum = values.reduce((a, b) => a + b, 0);
        this.message = `${field.label}: sum ${Math.round(sum * 100) / 100}, average ${Math.round((sum / values.length) * 100) / 100}.`;
      }
    },
    {
      id: 'history',
      label: 'Show history',
      icon: 'clock',
      onSelect: (field) => {
        this.message = `Your own dialog for the history of "${field.label}" would open here.`;
      }
    }
  ];

  onChange = (changeSet) => {
    this.store.apply(changeSet);
  };

  onFilterByField = (fieldId) => {
    this.message = `onFilterByField('${fieldId}'): your filter UI opens for this field.`;
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @fieldActions={{this.fieldActions}}
      @onFilterByField={{this.onFilterByField}}
      @onFieldCreate={{this.store.createField}}
      @onFieldUpdate={{this.store.updateField}}
      @onFieldDelete={{this.store.deleteField}}
      @height={{260}}
      @ariaLabel='Inspections'
    />
    <EuiSpacer @size='s' />
    <EuiCallOut @size='s' @title={{this.message}} />
  </template>
}
```
