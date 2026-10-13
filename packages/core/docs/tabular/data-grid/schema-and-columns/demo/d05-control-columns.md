---
order: 5
---

# Row selection and a totals footer

```hbs template
<EuiDataGrid
  aria-label="Control columns demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @leadingControlColumns={{this.leading}}
  @trailingControlColumns={{this.trailing}}
  @height={{320}}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
  <:controlHeaderCell as |cell|>
    {{#if (eq cell.columnId "select")}}
      <EuiCheckbox
        aria-label="Select all rows"
        @checked={{this.allSelected}}
        @indeterminate={{this.someSelected}}
        {{on "change" this.toggleAll}}
      />
    {{else}}
      <EuiScreenReaderOnly><span>Actions</span></EuiScreenReaderOnly>
    {{/if}}
  </:controlHeaderCell>
  <:controlCell as |cell|>
    {{#if (eq cell.columnId "select")}}
      <EuiCheckbox
        aria-label="Select row {{cell.rowIndex}}"
        @checked={{get this.selected (concat cell.rowIndex)}}
        {{on "change" (fn this.toggle cell.rowIndex)}}
      />
    {{else}}
      <EuiButtonIcon @iconType="trash" @size="xs" @color="danger" aria-label="Delete row {{cell.rowIndex}}" />
    {{/if}}
  </:controlCell>
  <:footerCell as |cell|>
    {{#if (eq cell.columnId "amount")}}Total: {{this.total}}{{/if}}
  </:footerCell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ControlColumnsDemo extends Component {
  @tracked selected = {};

  columns = [
    { id: 'item', displayAsText: 'Item' },
    { id: 'amount', displayAsText: 'Amount', schema: 'numeric' }
  ];

  leading = [{ id: 'select', width: 36 }];
  trailing = [{ id: 'actions', width: 40 }];

  rows = ['Keyboard', 'Mouse', 'Monitor', 'Cable', 'Dock', 'Webcam', 'Lamp', 'Chair'].map(
    (item, i) => ({ item, amount: String((i + 2) * 15) })
  );

  get total() {
    return this.rows.reduce((sum, row) => sum + Number(row.amount), 0);
  }

  get selectedCount() {
    return Object.values(this.selected).filter(Boolean).length;
  }

  get allSelected() {
    return this.selectedCount === this.rows.length;
  }

  get someSelected() {
    return this.selectedCount > 0 && !this.allSelected;
  }

  @action toggle(rowIndex) {
    this.selected = { ...this.selected, [rowIndex]: !this.selected[rowIndex] };
  }

  @action toggleAll() {
    const all = !this.allSelected;
    this.selected = Object.fromEntries(this.rows.map((_, i) => [i, all]));
  }
}
```
