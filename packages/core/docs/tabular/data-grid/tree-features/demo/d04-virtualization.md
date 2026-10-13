---
order: 4
---

# A 20,000-row tree

<EuiText>

40 regions × 50 stores × 10 departments, all expanded: 20,440 visible
rows. Only the rows in view are rendered. Scroll, then collapse a store or
press ArrowLeft on a department: toggling rebuilds the visible list in
about a millisecond.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Large tree"
  @columns={{this.columns}}
  @rowTree={{hash rows=this.regions defaultExpandedRowIds="all"}}
  @height={{400}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

export default class VirtualizationDemo extends Component {
  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 280 },
    { id: 'sales', displayAsText: 'Sales', schema: 'numeric' }
  ];

  regions = Array.from({ length: 40 }, (_, r) => ({
    id: `r${r}`,
    name: `Region ${r + 1}`,
    sales: 500 * (r + 1),
    children: Array.from({ length: 50 }, (_, s) => ({
      id: `r${r}s${s}`,
      name: `Store ${r + 1}.${s + 1}`,
      sales: 10 * (s + 1),
      children: Array.from({ length: 10 }, (_, d) => ({
        id: `r${r}s${s}d${d}`,
        name: `Department ${d + 1}`,
        sales: (r * 7 + s * 3 + d) % 97
      }))
    }))
  }));
}
```
