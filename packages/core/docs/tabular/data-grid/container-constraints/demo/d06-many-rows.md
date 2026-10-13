---
order: 6
---

# 100,000 rows and 30 columns (Ember EUI example)

<EuiText>

An extra example: a grid with 100,000 rows and 30 columns. Values are
computed when a cell renders, so nothing is precomputed for rows that are
never shown. `virtualizationOptions.onItemsRendered` is called after each
render with the rendered (`overscan…`) and visible (`visible…`) row and
column ranges; `overscanRowCount` widens the rendered range by 3 rows here.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiDataGrid, EuiSpacer, EuiText } from '@ember-eui/core/components';

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

  <template>
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
  </template>
}
```
