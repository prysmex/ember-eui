---
order: 1
---

# Initially expanded rows

<EuiText>

The first grid starts with everything expanded (`'all'`), the second with
just `src`. Both are uncontrolled: the grid owns the state after that.

</EuiText>

```hbs template
<EuiTitle @size="xxs" @tagName="h3">defaultExpandedRowIds="all"</EuiTitle>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="All rows expanded"
  @columns={{this.columns}}
  @rowTree={{hash rows=this.files defaultExpandedRowIds="all"}}
  @toolbarVisibility={{false}}
  @height={{240}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
<EuiSpacer />
<EuiTitle @size="xxs" @tagName="h3">defaultExpandedRowIds=(array "src")</EuiTitle>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Some rows expanded"
  @columns={{this.columns}}
  @rowTree={{hash rows=this.files defaultExpandedRowIds=(array "src")}}
  @toolbarVisibility={{false}}
  @height={{200}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

export default class DefaultExpandedDemo extends Component {
  columns = [
    { id: 'name', displayAsText: 'Name' },
    { id: 'size', displayAsText: 'Size (KB)', schema: 'numeric' }
  ];

  files = [
    {
      id: 'src',
      name: 'src',
      size: 96,
      children: [
        {
          id: 'src/components',
          name: 'components',
          size: 64,
          children: [{ id: 'src/components/grid.gts', name: 'grid.gts', size: 64 }]
        },
        { id: 'src/index.ts', name: 'index.ts', size: 32 }
      ]
    },
    { id: 'README.md', name: 'README.md', size: 8 }
  ];
}
```
