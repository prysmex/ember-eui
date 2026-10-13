---
order: 1
---

# Data grid demo

<EuiText>

The demo combines most features: in-memory sorting, pagination, a
controlled column visibility, column actions, cell actions (components
receiving `@Component`, the button to render), a cell that colors itself
with `setCellProps`, and a trailing control column whose actions open a
modal or a flyout. Closing them returns focus to the cell with the
`setFocusedCell` method of `@registerApi`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { concat, fn, get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';
import {
  EuiButton,
  EuiButtonEmpty,
  EuiButtonIcon,
  EuiCode,
  EuiContextMenuItem,
  EuiContextMenuPanel,
  EuiDataGrid,
  EuiFlyout,
  EuiFlyoutBody,
  EuiFlyoutFooter,
  EuiFlyoutHeader,
  EuiLink,
  EuiModal,
  EuiModalBody,
  EuiModalFooter,
  EuiModalHeader,
  EuiModalHeaderTitle,
  EuiPopover,
  EuiScreenReaderOnly,
  EuiText,
  EuiTitle,
  EuiToolTip,
} from '@ember-eui/core/components';

// Deterministic sample data with the fields of upstream's faker data
const LAST = ['Schmidt', 'Okafor', 'Lindqvist', 'Moreau', 'Tanaka', 'Novak', 'Ferreira', 'Kowalski', 'Haddad', 'Larsen', 'Rossi', 'Abbott'];
const FIRST = ['Amara', 'Bruno', 'Chloe', 'Dmitri', 'Elena', 'Felix', 'Grace', 'Hiro', 'Ines', 'Jonas', 'Keira', 'Liam', 'Maya'];
const SUFFIXES = ['Jr.', 'Sr.', 'II', 'III', 'IV', 'MD', 'PhD', 'DVM'];
const CITIES = ['Lake Ottoport', 'North Kaleigh', 'East Damian', 'Port Ellis', 'New Brayden', 'West Coraline', 'South Ivy'];
const COUNTRIES = ['Portugal', 'Norway', 'Japan', 'Peru', 'Kenya', 'Canada', 'Iceland', 'Chile', 'Morocco'];

const data = Array.from({ length: 99 }, (_, i) => {
  const first = FIRST[(i * 7) % FIRST.length];
  const last = LAST[(i * 5) % LAST.length];
  const name = `${last}, ${first}`;
  return {
    name: { formatted: `${name} ${SUFFIXES[i % SUFFIXES.length]}`, raw: name },
    email: { raw: `${first}.${last}${i}@example.com`.toLowerCase() },
    city: CITIES[(i * 3) % CITIES.length],
    country: COUNTRIES[(i * 4) % COUNTRIES.length],
    date: new Date(Date.UTC(2024, (i * 5) % 12, 1 + ((i * 11) % 28), (i * 7) % 24)).toString(),
    account: String(10000000 + ((i * 7919 * 104729) % 89999999)),
    amount: `${(((i * 6151) % 99900) / 100 + 1).toFixed(2)}`,
    phone: `(${200 + ((i * 37) % 700)}) ${String(100 + ((i * 53) % 900))}-${String(1000 + ((i * 97) % 9000))}`,
    version: `${i % 4}.${(i * 3) % 10}.${(i * 7) % 20}`
  };
});

const rawValue = (rowIndex, columnId) => data[rowIndex][columnId].raw ?? data[rowIndex][columnId];

const alert = (message) => window.alert(message);
const sendMoneyMessage = (rowIndex, columnId, isExpanded) =>
  `Sent money to ${rawValue(rowIndex, columnId)} ${isExpanded ? 'when expanded' : 'when not expanded'}`;

// Cell actions are components receiving the `@Component` button to render
const SayHi = <template>
  <@Component
    @iconType="heart"
    aria-label="Say hi to {{rawValue @rowIndex @columnId}}!"
    {{on "click" (fn alert (concat "Hi " (rawValue @rowIndex @columnId)))}}
  >Say hi</@Component>
</template>;

const SayBye = <template>
  <@Component
    @iconType="moon"
    aria-label="Say bye to {{rawValue @rowIndex @columnId}}!"
    {{on "click" (fn alert (concat "Bye " (rawValue @rowIndex @columnId)))}}
  >Say bye</@Component>
</template>;

const SendEmail = <template>
  <@Component
    @iconType="mail"
    aria-label="Send email to {{rawValue @rowIndex @columnId}}"
    {{on "click" (fn alert (rawValue @rowIndex @columnId))}}
  >Send email</@Component>
</template>;

const SendMoney = <template>
  <@Component
    @iconType="faceHappy"
    aria-label="Send money to {{rawValue @rowIndex @columnId}}"
    {{on "click" (fn alert (sendMoneyMessage @rowIndex @columnId @isExpanded))}}
  >Send money</@Component>
</template>;

const columns = [
  { id: 'name', displayAsText: 'Name', defaultSortDirection: 'asc', cellActions: [SayHi, SayBye] },
  { id: 'email', displayAsText: 'Email address', initialWidth: 130, cellActions: [SendEmail] },
  { id: 'location', displayAsText: 'Location' },
  {
    id: 'account',
    displayAsText: 'Account',
    actions: {
      showHide: { label: 'Custom hide label' },
      showMoveLeft: false,
      showMoveRight: false,
      additional: [
        { label: 'Custom action', onClick: () => {}, iconType: 'popper', size: 'xs', color: 'text' }
      ]
    },
    cellActions: [SendMoney]
  },
  { id: 'date', displayAsText: 'Date', defaultSortDirection: 'desc' },
  { id: 'amount', displayAsText: 'Amount' },
  { id: 'phone', displayAsText: 'Phone', isSortable: false },
  {
    id: 'version',
    displayAsText: 'Version',
    defaultSortDirection: 'desc',
    initialWidth: 70,
    isResizable: false,
    actions: false
  }
];

export default class DataGridDemo extends Component {
  data = data;
  columns = columns;
  trailingControlColumns = [{ id: 'actions', width: 40 }];
  gridApi = null;

  // Pagination
  @tracked pageIndex = 0;
  @tracked pageSize;

  // Sorting
  @tracked sortingColumns = [];

  // Column visibility, initialized to the full set of columns
  @tracked visibleColumns = columns.map(({ id }) => id);

  // Row actions
  @tracked popoverRowIndex = null;
  @tracked isModalVisible = false;
  @tracked isFlyoutVisible = false;
  focusedCell = null;

  amountCellProps = (amount) => ({
    style: { backgroundColor: `rgba(0, 255, 0, ${parseFloat(amount) * 0.0002})` }
  });

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

  @action onColumnResize(eventData) {
    console.log(eventData);
  }

  registerApi = (api) => {
    this.gridApi = api;
  };

  @action togglePopover(rowIndex, colIndex) {
    this.focusedCell = { rowIndex, colIndex };
    this.popoverRowIndex = this.popoverRowIndex === rowIndex ? null : rowIndex;
  }

  @action closePopover() {
    this.popoverRowIndex = null;
  }

  @action showModal() {
    this.closePopover();
    this.isModalVisible = true;
  }

  @action closeModal() {
    this.isModalVisible = false;
    this.gridApi?.setFocusedCell(this.focusedCell);
  }

  @action showFlyout() {
    this.closePopover();
    this.isFlyoutVisible = true;
  }

  @action closeFlyout() {
    this.isFlyoutVisible = false;
    this.gridApi?.setFocusedCell(this.focusedCell);
  }

  <template>
    <EuiDataGrid
      aria-label="Data grid demo"
      @columns={{this.columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @trailingControlColumns={{this.trailingControlColumns}}
      @rowCount={{this.data.length}}
      @inMemory={{hash level="sorting"}}
      @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
      @pagination={{hash
        pageIndex=this.pageIndex
        pageSize=this.pageSize
        onChangeItemsPerPage=this.onChangeItemsPerPage
        onChangePage=this.onChangePage
      }}
      @onColumnResize={{this.onColumnResize}}
      @registerApi={{this.registerApi}}
    >
      <:cell as |cell|>
        {{#let (get this.data cell.rowIndex) as |row|}}
          {{#if (eq cell.columnId "name")}}
            {{row.name.formatted}}
          {{else if (eq cell.columnId "email")}}
            <EuiLink @href="#">{{row.email.raw}}</EuiLink>
          {{else if (eq cell.columnId "location")}}
            {{row.city}},
            <EuiLink @href="https://google.com">{{row.country}}</EuiLink>
          {{else if (eq cell.columnId "amount")}}
            {{cell.setCellProps (this.amountCellProps row.amount)}}
            {{row.amount}}
          {{else}}
            {{get row cell.columnId}}
          {{/if}}
        {{/let}}
      </:cell>
      <:controlHeaderCell>
        <EuiScreenReaderOnly><span>Controls</span></EuiScreenReaderOnly>
      </:controlHeaderCell>
      <:controlCell as |cell|>
        <EuiPopover
          @isOpen={{eq this.popoverRowIndex cell.rowIndex}}
          @panelPaddingSize="none"
          @anchorPosition="upCenter"
          @closePopover={{this.closePopover}}
        >
          <:button>
            <EuiToolTip @content="Show actions" @disableScreenReaderOutput={{true}}>
              <EuiButtonIcon
                aria-label="Show actions"
                @iconType="boxesVertical"
                @color="text"
                {{on "click" (fn this.togglePopover cell.rowIndex cell.colIndex)}}
              />
            </EuiToolTip>
          </:button>
          <:content>
            <EuiContextMenuPanel @title="Actions">
              <EuiContextMenuItem @icon="chartWaterfall" {{on "click" this.showModal}}>
                Modal example
              </EuiContextMenuItem>
              <EuiContextMenuItem @icon="tableOfContents" {{on "click" this.showFlyout}}>
                Flyout example
              </EuiContextMenuItem>
            </EuiContextMenuPanel>
          </:content>
        </EuiPopover>
      </:controlCell>
    </EuiDataGrid>

    {{#if this.isModalVisible}}
      <EuiModal @onClose={{this.closeModal}} style="width: 500px">
        <EuiModalHeader>
          <EuiModalHeaderTitle>A typical modal</EuiModalHeaderTitle>
        </EuiModalHeader>
        <EuiModalBody>
          <EuiText>
            <p>
              <EuiLink @href="/docs/core/docs/layout/modal"><strong>EuiModal</strong></EuiLink>
              components have a higher <EuiCode>z-index</EuiCode> than
              <strong>EuiDataGrid</strong> components, even in fullscreen mode.
              This ensures that modals will never appear behind the data grid.
            </p>
          </EuiText>
        </EuiModalBody>
        <EuiModalFooter>
          <EuiButton @fill={{true}} {{on "click" this.closeModal}}>Close</EuiButton>
        </EuiModalFooter>
      </EuiModal>
    {{/if}}

    {{#if this.isFlyoutVisible}}
      <EuiFlyout
        aria-labelledby="dataGridDemoFlyoutTitle"
        @onClose={{this.closeFlyout}}
        @ownFocus={{true}}
        @size="s"
      >
        <EuiFlyoutHeader @hasBorder={{true}}>
          <EuiTitle @size="m"><h2 id="dataGridDemoFlyoutTitle">A typical flyout</h2></EuiTitle>
        </EuiFlyoutHeader>
        <EuiFlyoutBody>
          <EuiText>
            <p>
              <EuiLink @href="/docs/core/docs/layout/flyout"><strong>EuiFlyout</strong></EuiLink>
              components have a higher <EuiCode>z-index</EuiCode> than
              <strong>EuiDataGrid</strong> components, even in fullscreen mode.
              This ensures that flyouts will never appear behind the data grid.
            </p>
            <p>
              Flyouts are also styled with a vertical offset that accounts for the
              presence of fixed headers. However, when the data grid is in
              fullscreen mode, these offset styles are ignored to allow the flyout
              to correctly appear at the top of the viewport.
            </p>
          </EuiText>
        </EuiFlyoutBody>
        <EuiFlyoutFooter>
          <EuiButtonEmpty @flush="left" @iconType="cross" {{on "click" this.closeFlyout}}>
            Close
          </EuiButtonEmpty>
        </EuiFlyoutFooter>
      </EuiFlyout>
    {{/if}}
  </template>
}
```
