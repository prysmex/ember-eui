---
order: 5
---

# Control columns

<EuiText>

Control columns can be used to include ancillary cells not based on the
dataset, such as row selection checkboxes or action buttons. These columns
can be placed at either side of the data grid, and users are unable to
resize, sort, or rearrange them.

These custom columns are defined by passing an array of
EuiDataGridControlColumn objects (`{ id, width }`) to
`@leadingControlColumns` and/or `@trailingControlColumns`.

As with the data grid's `<:cell>` block, the `<:controlHeaderCell>` and
`<:controlCell>` blocks render the control columns (switch on `columnId`);
alternatively give a control column `headerCellRender` and `rowCellRender`
components. Control cells are not expandable; their interactive contents
are reached with Enter. The "items selected" button is added to the toolbar
with the `<:leftControlsAppend>` block (upstream's `additionalControls`).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { eq, gt } from 'ember-truth-helpers';
import {
  EuiAvatar,
  EuiButtonEmpty,
  EuiButtonIcon,
  EuiCheckbox,
  EuiContextMenuItem,
  EuiContextMenuPanel,
  EuiDataGrid,
  EuiDescriptionList,
  EuiDescriptionListDescription,
  EuiDescriptionListTitle,
  EuiFlyout,
  EuiFlyoutBody,
  EuiFlyoutHeader,
  EuiPopover,
  EuiPopoverTitle,
  EuiSpacer,
  EuiTitle,
  EuiToolTip,
} from '@ember-eui/core/components';

const LAST = ['Schmidt', 'Okafor', 'Lindqvist', 'Moreau', 'Tanaka', 'Novak', 'Ferreira', 'Kowalski', 'Haddad'];
const FIRST = ['Amara', 'Bruno', 'Chloe', 'Dmitri', 'Elena', 'Felix', 'Grace', 'Hiro', 'Ines', 'Jonas', 'Keira'];
const SUFFIXES = ['Jr.', 'Sr.', 'II', 'III', 'MD', 'PhD', 'DVM'];
const CITIES = ['Lake Ottoport', 'North Kaleigh', 'East Damian', 'Port Ellis', 'New Brayden', 'West Coraline'];
const COUNTRIES = ['Portugal', 'Norway', 'Japan', 'Peru', 'Kenya', 'Canada', 'Iceland', 'Chile'];

const data = Array.from({ length: 499 }, (_, i) => ({
  avatar: `${LAST[(i * 4 + 2) % LAST.length]}, ${FIRST[(i * 5 + 1) % FIRST.length]}`,
  name: `${LAST[i % LAST.length]}, ${FIRST[(i * 7) % FIRST.length]} ${SUFFIXES[i % SUFFIXES.length]}`,
  email: `${FIRST[(i * 7) % FIRST.length]}.${LAST[i % LAST.length]}${i}@example.com`.toLowerCase(),
  city: CITIES[(i * 5) % CITIES.length],
  country: COUNTRIES[(i * 3) % COUNTRIES.length],
  account: String(10000000 + ((i * 7919 * 104729) % 89999999))
}));

const columns = [
  { id: 'avatar', initialWidth: 38, isExpandable: false, isResizable: false },
  { id: 'name' },
  { id: 'email' },
  { id: 'city' },
  { id: 'country' },
  { id: 'account' }
];

export default class ControlColumnsDemo extends Component {
  data = data;
  columns = columns;

  leadingControlColumns = [
    { id: 'selection', width: 32 },
    { id: 'View', width: 36 }
  ];

  trailingControlColumns = [{ id: 'actions', width: 40 }];

  @tracked visibleColumns = columns.map(({ id }) => id);
  @tracked pageIndex = 0;
  @tracked pageSize;

  @tracked selectedRows = new Set();
  @tracked isSelectionPopoverOpen = false;
  @tracked actionsPopoverRow = null;
  @tracked flyoutRowIndex = null;

  get itemsLabel() {
    return this.selectedRows.size > 1 ? 'items' : 'item';
  }

  get isIndeterminate() {
    return this.selectedRows.size > 0 && this.selectedRows.size < data.length;
  }

  get flyoutRow() {
    return this.flyoutRowIndex === null ? null : data[this.flyoutRowIndex];
  }

  isSelected = (rowIndex) => this.selectedRows.has(rowIndex);

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  @action setPageIndex(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action setPageSize(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }

  @action toggleRow(rowIndex, event) {
    const next = new Set(this.selectedRows);
    if (event.target.checked) next.add(rowIndex);
    else next.delete(rowIndex);
    this.selectedRows = next;
  }

  @action toggleAll(event) {
    if (this.isIndeterminate || !event.target.checked) {
      // clear selection
      this.selectedRows = new Set();
    } else {
      // select everything
      this.selectedRows = new Set(data.map((_, index) => index));
    }
  }

  @action toggleSelectionPopover() {
    this.isSelectionPopoverOpen = !this.isSelectionPopoverOpen;
  }

  @action closeSelectionPopover() {
    this.isSelectionPopoverOpen = false;
  }

  @action alertAndClosePopover() {
    this.isSelectionPopoverOpen = false;
    window.alert('This is not a real control.');
  }

  @action toggleActionsPopover(rowIndex) {
    this.actionsPopoverRow = this.actionsPopoverRow === rowIndex ? null : rowIndex;
  }

  @action closeActionsPopover() {
    this.actionsPopoverRow = null;
  }

  @action openFlyout(rowIndex) {
    this.flyoutRowIndex = rowIndex;
  }

  @action closeFlyout() {
    this.flyoutRowIndex = null;
  }

  <template>
    <EuiDataGrid
      aria-label="Top EUI contributors"
      @leadingControlColumns={{this.leadingControlColumns}}
      @trailingControlColumns={{this.trailingControlColumns}}
      @columns={{this.columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{this.data.length}}
      @pagination={{hash
        pageIndex=this.pageIndex
        pageSize=this.pageSize
        onChangeItemsPerPage=this.setPageSize
        onChangePage=this.setPageIndex
      }}
    >
      <:leftControlsAppend>
        {{#if this.selectedRows.size}}
          <EuiPopover
            @isOpen={{this.isSelectionPopoverOpen}}
            @anchorPosition="upCenter"
            @panelPaddingSize="s"
            @closePopover={{this.closeSelectionPopover}}
          >
            <:button>
              <EuiButtonEmpty
                @size="xs"
                @iconType="chevronSingleDown"
                @iconSide="right"
                {{on "click" this.toggleSelectionPopover}}
              >
                {{this.selectedRows.size}} {{this.itemsLabel}} selected
              </EuiButtonEmpty>
            </:button>
            <:content>
              <EuiPopoverTitle>{{this.selectedRows.size}} {{this.itemsLabel}}</EuiPopoverTitle>
              <EuiContextMenuPanel>
                <EuiContextMenuItem @icon="pin" {{on "click" this.alertAndClosePopover}}>
                  Pin items
                </EuiContextMenuItem>
                <EuiContextMenuItem @icon="trash" {{on "click" this.alertAndClosePopover}}>
                  Delete item
                </EuiContextMenuItem>
              </EuiContextMenuPanel>
            </:content>
          </EuiPopover>
        {{/if}}
      </:leftControlsAppend>
      <:controlHeaderCell as |header|>
        {{#if (eq header.columnId "selection")}}
          <EuiCheckbox
            id="selection-toggle"
            aria-label="Select all rows"
            @indeterminate={{this.isIndeterminate}}
            @checked={{gt this.selectedRows.size 0}}
            {{on "change" this.toggleAll}}
          />
        {{/if}}
      </:controlHeaderCell>
      <:controlCell as |cell|>
        {{#if (eq cell.columnId "selection")}}
          <div>
            <EuiCheckbox
              id="selection-{{cell.rowIndex}}"
              aria-label="Select row {{cell.rowIndex}}, {{get (get this.data cell.rowIndex) 'name'}}"
              @checked={{this.isSelected cell.rowIndex}}
              {{on "change" (fn this.toggleRow cell.rowIndex)}}
            />
          </div>
        {{else if (eq cell.columnId "View")}}
          <EuiToolTip @content="View details" @disableScreenReaderOutput={{true}}>
            <EuiButtonIcon
              @color="text"
              @iconType="eye"
              @iconSize="s"
              aria-label="View details"
              {{on "click" (fn this.openFlyout cell.rowIndex)}}
            />
          </EuiToolTip>
        {{else}}
          <div>
            <EuiPopover
              @isOpen={{eq this.actionsPopoverRow cell.rowIndex}}
              @anchorPosition="upCenter"
              @panelPaddingSize="s"
              @closePopover={{this.closeActionsPopover}}
            >
              <:button>
                <EuiToolTip @content="Show actions" @disableScreenReaderOutput={{true}}>
                  <EuiButtonIcon
                    aria-label="Show actions"
                    @iconType="boxesVertical"
                    @color="text"
                    {{on "click" (fn this.toggleActionsPopover cell.rowIndex)}}
                  />
                </EuiToolTip>
              </:button>
              <:content>
                <EuiPopoverTitle>Actions</EuiPopoverTitle>
                <div style="width: 150px">
                  <EuiButtonEmpty @size="s" @color="text" @iconType="pin" aria-label="Pin selected items">
                    Pin
                  </EuiButtonEmpty>
                  <EuiSpacer @size="s" />
                  <EuiButtonEmpty @size="s" @color="text" @iconType="trash" aria-label="Delete selected items">
                    Delete
                  </EuiButtonEmpty>
                </div>
              </:content>
            </EuiPopover>
          </div>
        {{/if}}
      </:controlCell>
      <:cell as |cell|>
        {{#if (eq cell.columnId "avatar")}}
          <EuiAvatar @size="s" @name={{get (get this.data cell.rowIndex) "avatar"}} />
        {{else}}
          {{get (get this.data cell.rowIndex) cell.columnId}}
        {{/if}}
      </:cell>
    </EuiDataGrid>

    {{#if this.flyoutRow}}
      <EuiFlyout @ownFocus={{true}} @onClose={{this.closeFlyout}}>
        <EuiFlyoutHeader @hasBorder={{true}}>
          <EuiTitle @size="m"><h2>{{this.flyoutRow.name}}</h2></EuiTitle>
        </EuiFlyoutHeader>
        <EuiFlyoutBody>
          <EuiDescriptionList>
            {{#each-in this.flyoutRow as |key value|}}
              <EuiDescriptionListTitle>{{key}}</EuiDescriptionListTitle>
              <EuiDescriptionListDescription>{{value}}</EuiDescriptionListDescription>
            {{/each-in}}
          </EuiDescriptionList>
        </EuiFlyoutBody>
      </EuiFlyout>
    {{/if}}
  </template>
}
```
