---
order: 2
---

# Flat rows with `parentId` and controlled expansion

<EuiText>

Flat rows point at their parent's `id`; `@rowIndex` stays the row's index in
the array. Here the expanded ids are controlled, so the buttons can expand
or collapse everything.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="s" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" {{on "click" this.expandAll}}>Expand all</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" {{on "click" this.collapseAll}}>Collapse all</EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Flat rows demo"
  @columns={{this.columns}}
  @rowTree={{hash
    rows=this.people
    expandedRowIds=this.expandedRowIds
    onExpandedChange=this.onExpandedChange
  }}
  @height={{320}}
>
  <:cell as |cell|>{{get (get this.people cell.rowIndex) cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class FlatParentIdsDemo extends Component {
  @tracked expandedRowIds = ['ceo'];

  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 240 },
    { id: 'title', displayAsText: 'Title' }
  ];

  people = [
    { id: 'ceo', name: 'Ada', title: 'CEO' },
    { id: 'cto', parentId: 'ceo', name: 'Grace', title: 'CTO' },
    { id: 'eng1', parentId: 'cto', name: 'Linus', title: 'Engineer' },
    { id: 'eng2', parentId: 'cto', name: 'Margaret', title: 'Engineer' },
    { id: 'cfo', parentId: 'ceo', name: 'Katherine', title: 'CFO' },
    { id: 'acc', parentId: 'cfo', name: 'Alan', title: 'Accountant' }
  ];

  @action onExpandedChange(ids) {
    this.expandedRowIds = ids;
  }

  @action expandAll() {
    const parents = new Set(this.people.map((person) => person.parentId).filter(Boolean));
    this.expandedRowIds = [...parents];
  }

  @action collapseAll() {
    this.expandedRowIds = [];
  }
}
```
