---
order: 1
---

# Cell actions, popovers and interactive cells

<EuiText>

The "Status" column has two hover actions and a third one in its popover.
The "Link" column is not expandable and contains a link: focus the cell and
press Enter to reach it.

</EuiText>

```hbs template
<EuiText @size="s"><p>Last action: {{or this.lastAction "none"}}</p></EuiText>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Cell actions demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @toolbarVisibility={{false}}
>
  <:cell as |cell|>
    {{#if (eq cell.columnId "link")}}
      <EuiLink @href="#">Open {{get (get this.rows cell.rowIndex) "service"}}</EuiLink>
    {{else}}
      {{get (get this.rows cell.rowIndex) cell.columnId}}
    {{/if}}
  </:cell>
  <:cellPopover as |popover|>
    <EuiText @size="s">
      <p><strong>{{popover.columnId}}</strong> of row {{popover.rowIndex}}:</p>
      <p>{{get (get this.rows popover.rowIndex) popover.columnId}}</p>
    </EuiText>
    <popover.cellActions />
  </:cellPopover>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class CellActionsDemo extends Component {
  @tracked lastAction = null;

  record = (name) => ({ rowIndex, columnId }) => {
    this.lastAction = `${name} ${columnId} of row ${rowIndex}`;
  };

  columns = [
    { id: 'service', displayAsText: 'Service' },
    {
      id: 'status',
      displayAsText: 'Status',
      cellActions: [
        { iconType: 'plusInCircle', label: 'Filter for value', onClick: this.record('Filter for') },
        { iconType: 'minusInCircle', label: 'Filter out value', onClick: this.record('Filter out') },
        { iconType: 'copyClipboard', label: 'Copy value', onClick: this.record('Copy') }
      ]
    },
    { id: 'link', displayAsText: 'Link', isExpandable: false }
  ];

  rows = ['checkout', 'search', 'accounts', 'payments', 'inventory', 'shipping'].map((service, i) => ({
    service,
    status: i % 4 === 0 ? 'degraded' : 'healthy'
  }));
}
```
