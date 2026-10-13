---
order: 1
---

# In-memory sorting and schema detection

<EuiText>

Open a column's actions (the "…" button, or Enter on a focused header) or
the "Sort fields" popover. Amounts sort numerically, dates chronologically,
and the "Data" column holds JSON.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="In-memory sorting demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @inMemory={{hash level="sorting"}}
  @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
  @height={{360}}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const ACCOUNTS = ['Initech', 'Hooli', 'Globex', 'Umbrella', 'Vandelay', 'Acme', 'Soylent'];

export default class InMemorySortingDemo extends Component {
  @tracked sortingColumns = [{ id: 'amount', direction: 'desc' }];

  columns = [
    { id: 'account', displayAsText: 'Account' },
    { id: 'amount', displayAsText: 'Amount' },
    { id: 'date', displayAsText: 'Date' },
    { id: 'active', displayAsText: 'Active' },
    { id: 'data', displayAsText: 'Data' }
  ];

  rows = Array.from({ length: 40 }, (_, i) => ({
    account: ACCOUNTS[i % ACCOUNTS.length],
    amount: `$${((i * 7919) % 5000) + 10}.00`,
    date: `2026-${String((i % 12) + 1).padStart(2, '0')}-${String((i % 27) + 1).padStart(2, '0')}`,
    active: i % 3 === 0 ? 'true' : 'false',
    data: JSON.stringify({ id: i, tags: i % 2 ? ['a'] : ['b', 'c'] })
  }));

  @action onSort(columns) {
    this.sortingColumns = columns;
  }
}
```
