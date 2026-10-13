---
order: 2
---

# Multi-level groups with `getValue`

<EuiText>

The data is column-oriented arrays, so the grid gets `@rowCount` and a
`getValue(rowIndex, columnId)`. "Year" is computed from a date. Pick the
grouping with the buttons.

</EuiText>

```hbs template
<EuiButtonGroup
  @legend="Group by"
  @options={{this.groupOptions}}
  @idSelected={{this.groupById}}
  @onChange={{this.setGroupBy}}
  @buttonSize="compressed"
/>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Multi-level groups"
  @columns={{this.columns}}
  @rowCount={{this.data.product.length}}
  @grouping={{hash groupBy=this.groupBy getValue=this.getValue defaultExpandedGroupIds="all"}}
  @height={{360}}
>
  <:cell as |cell|>{{this.display cell.rowIndex cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const GROUPINGS = {
  none: [],
  category: ['category'],
  categoryYear: ['category', 'year'],
  yearCategory: ['year', 'category']
};

export default class MultiLevelDemo extends Component {
  @tracked groupById = 'categoryYear';

  groupOptions = [
    { id: 'none', label: 'None' },
    { id: 'category', label: 'Category' },
    { id: 'categoryYear', label: 'Category › Year' },
    { id: 'yearCategory', label: 'Year › Category' }
  ];

  columns = [
    { id: 'product', displayAsText: 'Product', initialWidth: 240 },
    { id: 'category', displayAsText: 'Category' },
    { id: 'year', displayAsText: 'Year' },
    { id: 'units', displayAsText: 'Units', schema: 'numeric' }
  ];

  // column-oriented data: one array per field
  data = {
    product: ['Desk', 'Chair', 'Lamp', 'Monitor', 'Keyboard', 'Sofa', 'Mouse', 'Shelf'],
    category: ['Furniture', 'Furniture', 'Lighting', 'Electronics', 'Electronics', 'Furniture', 'Electronics', 'Furniture'],
    soldOn: ['2023-03-01', '2024-01-12', '2023-07-30', '2024-05-02', '2023-11-11', '2024-02-20', '2024-08-08', '2023-09-09'],
    units: [12, 30, 8, 14, 40, 3, 55, 9]
  };

  get groupBy() {
    return GROUPINGS[this.groupById];
  }

  getValue = (rowIndex, columnId) =>
    columnId === 'year'
      ? Number(this.data.soldOn[rowIndex].slice(0, 4))
      : this.data[columnId][rowIndex];

  display = (rowIndex, columnId) => this.getValue(rowIndex, columnId);

  @action setGroupBy(id) {
    this.groupById = id;
  }
}
```
