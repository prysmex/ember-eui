---
order: 1
---

# Toolbar controls and column visibility

<EuiText>

Columns are controlled here: hiding, showing or reordering them updates
`visibleColumns`. The "Filters" button is an additional control.

</EuiText>

```hbs template
<EuiText @size="s"><p>Visible: {{this.visibleText}}</p></EuiText>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Toolbar demo"
  @columns={{this.columns}}
  @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
  @rowCount={{this.rows.length}}
  @height={{300}}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
  <:leftControlsAppend>
    <EuiDataGridToolbarControl @iconType="filter" @badgeContent={{2}}>
      Filters
    </EuiDataGridToolbarControl>
  </:leftControlsAppend>
  <:rightControls>
    <EuiButtonIcon @iconType="refresh" @size="xs" @color="text" aria-label="Refresh" />
  </:rightControls>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ToolbarDemo extends Component {
  columns = [
    { id: 'host', displayAsText: 'Host' },
    { id: 'status', displayAsText: 'Status' },
    { id: 'cpu', displayAsText: 'CPU %', schema: 'numeric' },
    { id: 'memory', displayAsText: 'Memory %', schema: 'numeric' },
    { id: 'zone', displayAsText: 'Zone' }
  ];

  @tracked visibleColumns = ['host', 'status', 'cpu', 'memory'];

  rows = Array.from({ length: 20 }, (_, i) => ({
    host: `web-${String(i + 1).padStart(2, '0')}`,
    status: i % 5 === 0 ? 'degraded' : 'healthy',
    cpu: String((i * 37) % 100),
    memory: String((i * 53) % 100),
    zone: ['a', 'b', 'c'][i % 3]
  }));

  get visibleText() {
    return this.visibleColumns.join(', ');
  }

  @action setVisibleColumns(columns) {
    this.visibleColumns = columns;
  }
}
```
