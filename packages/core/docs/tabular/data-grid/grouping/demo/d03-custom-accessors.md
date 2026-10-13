---
order: 3
---

# Custom accessors

<EuiText>

These rows keep their children in `subtasks` and their id in `key`, so the
demo passes `getChildren` and `getRowId`. The flat form works the same with
`getParentId`.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Custom accessors"
  @columns={{this.columns}}
  @rowTree={{hash
    rows=this.projects
    getChildren=this.getChildren
    getRowId=this.getRowId
    defaultExpandedRowIds=(array "web")
  }}
  @height={{280}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

export default class CustomAccessorsDemo extends Component {
  columns = [
    { id: 'label', displayAsText: 'Project', initialWidth: 260 },
    { id: 'points', displayAsText: 'Points', schema: 'numeric' }
  ];

  projects = [
    {
      key: 'web',
      label: 'Website',
      points: 13,
      subtasks: [
        { key: 'web-nav', label: 'Navigation', points: 5 },
        { key: 'web-search', label: 'Search', points: 8, subtasks: [{ key: 'web-search-ui', label: 'Search UI', points: 3 }] }
      ]
    },
    { key: 'api', label: 'API', points: 21, subtasks: [{ key: 'api-auth', label: 'Auth', points: 21 }] }
  ];

  getChildren = (project) => project.subtasks;
  getRowId = (project) => project.key;
}
```
