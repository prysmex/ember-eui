---
order: 1
---

# Custom body rendering demo

<EuiText>

The body renders every row of the current page without virtualization,
and shows each row's details (a hidden-header trailing control column) on
a line of its own below the row's cells. Toggle "Constrained grid height"
to give the grid a height: the custom body then scrolls.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { eq, not } from 'ember-truth-helpers';
import {
  EuiButton,
  EuiButtonIcon,
  EuiCallOut,
  EuiCheckbox,
  EuiDataGrid,
  EuiFlexGroup,
  EuiScreenReaderOnly,
  EuiSplitPanelInner,
  EuiSplitPanelOuter,
  EuiSwitch,
  EuiToolTip,
} from '@ember-eui/core/components';

/**
 * Mock data
 */
const LAST = ['Schmidt', 'Okafor', 'Lindqvist', 'Moreau', 'Tanaka', 'Novak', 'Ferreira', 'Kowalski', 'Haddad'];
const FIRST = ['Amara', 'Bruno', 'Chloe', 'Dmitri', 'Elena', 'Felix', 'Grace', 'Hiro', 'Ines', 'Jonas', 'Keira'];
const CITIES = ['Lake Ottoport', 'North Kaleigh', 'East Damian', 'Port Ellis', 'New Brayden', 'West Coraline'];
const COUNTRIES = ['Portugal', 'Norway', 'Japan', 'Peru', 'Kenya', 'Canada', 'Iceland', 'Chile'];

const rawData = Array.from({ length: 99 }, (_, i) => ({
  name: `${LAST[i % LAST.length]}, ${FIRST[(i * 7) % FIRST.length]}`,
  email: `${FIRST[(i * 7) % FIRST.length]}.${LAST[i % LAST.length]}${i}@example.com`.toLowerCase(),
  location: `${CITIES[(i * 5) % CITIES.length]}, ${COUNTRIES[(i * 3) % COUNTRIES.length]}`,
  date: `${new Date(Date.UTC(2024, (i * 5) % 12, 1 + ((i * 11) % 28), (i * 7) % 24))}`,
  amount: `$${((((i + 1) * 6151) % 99900) / 100 + 1).toFixed(2)}`,
  feesOwed: i % 3 === 0 ? 'true' : ''
}));

const footerData = {
  amount: `Total: ${rawData
    .reduce((acc, { amount }) => acc + Number(amount.split('$')[1]), 0)
    .toLocaleString('en-US', { style: 'currency', currency: 'USD' })}`
};

/**
 * Columns
 */
const alertAction = () => window.alert('action');

const SomeAction = <template>
  <@Component @iconType="faceHappy" aria-label="Some action" {{on "click" alertAction}}>
    Some action
  </@Component>
</template>;

const columns = [
  { id: 'name', displayAsText: 'Name', cellActions: [SomeAction] },
  { id: 'email', displayAsText: 'Email address', initialWidth: 130 },
  { id: 'location', displayAsText: 'Location' },
  { id: 'date', displayAsText: 'Date' },
  { id: 'amount', displayAsText: 'Amount' }
];

/**
 * Cell component
 */
const RenderCellValue = <template>{{get (get rawData @rowIndex) @columnId}}</template>;

/**
 * Row details component
 */
const firstName = (rowIndex) => rawData[rowIndex].name.split(', ')[1];
const hasFees = (rowIndex) => !!rawData[rowIndex].feesOwed;
const detailsCellProps = { style: { width: '100%', height: 'auto' } };

