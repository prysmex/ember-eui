---
order: 2
---

# Enhancements only in-memory

<EuiText>

With `@inMemory={{hash level="enhancements"}}` the grid will now
autodetect schemas based on the content it has available on the currently
viewed page. Notice that the field list under Sort fields has detected the
type of data each column contains.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiDataGrid, EuiLink } from '@ember-eui/core/components';

const LAST = ['Schmidt', 'Okafor', 'Lindqvist', 'Moreau', 'Tanaka', 'Novak', 'Ferreira', 'Kowalski', 'Haddad'];
const FIRST = ['Amara', 'Bruno', 'Chloe', 'Dmitri', 'Elena', 'Felix', 'Grace', 'Hiro', 'Ines', 'Jonas', 'Keira'];
const SUFFIXES = ['Jr.', 'Sr.', 'II', 'III', 'MD', 'PhD', 'DVM'];
const CITIES = ['Lake Ottoport', 'North Kaleigh', 'East Damian', 'Port Ellis', 'New Brayden', 'West Coraline'];
const COUNTRIES = ['Portugal', 'Norway', 'Japan', 'Peru', 'Kenya', 'Canada', 'Iceland', 'Chile'];

const columns = [
  { id: 'name' },
  { id: 'email' },
  { id: 'location' },
  { id: 'account' },
  { id: 'date' },
  { id: 'amount', schema: 'currency' },
  { id: 'phone' },
  { id: 'version' }
];

const rawData = Array.from({ length: 99 }, (_, i) => ({
  name: `${LAST[i % LAST.length]}, ${FIRST[(i * 7) % FIRST.length]} ${SUFFIXES[i % SUFFIXES.length]}`,
  email: `${FIRST[(i * 7) % FIRST.length]}.${LAST[i % LAST.length]}${i}@example.com`.toLowerCase(),
  city: CITIES[(i * 5) % CITIES.length],
  country: COUNTRIES[(i * 3) % COUNTRIES.length],
  date: `${new Date(Date.UTC(2024, (i * 5) % 12, 1 + ((i * 11) % 28), (i * 7) % 24))}`,
  account: String(10000000 + (((i + 1) * 7919 * 104729) % 89999999)),
  amount: ((((i + 1) * 6151) % 99900) / 100 + 1).toFixed(2),
  phone: `(${200 + ((i * 37) % 700)}) ${100 + ((i * 53) % 900)}-${1000 + ((i * 97) % 9000)}`,
  version: `${i % 4}.${(i * 3) % 10}.${(i * 7) % 20}`
}));

export default class InMemoryDemo extends Component {
  columns = columns;
  rowCount = rawData.length;

  // Pagination
  @tracked pageIndex = 0;
  @tracked pageSize = 10;

  // Sorting
  @tracked sortingColumns = [];

  // Column visibility
  @tracked visibleColumns = columns.map(({ id }) => id);

  // Sort data
  get sortedData() {
    return [...rawData].sort((a, b) => {
      for (const column of this.sortingColumns) {
        const aValue = a[column.id];
        const bValue = b[column.id];
        if (aValue < bValue) return column.direction === 'asc' ? -1 : 1;
        if (aValue > bValue) return column.direction === 'asc' ? 1 : -1;
      }
      return 0;
    });
  }

  // Pagination: inMemory doesn't paginate, so the data is pruned to the page
  get data() {
    const rowStart = this.pageIndex * this.pageSize;
    const rowEnd = Math.min(rowStart + this.pageSize, this.sortedData.length);
    return this.sortedData.slice(rowStart, rowEnd);
  }

  // The row index must be adjusted as `data` has already been pruned to the page size
  rowAt = (rowIndex) => this.data[rowIndex - this.pageIndex * this.pageSize];

  @action onChangeItemsPerPage(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }

  @action onChangePage(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action onSort(sortingColumns) {
    this.sortingColumns = sortingColumns;
  }

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  <template>
    <EuiDataGrid
      aria-label="Data grid enhanced in-memory demo"
      @columns={{this.columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{this.rowCount}}
      @inMemory={{hash level="enhancements"}}
      @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
      @pagination={{hash
        pageIndex=this.pageIndex
        pageSize=this.pageSize
        onChangeItemsPerPage=this.onChangeItemsPerPage
        onChangePage=this.onChangePage
      }}
    >
      <:cell as |cell|>
        {{#let (this.rowAt cell.rowIndex) as |row|}}
          {{#if row}}
            {{#if (eq cell.columnId "email")}}
              <EuiLink @href="#">{{row.email}}</EuiLink>
            {{else if (eq cell.columnId "location")}}
              {{row.city}},
              <EuiLink @href="https://google.com">{{row.country}}</EuiLink>
            {{else}}
              {{get row cell.columnId}}
            {{/if}}
          {{/if}}
        {{/let}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
