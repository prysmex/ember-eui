---
order: 1
---

# 100,000 rows and 30 columns

<EuiText>

Values are computed when a cell renders, so nothing is precomputed for
rows that are never shown.

</EuiText>

```hbs template
<EuiText @size="s">
  <p>Rendered rows {{this.items.overscanRowStartIndex}}–{{this.items.overscanRowStopIndex}}, columns {{this.items.overscanColumnStartIndex}}–{{this.items.overscanColumnStopIndex}}</p>
</EuiText>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Virtualization demo"
  @columns={{this.columns}}
  @rowCount={{100000}}
  @height={{400}}
  @virtualizationOptions={{this.virtualizationOptions}}
>
  <:cell as |cell|>{{cell.columnId}}-{{cell.rowIndex}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class VirtualizationDemo extends Component {
  @tracked items = {};

  columns = Array.from({ length: 30 }, (_, i) => ({
    id: `c${i}`,
    displayAsText: `Column ${i + 1}`,
    initialWidth: 120
  }));

  virtualizationOptions = {
    overscanRowCount: 3,
    onItemsRendered: (items) => {
      this.items = items;
    }
  };
}
```
