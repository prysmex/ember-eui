---
order: 1
---

# Defining custom schemas

<EuiText>

Custom schemas are passed as an array to `@schemaDetectors` and are
constructed against the **EuiDataGridSchemaDetector** interface. You can see
an example of a simple custom schema used on the last column below. In
addition to schemas being useful to map against for cell and expansion
rendering, any schema will also add a `euiDataGridRowCell--schemaName` class
to each matching cell (and `euiDataGridHeaderCell--schemaName` to its
header).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { EuiDataGrid } from '@ember-eui/core/components';

const LAST = ['Schmidt', 'Okafor', 'Lindqvist', 'Moreau', 'Tanaka', 'Novak', 'Ferreira'];
const FIRST = ['Amara', 'Bruno', 'Chloe', 'Dmitri', 'Elena', 'Felix', 'Grace'];
const SUFFIXES = ['Jr.', 'Sr.', 'II', 'MD', 'PhD'];

const person = (i) => `${LAST[i % LAST.length]}, ${FIRST[(i * 3) % FIRST.length]} ${SUFFIXES[i % SUFFIXES.length]}`;
const pastDate = (i) => `${new Date(Date.UTC(2024, (i * 5) % 12, 1 + ((i * 11) % 28), 9 + i))}`;

const columns = [
  { id: 'default' },
  { id: 'boolean' },
  { id: 'numeric' },
  { id: 'currency' },
  { id: 'datetime', schema: 'datetime' },
  { id: 'json' },
  { id: 'custom', schema: 'favoriteFranchise' }
];

const storeData = [1, 2, 3, 4].map((i) => ({
  default: person(i),
  boolean: `${i % 3 === 0}`,
  numeric: String(10000000 + ((i * 7919 * 104729) % 89999999)),
  currency: (((i * 6151) % 99900) / 100).toFixed(2),
  datetime: pastDate(i),
  json: JSON.stringify([
    {
      default: person(i + 7),
      boolean: `${i % 2 === 0}`,
      numeric: String(20000000 + ((i * 3571) % 79999999)),
      currency: (((i * 4271) % 99900) / 100).toFixed(2),
      date: pastDate(i + 3),
      custom: pastDate(i + 5)
    }
  ]),
  custom: i % 2 === 0 ? 'Star Wars' : 'Star Trek'
}));

const commaSeparateNumbers = (numberString) =>
  // extract the groups-of-three digits that are right-aligned,
  // then replace each group of xyz digits with ,xyz
  numberString.replace(/((\d{3})+)$/, (match) => match.replace(/(\d{3})/g, ',$1'));

export default class CustomSchemasDemo extends Component {
  columns = columns;
  @tracked visibleColumns = columns.map(({ id }) => id);
  @tracked data = storeData;
  @tracked sortingColumns = [{ id: 'custom', direction: 'asc' }];

  schemaDetectors = [
    {
      type: 'favoriteFranchise',
      textTransform: 'capitalize',
      detector(value) {
        return value.toLowerCase() === 'star wars' || value.toLowerCase() === 'star trek' ? 1 : 0;
      },
      comparator(a, b, direction) {
        const aValue = a.toLowerCase() === 'star wars';
        const bValue = b.toLowerCase() === 'star wars';
        if (aValue < bValue) return direction === 'asc' ? 1 : -1;
        if (aValue > bValue) return direction === 'asc' ? -1 : 1;
        return 0;
      },
      sortTextAsc: 'Star wars-Star trek',
      sortTextDesc: 'Star trek-Star wars',
      icon: 'starFill',
      color: '#800080'
    }
  ];

  css = {
    '.euiDataGridRowCell--favoriteFranchise': { backgroundColor: 'rgba(128, 0, 128, 0.05)' },
    '.euiDataGridHeaderCell--favoriteFranchise': { backgroundColor: 'rgba(128, 0, 128, 0.1)' }
  };

  cellValue = (rowIndex, columnId, schema) => {
    const value = this.data[rowIndex][columnId];
    return schema === 'numeric' ? commaSeparateNumbers(value) : value;
  };

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  @action setSorting(sortingColumns) {
    this.data = [...this.data].sort((a, b) => {
      for (const column of sortingColumns) {
        const aValue = a[column.id];
        const bValue = b[column.id];
        if (aValue < bValue) return column.direction === 'asc' ? -1 : 1;
        if (aValue > bValue) return column.direction === 'asc' ? 1 : -1;
      }
      return 0;
    });
    this.sortingColumns = sortingColumns;
  }

  <template>
    <EuiDataGrid
      aria-label="Data grid schema example"
      @columns={{this.columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{this.data.length}}
      @inMemory={{hash level="sorting"}}
      @sorting={{hash columns=this.sortingColumns onSort=this.setSorting}}
      @schemaDetectors={{this.schemaDetectors}}
      @css={{this.css}}
    >
      <:cell as |cell|>
        {{this.cellValue cell.rowIndex cell.columnId cell.schema}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
