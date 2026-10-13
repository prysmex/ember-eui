---
order: 2
---

# Row heights

<EuiText>

`@rowHeightsOptions.defaultHeight` is a pixel height, `{ lineCount }`
(text is clamped to that many lines), `{ height }` or `'auto'` (rows grow
to fit their tallest cell). `rowHeights` overrides single rows by data
index.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Row heights demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @rowHeightsOptions={{this.rowHeightsOptions}}
  @height={{320}}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';

const TEXT =
  'Data grids render large data sets with virtualization, so only the visible rows and columns are in the DOM. Long text wraps or is clamped depending on the row height.';

export default class RowHeightsDemo extends Component {
  columns = [
    { id: 'title', displayAsText: 'Title', initialWidth: 160 },
    { id: 'body', displayAsText: 'Body' }
  ];

  rowHeightsOptions = { defaultHeight: { lineCount: 2 }, rowHeights: { 1: 'auto' } };

  rows = Array.from({ length: 30 }, (_, i) => ({
    title: `Note ${i + 1}`,
    body: i === 1 ? `${TEXT} ${TEXT}` : TEXT
  }));
}
```
