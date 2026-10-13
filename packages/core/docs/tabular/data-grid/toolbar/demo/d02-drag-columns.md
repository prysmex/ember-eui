---
order: 2
---

# Drag and drop header columns

<EuiText>

Drag a column header to reorder the columns, or focus a header (click it,
or move to it with the arrow keys), press Space, move it with the arrow
keys and press Space again.

</EuiText>

```hbs template
<EuiText @size="s"><p>Order: {{this.order}}</p></EuiText>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Draggable columns demo"
  @columns={{this.columns}}
  @columnVisibility={{hash
    visibleColumns=this.visibleColumns
    setVisibleColumns=this.setVisibleColumns
    canDragAndDropColumns=true
  }}
  @rowCount={{this.rows.length}}
  @height={{260}}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DragColumnsDemo extends Component {
  columns = [
    { id: 'name', displayAsText: 'Name' },
    { id: 'city', displayAsText: 'City' },
    { id: 'country', displayAsText: 'Country' },
    { id: 'population', displayAsText: 'Population', schema: 'numeric' }
  ];

  @tracked visibleColumns = ['name', 'city', 'country', 'population'];

  rows = [
    ['Tokyo', 'Japan', '37400068'],
    ['Delhi', 'India', '28514000'],
    ['Shanghai', 'China', '25582000'],
    ['São Paulo', 'Brazil', '21650000'],
    ['Mexico City', 'Mexico', '21581000'],
    ['Cairo', 'Egypt', '20076000']
  ].map(([city, country, population], i) => ({ name: `#${i + 1}`, city, country, population }));

  get order() {
    return this.visibleColumns.join(', ');
  }

  @action setVisibleColumns(columns) {
    this.visibleColumns = columns;
  }
}
```
