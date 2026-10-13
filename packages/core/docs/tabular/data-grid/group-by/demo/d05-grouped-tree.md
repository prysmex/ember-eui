---
order: 5
---

# Grouping a tree

<EuiText>

Projects with subtasks (`@rowTree`), grouped by team (`@grouping`): the
root rows are grouped and keep their subtasks.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Grouped tree"
  @columns={{this.columns}}
  @rowTree={{hash rows=this.projects defaultExpandedRowIds="all"}}
  @grouping={{hash groupBy=(array "team") defaultExpandedGroupIds="all"}}
  @height={{340}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

export default class GroupedTreeDemo extends Component {
  columns = [
    { id: 'title', displayAsText: 'Project', initialWidth: 280 },
    { id: 'team', displayAsText: 'Team' },
    { id: 'points', displayAsText: 'Points', schema: 'numeric' }
  ];

  projects = [
    {
      id: 'p1',
      title: 'Checkout redesign',
      team: 'Web',
      points: 13,
      children: [
        { id: 'p1a', title: 'Cart page', team: 'Web', points: 5 },
        { id: 'p1b', title: 'Payment form', team: 'Web', points: 8 }
      ]
    },
    {
      id: 'p2',
      title: 'Search API',
      team: 'Platform',
      points: 21,
      children: [{ id: 'p2a', title: 'Indexing', team: 'Platform', points: 21 }]
    },
    { id: 'p3', title: 'Dark mode', team: 'Web', points: 3 }
  ];
}
```
