---
order: 4
---

# Sorting and pagination in-memory

<EuiText>

With `@inMemory={{hash level="sorting"}}` the grid will now take care of
managing the data cleanup for sorting as well as pagination. Like before it
will autodetect schemas when possible.

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
  @tracked pageSize = undefined;

  // Sorting
  @tracked sortingColumns = [];

  // Column visibility
  @tracked visibleColumns = columns.map(({ id }) => id);

  // The grid itself is responsible for sorting and pagination
  rowAt = (rowIndex) => rawData[rowIndex];

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
      aria-label="inMemory level set to sorting data grid demo"
      @columns={{this.columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{this.rowCount}}
      @inMemory={{hash level="sorting"}}
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
