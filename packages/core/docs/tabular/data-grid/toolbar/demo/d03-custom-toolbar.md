---
order: 3
---

# Custom toolbar

<EuiText>

The `<:customToolbar>` block places the grid's controls in its own layout:
a title on the left, a custom button and the grid's controls on the right.
The left controls hide when the grid is too narrow, like the default
toolbar.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Custom toolbar demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @sorting={{this.sorting}}
  @inMemory={{this.inMemory}}
  @height={{300}}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
  <:customToolbar as |toolbar|>
    <EuiFlexGroup
      @responsive={{false}}
      @gutterSize="s"
      @justifyContent="spaceBetween"
      @alignItems="center"
      class="euiDataGrid__controls"
    >
      <EuiFlexItem @grow={{false}}>
        <EuiTitle @size="xxs"><h3>Servers</h3></EuiTitle>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiFlexGroup @responsive={{false}} @gutterSize="xs" @alignItems="center">
          {{#if toolbar.hasRoomForGridControls}}
            <EuiFlexItem @grow={{false}}><toolbar.columnControl /></EuiFlexItem>
            {{#if toolbar.columnSortingControl}}
              <EuiFlexItem @grow={{false}}><toolbar.columnSortingControl /></EuiFlexItem>
            {{/if}}
          {{/if}}
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @size="xs" @iconType="download">Export</EuiButtonEmpty>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}><toolbar.keyboardShortcutsControl /></EuiFlexItem>
          <EuiFlexItem @grow={{false}}><toolbar.displayControl /></EuiFlexItem>
          <EuiFlexItem @grow={{false}}><toolbar.fullScreenControl /></EuiFlexItem>
        </EuiFlexGroup>
      </EuiFlexItem>
    </EuiFlexGroup>
  </:customToolbar>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class CustomToolbarDemo extends Component {
  @tracked sortingColumns = [];

  columns = [
    { id: 'host', displayAsText: 'Host' },
    { id: 'region', displayAsText: 'Region' },
    { id: 'load', displayAsText: 'Load', schema: 'numeric' }
  ];

  inMemory = { level: 'sorting' };

  rows = Array.from({ length: 12 }, (_, i) => ({
    host: `api-${String(i + 1).padStart(2, '0')}`,
    region: ['eu-west', 'us-east', 'ap-south'][i % 3],
    load: String((i * 29) % 100)
  }));

  get sorting() {
    return {
      columns: this.sortingColumns,
      onSort: (columns) => (this.sortingColumns = columns)
    };
  }
}
```
