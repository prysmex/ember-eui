---
order: 1
---

# Paginated grid

<EuiText>

`rowIndex` stays the index into your data on every page.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Pagination demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @pagination={{hash
    pageIndex=this.pageIndex
    pageSize=this.pageSize
    pageSizeOptions=(array 10 25 50)
    onChangePage=this.onChangePage
    onChangeItemsPerPage=this.onChangeItemsPerPage
  }}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PaginationDemo extends Component {
  @tracked pageIndex = 0;
  @tracked pageSize = 10;

  columns = [
    { id: 'id', displayAsText: 'Order', schema: 'numeric', initialWidth: 100 },
    { id: 'customer', displayAsText: 'Customer' },
    { id: 'total', displayAsText: 'Total', schema: 'currency' }
  ];

  rows = Array.from({ length: 137 }, (_, i) => ({
    id: String(1000 + i),
    customer: ['Ada', 'Grace', 'Alan', 'Linus', 'Ken'][i % 5],
    total: `$${(((i + 3) * 1373) % 900) + 20}.00`
  }));

  @action onChangePage(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action onChangeItemsPerPage(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }
}
```
