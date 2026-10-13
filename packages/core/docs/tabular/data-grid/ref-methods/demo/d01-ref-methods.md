---
order: 1
---

# Imperative API

<EuiText>

The buttons drive the grid through the API passed to `@registerApi`.
Row numbers are rows of the data: the grid is sorted by "Value" here, and
paginated, so it finds the right page and position.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="s" @wrap={{true}} @responsive={{false}}>
  <EuiButton @size="s" {{on "click" this.focusCell}}>Focus row 42, column 2</EuiButton>
  <EuiButton @size="s" {{on "click" this.openPopover}}>Open the popover of row 7</EuiButton>
  <EuiButton @size="s" {{on "click" this.scrollToEnd}}>Scroll to the page's last row</EuiButton>
  <EuiButton @size="s" {{on "click" this.fullScreen}}>Fullscreen</EuiButton>
</EuiFlexGroup>
<EuiSpacer @size="m" />
<EuiDataGrid
  aria-label="Imperative API demo"
  @columns={{this.columns}}
  @rowCount={{100}}
  @height={{320}}
  @sorting={{this.sorting}}
  @inMemory={{this.inMemory}}
  @pagination={{this.pagination}}
  @registerApi={{this.registerApi}}
>
  <:cell as |cell|>
    {{#if (eq cell.columnId "row")}}Row {{cell.rowIndex}}{{else}}{{this.valueOf cell.rowIndex}}{{/if}}
  </:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ImperativeApiDemo extends Component {
  api = null;
  @tracked pageIndex = 0;
  @tracked pageSize = 25;
  @tracked sortingColumns = [{ id: 'value', direction: 'desc' }];

  columns = [
    { id: 'row', displayAsText: 'Row' },
    { id: 'value', displayAsText: 'Value', schema: 'numeric' }
  ];

  inMemory = { level: 'sorting' };

  get sorting() {
    return {
      columns: this.sortingColumns,
      onSort: (columns) => (this.sortingColumns = columns)
    };
  }

  get pagination() {
    return {
      pageIndex: this.pageIndex,
      pageSize: this.pageSize,
      pageSizeOptions: [25, 50, 100],
      onChangePage: (pageIndex) => (this.pageIndex = pageIndex),
      onChangeItemsPerPage: (pageSize) => {
        this.pageSize = pageSize;
        this.pageIndex = 0;
      }
    };
  }

  valueOf = (rowIndex) => String((rowIndex * 7919) % 1000);

  registerApi = (api) => {
    this.api = api;
  };

  @action focusCell() {
    this.api.setFocusedCell({ rowIndex: 42, colIndex: 1 });
  }

  @action openPopover() {
    this.api.openCellPopover({ rowIndex: 7, colIndex: 1 });
  }

  @action scrollToEnd() {
    this.api.scrollToItem({ rowIndex: this.pageSize - 1, align: 'end' });
  }

  @action fullScreen() {
    this.api.setIsFullScreen(true);
  }
}
```
