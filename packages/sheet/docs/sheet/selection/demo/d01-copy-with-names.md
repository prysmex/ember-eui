---
order: 1
---

# Copy with field names

<EuiText>

Select a few rows (click the row numbers, or drag over cells), open the
row menu (right-click, or the row's menu) and pick "Copy with field names":
the rows go to the clipboard after a line with the field labels. Paste
them in the box below with Ctrl/Cmd+V. A normal "Copy" has no label
line. The line under the sheet is `@onSelectionChange`: the selection's
`kind` and `cellCount`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiSpacer, EuiText, EuiTextArea } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Title', required: true, width: 220 },
  { id: 'area', label: 'Area' },
  { id: 'date', label: 'Date', type: 'date' },
  { id: 'findings', label: 'Findings', type: 'number', min: 0 }
];

export default class SheetCopyWithNames extends Component {
  getId = (record) => record.id;
  store = localRecords(inspections(), {
    getRecordId: this.getId,
    fields: FIELDS
  });

  @tracked selection = null;
  @tracked pasted = '';

  onChange = (changeSet) => {
    this.store.apply(changeSet);
  };

  onSelectionChange = (selection) => {
    this.selection = selection;
  };

  onInput = (event) => {
    this.pasted = event.target.value;
  };

  get selectionText() {
    const selection = this.selection;
    return selection
      ? `Selection: kind "${selection.kind}", cellCount ${selection.cellCount} (${selection.records.length} records x ${selection.fields.length} fields).`
      : 'Selection: none.';
  }

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @copyWithFieldNames={{true}}
      @onSelectionChange={{this.onSelectionChange}}
      @height={{240}}
      @ariaLabel='Inspections'
    />
    <EuiSpacer @size='s' />
    <EuiText @size='s'><p>{{this.selectionText}}</p></EuiText>
    <EuiSpacer @size='s' />
    <EuiTextArea
      @value={{this.pasted}}
      @fullWidth={{true}}
      @rows={{5}}
      placeholder='Paste the copied rows here'
      aria-label='Pasted rows'
      {{on 'input' this.onInput}}
    />
  </template>
}
```
