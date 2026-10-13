---
order: 3
---

# Toggle column

<EuiText>

The first column holds a status icon, so `toggleColumnId="name"` puts the
indentation and the toggle in the "Name" column. The tree keys (arrows,
Space) work in that column's cells.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Toggle column"
  @columns={{this.columns}}
  @rowTree={{hash rows=this.services defaultExpandedRowIds="all" toggleColumnId="name"}}
  @toolbarVisibility={{false}}
  @height={{260}}
>
  <:cell as |cell|>
    {{#if (eq cell.columnId "status")}}
      <EuiIcon
        @type={{if (eq cell.row.status "ok") "checkInCircleFilled" "warning"}}
        @color={{if (eq cell.row.status "ok") "success" "warning"}}
        aria-label={{cell.row.status}}
      />
    {{else}}
      {{get cell.row cell.columnId}}
    {{/if}}
  </:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

export default class ToggleColumnDemo extends Component {
  columns = [
    { id: 'status', displayAsText: 'Status', initialWidth: 70, isExpandable: false },
    { id: 'name', displayAsText: 'Name', initialWidth: 260 },
    { id: 'latency', displayAsText: 'Latency (ms)', schema: 'numeric' }
  ];

  services = [
    {
      id: 'checkout',
      name: 'checkout',
      status: 'ok',
      latency: 120,
      children: [
        { id: 'checkout-db', name: 'postgres', status: 'ok', latency: 12 },
        { id: 'checkout-pay', name: 'payments', status: 'degraded', latency: 840 }
      ]
    },
    {
      id: 'search',
      name: 'search',
      status: 'ok',
      latency: 45,
      children: [{ id: 'search-es', name: 'elasticsearch', status: 'ok', latency: 30 }]
    }
  ];
}
```
