---
order: 1
---

# Cell actions

<EuiText>

In addition to making a cell expandable, you can add more custom actions by
setting `columns.cellActions`. These actions render as icon buttons in the
cell on hover/focus, and as full buttons in the cell expansion popover.
Note that once any `cellActions` are passed, the cell becomes automatically
expandable: this ensures keyboard and screen reader users have access to
all cell actions.

`columns.cellActions` accepts an array of components. Because different
button types are used in the cell and in the cell popover, each action
receives a `@Component` argument which you must render (`<@Component>`) so
that your cell actions switch correctly between icon buttons and buttons.
Actions also receive `@rowIndex`, `@colIndex`, `@columnId` and
`@isExpanded` (true in the popover). As an Ember convenience, an action can
also be a plain `{ iconType, label, onClick }` object.

To close a cell's expansion popover upon clicking an action, use the
`closeCellPopover` method of the grid's API, received through
[`@registerApi`](/docs/core/docs/tabular/data-grid/ref-methods).

In the below example, the email and city columns provide 1 cell action
each, while the country column provides 2 cell actions.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn, get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiAvatar, EuiDataGrid } from '@ember-eui/core/components';

const rowNumber = (rowIndex) => rowIndex + 1;
const alertMessage = (message) => window.alert(message);

const loveMessage = (rowIndex, columnId) =>
  `Love sent from row ${rowIndex + 1}, column "${columnId}"`;

const cheerMessage = (rowIndex, columnId, isExpanded) =>
  isExpanded
    ? `Cheers sent in Popover to row "${rowIndex + 1}" column "${columnId}"`
    : `Cheers sent from row ${rowIndex + 1}, column "${columnId}"`;

const paintMessage = (rowIndex, columnId) =>
  `Paint sent from row ${rowIndex + 1}, column "${columnId}"`;

// Closes the expansion popover through the grid's API (see `@registerApi`)
const sendLoveAction = (closePopover) => {
  const sendLove = (rowIndex, columnId) => {
    alertMessage(loveMessage(rowIndex, columnId));
    closePopover();
  };
  return <template>
    <@Component
      @iconType="heart"
      aria-label='Send love to {{rowNumber @rowIndex}}, column "{{@columnId}}" '
      {{on "click" (fn sendLove @rowIndex @columnId)}}
    >Send love</@Component>
  </template>;
};

const CheerAction = <template>
  <@Component
    @iconType="popper"
    aria-label={{cheerMessage @rowIndex @columnId @isExpanded}}
    {{on "click" (fn alertMessage (cheerMessage @rowIndex @columnId @isExpanded))}}
  >Cheer</@Component>
</template>;

const LoveCityAction = <template>
  <@Component
    @iconType="heart"
    aria-label={{loveMessage @rowIndex @columnId}}
    {{on "click" (fn alertMessage (loveMessage @rowIndex @columnId))}}
  >Love this city</@Component>
</template>;

const PaintCountryAction = <template>
  <@Component
    @iconType="brush"
    aria-label='Paint country at row {{rowNumber @rowIndex}}, column "{{@columnId}}"'
    {{on "click" (fn alertMessage (paintMessage @rowIndex @columnId))}}
  >Paint this city</@Component>
</template>;

const data = [
  ['Hartmann', 'Ada', 'Jr.', 'ada.hartmann@example.com', 'Lake Rosalind', 'Iceland', '20375816'],
  ['Okafor', 'Bruno', 'III', 'bruno_okafor@example.net', 'North Kailey', 'Portugal', '61049273'],
  ['Lindqvist', 'Carmen', 'Sr.', 'carmen.l@example.org', 'Port Elnora', 'Chile', '87512046'],
  ['Moreau', 'Dmitri', 'IV', 'dmitri44@example.com', 'West Juniper', 'Kenya', '39268105']
].map(([last, first, suffix, email, city, country, account]) => ({
  avatar: `${last}, ${first}`,
  name: `${last}, ${first} ${suffix}`,
  email,
  city,
  country,
  account
}));

export default class CellActionsDemo extends Component {
  api = null;

  columns = [
    { id: 'avatar', initialWidth: 40, isResizable: false, actions: false },
    { id: 'name', initialWidth: 100, isSortable: true, actions: { showHide: false } },
    {
      id: 'email',
      isSortable: true,
      cellActions: [sendLoveAction(() => this.api?.closeCellPopover())]
    },
    { id: 'city', isSortable: true, cellActions: [CheerAction] },
    { id: 'country', cellActions: [LoveCityAction, PaintCountryAction] },
    { id: 'account' }
  ];

  @tracked visibleColumns = this.columns.map(({ id }) => id);
  @tracked pageIndex = 0;
  @tracked pageSize = 10;

  registerApi = (api) => (this.api = api);
  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);
  onChangePage = (pageIndex) => (this.pageIndex = pageIndex);
  onChangeItemsPerPage = (pageSize) => {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  };

  <template>
    <EuiDataGrid
      aria-label="DataGrid demonstrating cell actions"
      @columns={{this.columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{data.length}}
      @pagination={{hash
        pageIndex=this.pageIndex
        pageSize=this.pageSize
        onChangePage=this.onChangePage
        onChangeItemsPerPage=this.onChangeItemsPerPage
      }}
      @registerApi={{this.registerApi}}
    >
      <:cell as |cell|>
        {{#let (get data cell.rowIndex) as |row|}}
          {{#if (eq cell.columnId "avatar")}}
            <EuiAvatar @size="s" @name={{row.avatar}} />
          {{else}}
            {{get row cell.columnId}}
          {{/if}}
        {{/let}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
