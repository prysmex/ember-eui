---
order: 2
---

# Flat rows with `parentId`

<EuiText>

No row has `children`, so the grid reads each row's `parentId` (or
`parent`). `@rowIndex` is the row's index in the array, so this demo
renders cells the classic way, with `rowIndex`. The rows are unsorted: a
child may come before its parent.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { get, hash } from '@ember/helper';
import { EuiDataGrid } from '@ember-eui/core/components';

export default class FlatRowsDemo extends Component {
  columns = [
    { id: 'title', displayAsText: 'Task', initialWidth: 280 },
    { id: 'owner', displayAsText: 'Owner' },
    { id: 'status', displayAsText: 'Status' }
  ];

  tasks = [
    { id: 't2', parentId: 't1', title: 'Design the API', owner: 'Ada', status: 'done' },
    { id: 't1', title: 'Row grouping', owner: 'Ada', status: 'in progress' },
    { id: 't3', parentId: 't1', title: 'Write the docs', owner: 'Grace', status: 'in progress' },
    { id: 't4', parent: 't3', title: 'Recipes page', owner: 'Grace', status: 'todo' },
    { id: 't5', title: 'Release', owner: 'Linus', status: 'todo' },
    { id: 't6', parentId: 't5', title: 'Changelog', owner: 'Linus', status: 'todo' }
  ];

  <template>
    <EuiDataGrid
      aria-label="Flat rows"
      @columns={{this.columns}}
      @rowTree={{hash rows=this.tasks defaultExpandedRowIds="all"}}
      @height={{300}}
    >
      <:cell as |cell|>{{get (get this.tasks cell.rowIndex) cell.columnId}}</:cell>
    </EuiDataGrid>
  </template>
}
```
