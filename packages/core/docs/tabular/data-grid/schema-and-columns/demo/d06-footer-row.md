---
order: 6
---

# Footer row

<EuiText>

A footer row can be used to include value aggregations to the grid. Values
could be based on the dataset, such as sum/average/min/max of numeric values
in a column, or any other necessary data.

The footer row is defined by passing a `@renderFooterCellValue` component
(or the `<:footerCell>` block) to **EuiDataGrid**. It receives the same
arguments as cells (`@columnId`, `@setCellProps`, …) and sticks to the
bottom of the grid (`gridStyle.stickyFooter`).

When rendering footer cell values, we encourage turning off cell expansion
on cells without content with `setCellProps({ isExpandable: false })`.

Control columns will render empty footer cells by default, unless a custom
`footerCellRender` component or the `<:controlFooterCell>` block is given.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import {
  EuiButtonIcon,
  EuiCheckbox,
  EuiDataGrid,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSwitch,
  EuiToolTip,
} from '@ember-eui/core/components';

const LAST = ['Schmidt', 'Okafor', 'Lindqvist', 'Moreau', 'Tanaka', 'Novak', 'Ferreira'];
const FIRST = ['Amara', 'Bruno', 'Chloe', 'Dmitri', 'Elena', 'Felix', 'Grace', 'Hiro'];
const SUFFIXES = ['Jr.', 'Sr.', 'II', 'III', 'MD', 'PhD'];

const rawData = Array.from({ length: 19 }, (_, i) => ({
  name: `${LAST[i % LAST.length]}, ${FIRST[(i * 3) % FIRST.length]} ${SUFFIXES[i % SUFFIXES.length]}`,
  date: `${new Date(Date.UTC(2024, (i * 5) % 12, 1 + ((i * 11) % 28), (i * 7) % 24))}`,
  amount: `$${((((i + 1) * 6151) % 99900) / 100 + 1).toFixed(2)}`,
  phone: `(${200 + ((i * 37) % 700)}) ${100 + ((i * 53) % 900)}-${1000 + ((i * 97) % 9000)}`,
  version: `${i % 4}.${(i * 3) % 10}.${(i * 7) % 20}`
}));

const columns = [
  { id: 'name', displayAsText: 'Name', defaultSortDirection: 'asc' },
  { id: 'date', defaultSortDirection: 'desc' },
  { id: 'amount' },
  { id: 'phone', isSortable: false },
  { id: 'version', defaultSortDirection: 'desc' }
];

const footerCellValues = {
  amount: `Total: ${rawData
    .reduce((acc, { amount }) => acc + Number(amount.split('$')[1]), 0)
    .toLocaleString('en-US', { style: 'currency', currency: 'USD' })}`,
  version: `Latest: ${rawData.map(({ version }) => version).sort()[rawData.length - 1]}`
};

const footerValue = (columnId) => footerCellValues[columnId];

// Turns off the cell expansion button when the footer cell is empty
const RenderFooterCellValue = <template>
  {{#let (footerValue @columnId) as |value|}}
    {{#if value}}
      {{value}}
    {{else}}
      {{@setCellProps (hash isExpandable=false)}}
    {{/if}}
  {{/let}}
</template>;

export default class FooterRowDemo extends Component {
  data = rawData;
  columns = columns;
  RenderFooterCellValue = RenderFooterCellValue;

  leadingControlColumns = [{ id: 'selection', width: 32 }];
  trailingControlColumns = [{ id: 'actions', width: 36 }];

  gridStyle = { border: 'horizontal', rowHover: 'highlight', header: 'underline' };

  @tracked visibleColumns = columns.map(({ id }) => id);
  @tracked pageIndex = 0;
  @tracked pageSize;
  @tracked showFooterRow = true;

  amountCellProps = (rowIndex) => {
    const numeric = parseFloat(rawData[rowIndex].amount.match(/\d+\.\d+/)[0]);
    return { style: { backgroundColor: `rgba(0, 255, 0, ${numeric * 0.0002})` } };
  };

  @action toggleFooterRow() {
    this.showFooterRow = !this.showFooterRow;
  }

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  @action onChangeItemsPerPage(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }

  @action onChangePage(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action onColumnResize(eventData) {
    console.log(eventData);
  }

  <template>
    <EuiFlexGroup @direction="column">
      <EuiFlexItem>
        <EuiSwitch
          @label="Show footer row"
          @checked={{this.showFooterRow}}
          @onChange={{this.toggleFooterRow}}
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiDataGrid
          aria-label="Data grid footer row demo"
          @columns={{this.columns}}
          @columnVisibility={{hash
            visibleColumns=this.visibleColumns
            setVisibleColumns=this.setVisibleColumns
          }}
          @leadingControlColumns={{this.leadingControlColumns}}
          @trailingControlColumns={{this.trailingControlColumns}}
          @rowCount={{this.data.length}}
          @renderFooterCellValue={{if this.showFooterRow this.RenderFooterCellValue}}
          @pagination={{hash
            pageIndex=this.pageIndex
            pageSize=this.pageSize
            onChangeItemsPerPage=this.onChangeItemsPerPage
            onChangePage=this.onChangePage
          }}
          @onColumnResize={{this.onColumnResize}}
          @gridStyle={{this.gridStyle}}
        >
          <:cell as |cell|>
            {{#if (eq cell.columnId "amount")}}
              {{cell.setCellProps (this.amountCellProps cell.rowIndex)}}
            {{/if}}
            {{get (get this.data cell.rowIndex) cell.columnId}}
          </:cell>
          {{! Check state doesn't actually work - this is just a static example }}
          <:controlHeaderCell as |header|>
            {{#if (eq header.columnId "selection")}}
              <EuiCheckbox id="selectAllHeader" aria-label="Select all rows" />
            {{else}}
              <span class="euiScreenReaderOnly">Actions</span>
            {{/if}}
          </:controlHeaderCell>
          <:controlCell as |cell|>
            {{#if (eq cell.columnId "selection")}}
              <EuiCheckbox id="selectRow{{cell.rowIndex}}" aria-label="Select this row" />
            {{else}}
              <EuiToolTip @content="Show actions" @disableScreenReaderOutput={{true}}>
                <EuiButtonIcon aria-label="Show actions" @iconType="boxesVertical" />
              </EuiToolTip>
            {{/if}}
          </:controlCell>
          <:controlFooterCell as |cell|>
            {{#if (eq cell.columnId "selection")}}
              <EuiCheckbox id="selectAllFooter" aria-label="Select all rows" />
            {{/if}}
          </:controlFooterCell>
        </EuiDataGrid>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
