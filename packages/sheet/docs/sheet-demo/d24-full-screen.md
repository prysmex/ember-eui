---
order: 24
---

# Full screen and column tools

<EuiText>

The toolbar is the app's: its buttons use the block API. **Full screen**
calls `sheet.setFullScreen`: the sheet (toolbar, grid and footer) fills the
window and the page behind stops scrolling; the button's icon and label
follow `sheet.isFullScreen`. Escape on a cell leaves full screen once
nothing else uses it (an open editor or menu, the copy mark, a range).
**Fit all fields** calls `api.fitFields()`: each column takes the width of
its header and its widest loaded cell (80 to 480 px). One column at a
time: "Fit to content" in its header menu, or a double-click on its
resize edge.

The header menu also has an app item, "Summarize" (`@fieldActions`),
enabled on the number fields only; it writes the column's total in the
footer. It sits after the sheet's items and before "Delete field" (the
fields are `localRecords`' here, so Edit, Insert and Delete work, in full
screen too). The row menu has "Copy with field names"
(`@copyWithFieldNames`): the rows as tab-separated text after a line of
the column names, to paste into a report or an email.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { EuiButtonEmpty, EuiFlexGroup, EuiFlexItem, EuiText } from '@ember-eui/core/components';
import { EuiSheet, defaultMessages, localRecords } from '@ember-eui/sheet';

const SITES = [
  { value: 'mty', label: 'Monterrey, Nuevo León' },
  { value: 'gdl', label: 'Guadalajara' },
  { value: 'qro', label: 'Querétaro (north plant, building 3)', color: 'accent' },
];

const FIELDS = [
  { id: 'item', label: 'Item', width: 120 },
  { id: 'site', label: 'Site', type: 'singleSelect', options: SITES, width: 110 },
  { id: 'notes', label: 'Notes', width: 120 },
  { id: 'qty', label: 'Quantity on hand', type: 'number', width: 90 },
  { id: 'cost', label: 'Unit cost', type: 'currency', currency: 'MXN', width: 90 },
  { id: 'audited', label: 'Audited', type: 'checkbox', width: 90 },
];

const NOTES = [
  'Reorder before the end of the month',
  '',
  'Two boxes damaged in transit, claim open with the carrier',
  'Ok',
];

const RECORDS = Array.from({ length: 40 }, (_, i) => ({
  id: `i${i + 1}`,
  item: `Part ${String(i + 1).padStart(3, '0')}`,
  site: SITES[i % 3].value,
  notes: NOTES[i % 4],
  qty: (i * 37) % 500,
  cost: 12.5 + ((i * 13) % 90),
  audited: i % 3 === 0,
}));

export default class SheetFullScreen extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });
  messages = defaultMessages;
  api = null;
  @tracked total = null;

  registerApi = (api) => (this.api = api);
  fitAll = () => this.api?.fitFields();

  fieldActions = [
    {
      id: 'summarize',
      label: 'Summarize',
      icon: 'number',
      isDisabled: (field) => field.type !== 'number' && field.type !== 'currency',
      onSelect: (field) => {
        const sum = this.store.records.reduce((total, record) => total + (Number(record[field.id]) || 0), 0);
        this.total = `${field.label}: ${Math.round(sum * 100) / 100}`;
      },
    },
  ];

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @registerApi={{this.registerApi}}
      @onFieldCreate={{this.store.createField}}
      @onFieldUpdate={{this.store.updateField}}
      @onFieldDelete={{this.store.deleteField}}
      @fieldActions={{this.fieldActions}}
      @copyWithFieldNames={{true}}
      @height={{320}}
      @ariaLabel='Inventory'
    >
      <:toolbar as |sheet|>
        <EuiFlexGroup @gutterSize='s' @alignItems='center' @responsive={{false}}>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty
              @size='s'
              @iconType={{if sheet.isFullScreen 'fullScreenExit' 'fullScreen'}}
              data-test-subj='fullScreenButton'
              {{on 'click' (fn sheet.setFullScreen (if sheet.isFullScreen false true))}}
            >
              {{if sheet.isFullScreen (this.messages.exitFullScreen) (this.messages.enterFullScreen)}}
            </EuiButtonEmpty>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @size='s' @iconType='editorDistributeHorizontal' data-test-subj='fitAllButton' {{on 'click' this.fitAll}}>
              {{this.messages.fitAllFields}}
            </EuiButtonEmpty>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
      <:footer>
        <EuiText @size='xs' @color='subdued' data-test-subj='summaryText'>
          <p>{{if this.total this.total '40 items. "Summarize" in a number column’s menu adds its total here.'}}</p>
        </EuiText>
      </:footer>
    </EuiSheet>
  </template>
}
```
