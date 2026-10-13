---
order: 3
---

# Conditionally customizing cell popover content

<EuiText>

Cell popover content values can be conditionally customized using the
`isDetails` flag passed to the `<:cell>` block (or `@isDetails` passed to
the `@renderCellValue` component). If you need basic customization of cell
popover values based on, e.g. schema or column, this is the most
straightforward approach.

By default, all cell popover contents are rendered with an **EuiText**
wrapper, and cell actions are rendered within an **EuiPopoverFooter** as
**EuiButtonEmpty**s. Columns with a `json` schema additionally have an
automatic formatter that indents and displays the popover content within
an **EuiCodeBlock**.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { get, hash } from '@ember/helper';
import { and, eq } from 'ember-truth-helpers';
import { EuiDataGrid, EuiTitle } from '@ember-eui/core/components';

const FilterIn = <template>
  <@Component @iconType="plusCircle" aria-label="Filter in">Filter in</@Component>
</template>;
const FilterOut = <template>
  <@Component @iconType="minusCircle" aria-label="Filter out">Filter out</@Component>
</template>;

const cellActions = [FilterIn, FilterOut];

const columns = [
  { id: 'default', cellActions },
  { id: 'datetime', cellActions },
  { id: 'json', schema: 'json', cellActions },
  { id: 'custom', schema: 'favoriteFranchise', cellActions }
];

const data = [
  ['Hartmann, Ada Jr.', 'Tue Mar 12 2024 10:41:07 GMT+0000', '20375816', '412.08', 'Wed Aug 07 2024 16:02:55 GMT+0000'],
  ['Okafor, Bruno III', 'Sat Nov 30 2024 07:15:42 GMT+0000', '61049273', '87.50', 'Mon Jan 22 2024 21:30:19 GMT+0000'],
  ['Lindqvist, Carmen Sr.', 'Thu Jun 20 2024 23:58:01 GMT+0000', '87512046', '953.71', 'Fri Oct 04 2024 05:47:33 GMT+0000'],
  ['Moreau, Dmitri IV', 'Sun Feb 04 2024 13:26:50 GMT+0000', '39268105', '230.44', 'Tue Dec 17 2024 09:11:28 GMT+0000']
].map(([name, datetime, numeric, currency, date], i) => ({
  default: name,
  datetime,
  json: JSON.stringify([{ numeric, currency, date }]),
  custom: (i + 1) % 2 === 0 ? 'Star Wars' : 'Star Trek'
}));

export default class ConditionalPopoverContentDemo extends Component {
  @tracked visibleColumns = columns.map(({ id }) => id);

  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);

  <template>
    <EuiDataGrid
      aria-label="Data grid example of renderCellValue.isDetails"
      @columns={{columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{data.length}}
    >
      <:cell as |cell|>
        {{#let (get (get data cell.rowIndex) cell.columnId) as |value|}}
          {{#if (and (eq cell.schema "favoriteFranchise") cell.isDetails)}}
            <EuiTitle @size="xs"><h3>{{value}} is the best!</h3></EuiTitle>
          {{else}}
            {{value}}
          {{/if}}
        {{/let}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
