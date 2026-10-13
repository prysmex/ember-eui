---
order: 1
---

# Nested rows from `children`

<EuiText>

Rows nest through their `children` arrays: `@rowTree={{this.files}}` is all
it takes. Click a toggle, or focus a "Name" cell and press Space.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Nested rows demo"
  @columns={{this.columns}}
  @rowTree={{this.files}}
  @height={{360}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

export default class NestedRowsDemo extends Component {
  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 260 },
    { id: 'type', displayAsText: 'Type' },
    { id: 'size', displayAsText: 'Size (KB)', schema: 'numeric' }
  ];

  files = [
    {
      name: 'src',
      type: 'folder',
      size: 96,
      children: [
        {
          name: 'components',
          type: 'folder',
          size: 64,
          children: [
            { name: 'eui-data-grid.gts', type: 'file', size: 40 },
            { name: 'eui-button.gts', type: 'file', size: 24 }
          ]
        },
        {
          name: 'utils',
          type: 'folder',
          size: 32,
          children: [{ name: 'row-tree.ts', type: 'file', size: 32 }]
        }
      ]
    },
    {
      name: 'docs',
      type: 'folder',
      size: 12,
      children: [{ name: 'grouping.md', type: 'file', size: 12 }]
    },
    { name: 'package.json', type: 'file', size: 4 },
    { name: 'README.md', type: 'file', size: 8 }
  ];
}
```
