---
order: 6
---

# Table pagination

<EuiText>

You can use **EuiTablePagination** to create a combination "Rows per page" and pagination set, commonly used with tables. If you pass `0` in as one of the `@itemsPerPageOptions`, it will create a "Show all" option and hide the pagination.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { array } from '@ember/helper';
import { EuiTablePagination } from '@ember-eui/core/components';

const totalEntries = 1250;

export default class DemoComponent extends Component {
  @tracked activePage = 0;
  @tracked rowSize = 50;
  @tracked pageCount = Math.ceil(totalEntries / 50);

  @action
  goToPage(pageNumber) {
    this.activePage = pageNumber;
  }

  @action
  changeItemsPerPage(pageSize) {
    this.pageCount = Math.ceil(totalEntries / pageSize);
    this.rowSize = pageSize;
    this.activePage = 0;
  }

  <template>
    <EuiTablePagination
      aria-label="Table pagination example"
      @pageCount={{this.pageCount}}
      @activePage={{this.activePage}}
      @onChangePage={{this.goToPage}}
      @itemsPerPage={{this.rowSize}}
      @onChangeItemsPerPage={{this.changeItemsPerPage}}
      @itemsPerPageOptions={{array 10 20 0}}
    />
  </template>
}
```
