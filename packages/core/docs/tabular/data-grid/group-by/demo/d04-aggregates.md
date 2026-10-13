---
order: 4
---

# Totals, averages and counts in group rows

<EuiText>

`renderGroupCell` renders every data cell of the group rows. This one shows
the label in the toggle column, a **sum** under "Amount", an **average**
under "Discount" and a **distinct count** under "Customer", all computed
from `@group.rowIndices`. Nested groups (region › quarter) get their own
totals.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { array, hash } from '@ember/helper';
import { EuiDataGrid } from '@ember-eui/core/components';

const ORDERS = [
  ['North', 'Q1', 'Acme', 1200, 5],
  ['North', 'Q1', 'Globex', 800, 0],
  ['North', 'Q2', 'Acme', 1500, 10],
  ['North', 'Q2', 'Initech', 400, 0],
  ['South', 'Q1', 'Hooli', 2200, 15],
  ['South', 'Q1', 'Acme', 300, 5],
  ['South', 'Q2', 'Hooli', 900, 0],
  ['South', 'Q2', 'Vandelay', 650, 20]
].map(([region, quarter, customer, amount, discount], i) => ({
  id: i,
  order: `#${1000 + i}`,
  region,
  quarter,
  customer,
  amount,
  discount
}));

const money = (value) => `$${value.toLocaleString('en-US')}`;

// what each column aggregates to in group rows
const aggregate = (rowIndices, columnId) => {
  const rows = rowIndices.map((i) => ORDERS[i]);
  switch (columnId) {
    case 'amount':
      return `Σ ${money(rows.reduce((sum, row) => sum + row.amount, 0))}`;
    case 'discount':
      return `avg ${(rows.reduce((sum, row) => sum + row.discount, 0) / rows.length).toFixed(1)}%`;
    case 'customer':
      return `${new Set(rows.map((row) => row.customer)).size} customers`;
    default:
      return '';
  }
};

const GroupCell = <template>
  {{#if @isToggleCell}}
    <strong>{{@group.value}}</strong> · {{@group.count}} orders
  {{else}}
    <em>{{aggregate @group.rowIndices @columnId}}</em>
  {{/if}}
</template>;

export default class AggregatesDemo extends Component {
  GroupCell = GroupCell;
  orders = ORDERS;

  columns = [
    { id: 'order', displayAsText: 'Order', initialWidth: 230 },
    { id: 'customer', displayAsText: 'Customer' },
    { id: 'amount', displayAsText: 'Amount', schema: 'numeric' },
    { id: 'discount', displayAsText: 'Discount', schema: 'numeric' }
  ];

  format = (row, columnId) => {
    if (columnId === 'amount') return money(row.amount);
    if (columnId === 'discount') return `${row.discount}%`;
    return row[columnId];
  };

  <template>
    <EuiDataGrid
      aria-label="Aggregates"
      @columns={{this.columns}}
      @grouping={{hash
        groupBy=(array "region" "quarter")
        rows=this.orders
        renderGroupCell=this.GroupCell
        defaultExpandedGroupIds=(array 'group:["North"]')
      }}
      @height={{380}}
    >
      <:cell as |cell|>{{this.format cell.row cell.columnId}}</:cell>
    </EuiDataGrid>
  </template>
}
```
