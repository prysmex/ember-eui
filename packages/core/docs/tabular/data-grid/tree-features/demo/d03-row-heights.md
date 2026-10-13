---
order: 3
---

# Auto row heights

<EuiText>

`defaultHeight: 'auto'` measures every row. Expand and collapse: long
descriptions keep their height wherever their row moves.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Row heights"
  @columns={{this.columns}}
  @rowTree={{hash rows=this.topics defaultExpandedRowIds=(array "grid")}}
  @rowHeightsOptions={{hash defaultHeight="auto"}}
  @height={{380}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

export default class RowHeightsDemo extends Component {
  columns = [
    { id: 'title', displayAsText: 'Topic', initialWidth: 220 },
    { id: 'summary', displayAsText: 'Summary' }
  ];

  topics = [
    {
      id: 'grid',
      title: 'Data grid',
      summary: 'Virtualized rows and columns, keyboard navigation and cell popovers.',
      children: [
        {
          id: 'tree',
          title: 'Nested rows',
          summary:
            'Rows nest through their children arrays or point at their parent with parentId. The grid renders the visible rows only, indents them by level and adds a toggle to every row that has children.'
        },
        { id: 'groups', title: 'Grouping', summary: 'Group rows by column values.' }
      ]
    },
    {
      id: 'table',
      title: 'Basic table',
      summary:
        'A simpler table for small data sets, with sorting, pagination and selection built in, and no virtualization or keyboard grid navigation.',
      children: [{ id: 'memory', title: 'In-memory table', summary: 'Search, sort and page in the browser.' }]
    }
  ];
}
```
