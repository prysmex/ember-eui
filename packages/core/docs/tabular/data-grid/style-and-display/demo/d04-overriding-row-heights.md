---
order: 4
---

# Overriding specific row heights

<EuiText>

You can override the default height of a specific row by passing a
`rowHeights` object associating the row's index with a specific height
configuration.

<EuiCallOut @title="Disabling the row height toolbar control" @color="warning" @size="s">
  <p>
    Individual row heights will be overridden by the toolbar display
    controls. If you do not want users to be able to override specific row
    heights, set <code>toolbarVisibility.showDisplaySelector.allowRowHeight</code>
    to <code>false</code>.
  </p>
</EuiCallOut>

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Row height options with fixed heights and overrides"
  @columns={{this.columns}}
  @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
  @rowCount={{this.rawData.length}}
  @rowHeightsOptions={{this.rowHeightsOptions}}
>
  <:cell as |cell|>
    {{#if (eq cell.columnId "productImage")}}
      <img src={{get (get this.rawData cell.rowIndex) "productImage"}} alt="Mock product image" />
    {{else}}
      {{get (get this.rawData cell.rowIndex) cell.columnId}}
    {{/if}}
  </:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class RowHeightOverridesDemo extends Component {
  rawData = [
    'Ergonomic Granite Chair',
    'Handcrafted Steel Keyboard',
    'Sleek Cotton Hat',
    'Rustic Bronze Lamp',
    'Licensed Wooden Table'
  ].map((productName, i) => ({
    index: i,
    productName,
    productImage: `https://picsum.photos/id/${i}/300/${i === 2 ? 200 : 100}`
  }));

  columns = [
    { id: 'index', displayAsText: 'Index', isExpandable: false, initialWidth: 52 },
    { id: 'productName', displayAsText: 'Product name', isExpandable: false },
    { id: 'productImage', displayAsText: 'Image' }
  ];

  rowHeightsOptions = {
    defaultHeight: 40,
    rowHeights: { 2: 212 }
  };

  @tracked visibleColumns = this.columns.map(({ id }) => id);

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }
}
```
