---
order: 4
---

# Expand all, collapse all and the imperative API

<EuiText>

The buttons call the API that `@registerApi` hands over. "Focus keys.ts"
calls `setFocusedCell` with a data row index two levels deep: the grid
expands its ancestors first.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="s" @responsive={{false}} @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" {{on "click" this.expandAll}}>Expand all</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" {{on "click" this.collapseAll}}>Collapse all</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" {{on "click" this.expandSrc}}>Expand "src"</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" {{on "click" this.focusKeys}}>Focus keys.ts</EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Imperative API"
  @columns={{this.columns}}
  @rowTree={{this.files}}
  @registerApi={{this.registerApi}}
  @toolbarVisibility={{false}}
  @height={{260}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class ImperativeApiDemo extends Component {
  api = null;

  columns = [
    { id: 'name', displayAsText: 'Name' },
    { id: 'size', displayAsText: 'Size (KB)', schema: 'numeric' }
  ];

  // pre-order data row indexes: src 0, app.ts 1, utils 2, keys.ts 3, README.md 4
  files = [
    {
      id: 'src',
      name: 'src',
      size: 30,
      children: [
        { id: 'app', name: 'app.ts', size: 20 },
        { id: 'utils', name: 'utils', size: 10, children: [{ id: 'keys', name: 'keys.ts', size: 10 }] }
      ]
    },
    { id: 'readme', name: 'README.md', size: 5 }
  ];

  registerApi = (api) => {
    this.api = api;
  };

  @action expandAll() {
    this.api?.expandAll();
  }

  @action collapseAll() {
    this.api?.collapseAll();
  }

  @action expandSrc() {
    this.api?.expandRow('src');
  }

  @action focusKeys() {
    this.api?.setFocusedCell({ rowIndex: 3, colIndex: 0 });
  }
}
```
