---
order: 2
---

# Pagination over visible rows

<EuiText>

Five rows per page. "Expand all" adds pages. Go to the last page and
"Collapse all": the grid moves `pageIndex` back to the last page that
still exists.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="s" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" {{on "click" this.expandAll}}>Expand all</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" {{on "click" this.collapseAll}}>Collapse all</EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Pagination"
  @columns={{this.columns}}
  @rowTree={{this.folders}}
  @registerApi={{this.registerApi}}
  @pagination={{hash
    pageIndex=this.pageIndex
    pageSize=this.pageSize
    pageSizeOptions=(array 5 10)
    onChangePage=this.onChangePage
    onChangeItemsPerPage=this.onChangeItemsPerPage
  }}
  @toolbarVisibility={{false}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PaginationDemo extends Component {
  @tracked pageIndex = 0;
  @tracked pageSize = 5;
  api = null;

  columns = [
    { id: 'name', displayAsText: 'Name' },
    { id: 'items', displayAsText: 'Items', schema: 'numeric' }
  ];

  folders = ['Inbox', 'Projects', 'Archive', 'Receipts', 'Travel', 'Photos'].map((name) => ({
    id: name,
    name,
    items: 3,
    children: [1, 2, 3].map((n) => ({ id: `${name}-${n}`, name: `${name} item ${n}`, items: 1 }))
  }));

  registerApi = (api) => {
    this.api = api;
  };

  @action expandAll() {
    this.api?.expandAll();
  }

  @action collapseAll() {
    this.api?.collapseAll();
  }

  @action onChangePage(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action onChangeItemsPerPage(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }
}
```
