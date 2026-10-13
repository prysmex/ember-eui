---
order: 1
---

# Group by one column

<EuiText>

Rows grouped by "Department". The groups start collapsed: open one with
its toggle, ArrowRight or Space.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Group by department"
  @columns={{this.columns}}
  @grouping={{hash groupBy=(array "department") rows=this.people}}
  @height={{320}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

export default class OneLevelDemo extends Component {
  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 240 },
    { id: 'department', displayAsText: 'Department' },
    { id: 'role', displayAsText: 'Role' }
  ];

  people = [
    { name: 'Ada', department: 'Engineering', role: 'Lead' },
    { name: 'Grace', department: 'Engineering', role: 'Engineer' },
    { name: 'Katherine', department: 'Finance', role: 'Analyst' },
    { name: 'Linus', department: 'Engineering', role: 'Engineer' },
    { name: 'Margaret', department: 'Design', role: 'Designer' },
    { name: 'Alan', department: 'Finance', role: 'Controller' },
    { name: 'Hedy', department: 'Design', role: 'Lead' }
  ];
}
```
