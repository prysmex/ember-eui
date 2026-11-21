---
order: 1
---

# Undo and redo buttons

<EuiText>

The toolbar's buttons call `api.undo()` and `api.redo()`, the same as
Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z on the grid. Each undo or redo is one
more change set through `@onChange` (the list shows their `source`), and
the store applies it like an edit. Edit two cells, paste a block, then
press Undo three times and Redo once. **Clear history** calls
`api.clearHistory()`: Undo then does nothing. The sheet does not tell
you whether there is something to undo, so the buttons stay enabled; an
undo with nothing to undo emits nothing.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { EuiButtonEmpty, EuiText } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { products } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'name', label: 'Product', required: true, width: 200 },
  {
    id: 'price',
    label: 'Price',
    type: 'currency',
    currency: 'MXN',
    locale: 'es-MX',
    min: 0
  },
  { id: 'stock', label: 'Stock', type: 'number', min: 0 }
];

export default class UndoButtons extends Component {
  getId = (record) => record.id;
  store = localRecords(products(), { getRecordId: this.getId, fields: FIELDS });

  @tracked log = [];

  onChange = (changeSet) => {
    this.store.apply(changeSet);
    const cells =
      changeSet.patches.length +
      changeSet.inserts.length +
      (changeSet.deletes?.length ?? 0);
    this.log = [
      `${changeSet.source}: ${cells} cells or records`,
      ...this.log
    ].slice(0, 6);
  };

  clear = (api) => {
    api.clearHistory();
    this.log = ['history cleared', ...this.log].slice(0, 6);
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @height={{230}}
      @ariaLabel='Products'
    >
      <:toolbar as |sheet|>
        <EuiButtonEmpty
          @size='s'
          @iconType='editorUndo'
          {{on 'click' sheet.api.undo}}
        >Undo</EuiButtonEmpty>
        <EuiButtonEmpty
          @size='s'
          @iconType='editorRedo'
          {{on 'click' sheet.api.redo}}
        >Redo</EuiButtonEmpty>
        <EuiButtonEmpty
          @size='s'
          @iconType='eraser'
          {{on 'click' (fn this.clear sheet.api)}}
        >Clear history</EuiButtonEmpty>
      </:toolbar>
    </EuiSheet>
    <EuiText @size='s'>
      <ul>
        {{#each this.log as |line|}}
          <li>{{line}}</li>
        {{else}}
          <li>No change sets yet.</li>
        {{/each}}
      </ul>
    </EuiText>
  </template>
}
```
