---
order: 1
---

# Sorting siblings and groups

<EuiText>

Grouped by "Team" with in-memory sorting. Sort by "Points" or "Name" from
the toolbar's "Sort fields" or a header's actions: the rows are sorted
inside each group, and the subtasks inside each project. Sort by "Team" to
reverse the group order.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Sorting"
  @columns={{this.columns}}
  @rowTree={{hash rows=this.projects defaultExpandedRowIds="all"}}
  @grouping={{hash groupBy=(array "team") defaultExpandedGroupIds="all"}}
  @inMemory={{hash level="sorting"}}
  @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
  @height={{380}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SortingDemo extends Component {
  @tracked sortingColumns = [{ id: 'points', direction: 'desc' }];

  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 260 },
    { id: 'team', displayAsText: 'Team' },
    { id: 'points', displayAsText: 'Points', schema: 'numeric' }
  ];

  projects = [
    {
      id: 'checkout',
      name: 'Checkout',
      team: 'Web',
      points: 13,
      children: [
        { id: 'cart', name: 'Cart page', team: 'Web', points: 5 },
        { id: 'payment', name: 'Payment form', team: 'Web', points: 8 }
      ]
    },
    { id: 'dark', name: 'Dark mode', team: 'Web', points: 3 },
    {
      id: 'search',
      name: 'Search API',
      team: 'Platform',
      points: 21,
      children: [
        { id: 'indexing', name: 'Indexing', team: 'Platform', points: 13 },
        { id: 'ranking', name: 'Ranking', team: 'Platform', points: 8 }
      ]
    },
    { id: 'billing', name: 'Billing jobs', team: 'Platform', points: 5 }
  ];

  @action onSort(columns) {
    this.sortingColumns = columns;
  }
}
```