const RenderRowDetails = <template>
  {{@setCellProps detailsCellProps}}
  {{#if (hasFees @rowIndex)}}
    <EuiCallOut
      @size="s"
      @color="danger"
      @iconType="errorFill"
      @title="{{firstName @rowIndex}}'s account has outstanding fees"
    >
      <:body>
        <EuiButton @color="danger" @size="s">Send an email reminder</EuiButton>
      </:body>
    </EuiCallOut>
  {{else}}
    <EuiCallOut
      @size="s"
      @color="success"
      @iconType="checkCircleFill"
      @title="{{firstName @rowIndex}}'s account has no outstanding fees"
    />
  {{/if}}
</template>;

/**
 * Control columns
 */
const leadingControlColumns = [
  {
    id: 'selection',
    width: 32,
    headerCellRender: <template>
      <EuiCheckbox id="select-all-rows" aria-label="Select all rows" />
    </template>,
    rowCellRender: <template>
      <EuiCheckbox id="select-row-{{@rowIndex}}" aria-label="Select row" />
    </template>
  }
];

const trailingControlColumns = [
  {
    id: 'actions',
    width: 40,
    headerCellRender: <template>
      <EuiScreenReaderOnly><span>Actions</span></EuiScreenReaderOnly>
    </template>,
    rowCellRender: <template>
      <EuiToolTip @content="See row actions" @disableScreenReaderOutput={{true}}>
        <EuiButtonIcon @iconType="boxesVertical" aria-label="See row actions" />
      </EuiToolTip>
    </template>
  },
  // The custom row details is actually a trailing control column cell with
  // a hidden header. This is important for accessibility and markup reasons
  {
    id: 'row-details',
    // The header cell should be visually hidden, but available to screen readers
    width: 0,
    headerCellRender: <template>Row details</template>,
    headerCellProps: { className: 'euiScreenReaderOnly' },
    // When rendering this custom cell, we'll want to override
    // the automatic width/heights calculated by EuiDataGrid
    rowCellRender: RenderRowDetails
  }
];

/**
 * Footer cell component: turns off the cell expansion button if the footer cell is empty
 */
const footerValue = (columnId) => footerData[columnId];
const notExpandable = { isExpandable: false };

const RenderFooterCellValue = <template>
  {{#let (footerValue @columnId) as |value|}}
    {{#if value}}{{value}}{{else}}{{@setCellProps notExpandable}}{{/if}}
  {{/let}}
</template>;

/**
 * Custom body: ensures we're displaying correctly-paginated rows, and renders
 * the row details cell outside of the row's flex wrapper
 */
const visibleRows = (visibleRowData) => rawData.slice(visibleRowData.startRow, visibleRowData.endRow);
const lastIndex = (list) => list.length - 1;
const bodyProps = {
  // Set custom props onto the grid body wrapper
  onScroll: (event) => console.debug('scrollTop:', event.currentTarget.scrollTop)
};

const CustomUnvirtualizedGridBody = <template>
  {{@setCustomGridBodyProps bodyProps}}
  {{#if @headerRow}}<@headerRow />{{/if}}
  {{#each (visibleRows @visibleRowData) as |_row rowIndex|}}
    <div role="row" class="euiDataGridRow" style="width: fit-content">
      <div style="display: flex">
        {{#each @visibleColumns as |column colIndex|}}
          {{! Skip the row details cell - we'll render it manually outside of the flex wrapper }}
          {{#if (not (eq column.id "row-details"))}}
            <@Cell @colIndex={{colIndex}} @visibleRowIndex={{rowIndex}} />
          {{/if}}
        {{/each}}
      </div>
      <div class="customRowDetails">
        {{! If the row is being shown, it should always be the last index }}
        <@Cell @colIndex={{lastIndex @visibleColumns}} @visibleRowIndex={{rowIndex}} />
      </div>
    </div>
  {{/each}}
  {{#if @footerRow}}<@footerRow />{{/if}}
</template>;

export default class CustomBodyRenderingDemo extends Component {
  columns = columns;
  rowCount = rawData.length;
  leadingControlColumns = leadingControlColumns;
  trailingControlColumns = trailingControlColumns;
  RenderCellValue = RenderCellValue;
  RenderFooterCellValue = RenderFooterCellValue;
  CustomUnvirtualizedGridBody = CustomUnvirtualizedGridBody;

  gridStyle = { border: 'none', header: 'underline' };
  // Extra specificity needed to override EuiDataGrid's default styles
  css = { '.customRowDetails .euiDataGridRowCell__content': { display: 'block', padding: 0 } };

  @tracked autoHeight = true;

  // Column visibility
  @tracked visibleColumns = columns.map(({ id }) => id);

  // Pagination
  @tracked pageIndex = 0;
  @tracked pageSize;

  // Sorting
  @tracked sortingColumns = [];

  get height() {
    return this.autoHeight ? undefined : 500;
  }

  @action toggleAutoHeight() {
    this.autoHeight = !this.autoHeight;
  }

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  @action onChangePage(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action onChangePageSize(pageSize) {
    this.pageSize = pageSize;
  }

  @action onSort(sortingColumns) {
    this.sortingColumns = sortingColumns;
  }

  <template>
    <EuiSplitPanelOuter @hasBorder={{true}}>
      <EuiSplitPanelInner @color="subdued">
        <EuiFlexGroup @alignItems="center">
          <EuiSwitch
            @label="Constrained grid height"
            @checked={{not this.autoHeight}}
            @onChange={{this.toggleAutoHeight}}
          />
        </EuiFlexGroup>
      </EuiSplitPanelInner>
      <EuiSplitPanelInner>
        <EuiDataGrid
          aria-label="Data grid custom body renderer demo"
          @columns={{this.columns}}
          @leadingControlColumns={{this.leadingControlColumns}}
          @trailingControlColumns={{this.trailingControlColumns}}
          @columnVisibility={{hash
            visibleColumns=this.visibleColumns
            setVisibleColumns=this.setVisibleColumns
          }}
          @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
          @inMemory={{hash level="sorting"}}
          @pagination={{hash
            pageIndex=this.pageIndex
            pageSize=this.pageSize
            onChangePage=this.onChangePage
            onChangeItemsPerPage=this.onChangePageSize
          }}
          @rowCount={{this.rowCount}}
          @renderCellValue={{this.RenderCellValue}}
          @renderFooterCellValue={{this.RenderFooterCellValue}}
          @renderCustomGridBody={{this.CustomUnvirtualizedGridBody}}
          @gridStyle={{this.gridStyle}}
          @css={{this.css}}
          @height={{this.height}}
        />
      </EuiSplitPanelInner>
    </EuiSplitPanelOuter>
  </template>
}
```
