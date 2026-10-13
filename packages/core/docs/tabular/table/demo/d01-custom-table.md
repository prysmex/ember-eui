---
order: 1
---

# Custom table

<EuiText>

One of many ways you might set up a custom table that accounts for all the
notes above: the component sorts, pages and selects the items, the header
cells sort with `@onSort`, `@isSorted` and `@isSortAscending`, every cell
passes its `mobileOptions.header`, and `EuiTableHeaderMobile` holds the
"select all" checkbox and an `EuiTableSortMobile` for small screens.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn, get, hash, array } from '@ember/helper';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';
import {
  EuiBadge,
  EuiButton,
  EuiButtonIcon,
  EuiCheckbox,
  EuiContextMenuItem,
  EuiContextMenuPanel,
  EuiFieldSearch,
  EuiFlexGroup,
  EuiFlexItem,
  EuiHealth,
  EuiIcon,
  EuiLink,
  EuiPopover,
  EuiScreenReaderOnly,
  EuiSpacer,
  EuiTable,
  EuiTableBody,
  EuiTableFooter,
  EuiTableFooterCell,
  EuiTableHeader,
  EuiTableHeaderCell,
  EuiTableHeaderCellCheckbox,
  EuiTableHeaderMobile,
  EuiTablePagination,
  EuiTableRow,
  EuiTableRowCell,
  EuiTableRowCellCheckbox,
  EuiTableSortMobile,
  EuiToolTip,
} from '@ember-eui/core/components';

const LONG_WRAP =
  'A very long line which will wrap on narrower screens and NOT become truncated and replaced by an ellipsis';
const LONG_TRUNCATE =
  'A very long line which will not wrap on narrower screens and instead will become truncated and replaced by an ellipsis';
const ELEMENT_WRAP =
  'A very long line in an ELEMENT which will wrap on narrower screens and NOT become truncated and replaced by an ellipsis';
const ELEMENT_TRUNCATE =
  'A very long line in an ELEMENT which will not wrap on narrower screens and instead will become truncated and replaced by an ellipsis';

// [title, truncateText, isLink, dateCreated, magnitude, health color, health label]
const ITEMS = [
  [LONG_WRAP, false, false, 'Tue Dec 28 2016', 1, 'success', 'Healthy'],
  [LONG_TRUNCATE, true, false, 'Tue Dec 01 2016', 1, 'success', 'Healthy'],
  [ELEMENT_WRAP, false, false, 'Tue Dec 01 2016', 10, 'warning', 'Warning'],
  [ELEMENT_TRUNCATE, true, false, 'Tue Dec 16 2016', 100, 'success', 'Healthy'],
  ['Dog', false, true, 'Tue Dec 13 2016', 1000, 'warning', 'Warning'],
  ['Dragon', false, true, 'Tue Dec 11 2016', 10000, 'success', 'Healthy'],
  ['Bear', false, true, 'Tue Dec 11 2016', 10000, 'danger', 'Danger'],
  ['Dinosaur', false, true, 'Tue Dec 11 2016', 10000, 'warning', 'Warning'],
  ['Spider', false, true, 'Tue Dec 11 2016', 10000, 'warning', 'Warning'],
  ['Bugbear', false, true, 'Tue Dec 11 2016', 10000, 'success', 'Healthy'],
  ['Bear', false, true, 'Tue Dec 11 2016', 10000, 'danger', 'Danger'],
  ['Dinosaur', false, true, 'Tue Dec 11 2016', 10000, 'warning', 'Warning'],
  ['Spider', false, true, 'Tue Dec 11 2016', 10000, 'success', 'Healthy'],
  ['Bugbear', false, true, 'Tue Dec 11 2016', 10000, 'danger', 'Danger'],
].map(([title, truncateText, isLink, dateCreated, magnitude, healthColor, healthLabel], id) => ({
  id,
  title,
  truncateText,
  isLink,
  type: 'user',
  dateCreated,
  magnitude,
  // upstream shows one row's health with an EuiHealth instead of a badge
  health: { color: healthColor, label: healthLabel, asHealth: id === 12 },
}));

const SORTABLE = [
  { id: 'dateCreated', label: 'Date created', getValue: (item) => item.dateCreated.toLowerCase() },
  { id: 'magnitude', label: 'Orders of magnitude', getValue: (item) => item.magnitude },
];

export default class CustomTable extends Component {
  items = ITEMS;

  @tracked itemIdToSelectedMap = {};
  @tracked itemIdToOpenActionsPopoverMap = {};
  @tracked sortedColumn = 'magnitude';
  @tracked ascendingByName = { dateCreated: true, magnitude: true };
  @tracked itemsPerPage = 10;
  @tracked pageIndex = 0;

  get sortedItems() {
    const { getValue } = SORTABLE.find(({ id }) => id === this.sortedColumn);
    const direction = this.ascendingByName[this.sortedColumn] ? 1 : -1;
    return [...this.items].sort((a, b) =>
      getValue(a) === getValue(b) ? 0 : getValue(a) > getValue(b) ? direction : -direction
    );
  }

  get pageCount() {
    return Math.ceil(this.items.length / this.itemsPerPage);
  }

  get pageOfItems() {
    const start = this.pageIndex * this.itemsPerPage;
    return this.sortedItems.slice(start, start + this.itemsPerPage);
  }

  get pageTotal() {
    return this.pageOfItems.reduce((acc, cur) => acc + cur.magnitude, 0);
  }

  get mobileSortItems() {
    return SORTABLE.map(({ id, label }) => ({
      name: label,
      key: id,
      onSort: () => this.onSort(id),
      isSorted: this.sortedColumn === id,
      isSortAscending: this.ascendingByName[id],
    }));
  }

  get areAllItemsSelected() {
    return this.items.every((item) => this.itemIdToSelectedMap[item.id]);
  }

  get areAnyRowsSelected() {
    return Object.values(this.itemIdToSelectedMap).some(Boolean);
  }

  onSort = (prop) => {
    if (this.sortedColumn === prop) {
      this.ascendingByName = { ...this.ascendingByName, [prop]: !this.ascendingByName[prop] };
    }
    this.sortedColumn = prop;
  };

  onChangeItemsPerPage = (itemsPerPage) => {
    this.itemsPerPage = itemsPerPage;
    this.pageIndex = 0;
  };

  onChangePage = (pageIndex) => {
    this.pageIndex = pageIndex;
  };

  toggleItem = (itemId) => {
    this.itemIdToSelectedMap = {
      ...this.itemIdToSelectedMap,
      [itemId]: !this.itemIdToSelectedMap[itemId],
    };
  };

  toggleAll = () => {
    const allSelected = this.areAllItemsSelected;
    const itemIdToSelectedMap = {};
    this.items.forEach((item) => (itemIdToSelectedMap[item.id] = !allSelected));
    this.itemIdToSelectedMap = itemIdToSelectedMap;
  };

  togglePopover = (itemId) => {
    this.itemIdToOpenActionsPopoverMap = {
      ...this.itemIdToOpenActionsPopoverMap,
      [itemId]: !this.itemIdToOpenActionsPopoverMap[itemId],
    };
  };

  closePopover = (itemId) => {
    // only update the state if this item's popover is open
    if (this.itemIdToOpenActionsPopoverMap[itemId]) {
      this.itemIdToOpenActionsPopoverMap = {
        ...this.itemIdToOpenActionsPopoverMap,
        [itemId]: false,
      };
    }
  };

  // the search field is only a placeholder in this example
  onSearch = () => {};

  <template>
    <EuiFlexGroup @gutterSize="m">
      {{#if this.areAnyRowsSelected}}
        <EuiFlexItem @grow={{false}}>
          <EuiButton @color="danger">Delete selected</EuiButton>
        </EuiFlexItem>
      {{/if}}
      <EuiFlexItem>
        <EuiFieldSearch @fullWidth={{true}} @placeholder="Search..." @onSearch={{this.onSearch}} />
      </EuiFlexItem>
    </EuiFlexGroup>

    <EuiSpacer @size="m" />

    <EuiTableHeaderMobile>
      <EuiFlexGroup @responsive={{false}} @justifyContent="spaceBetween" @alignItems="baseline">
        <EuiFlexItem @grow={{false}}>
          <EuiCheckbox
            @id="selectAllCheckboxMobile"
            @label="Select all rows"
            aria-label="Select all rows"
            title="Select all rows"
            @checked={{this.areAllItemsSelected}}
            {{on "change" this.toggleAll}}
          />
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiTableSortMobile @items={{this.mobileSortItems}} />
        </EuiFlexItem>
      </EuiFlexGroup>
    </EuiTableHeaderMobile>

    <EuiTable id="example-id">
      <EuiTableHeader>
        <EuiTableHeaderCellCheckbox @width="32px">
          <EuiCheckbox
            @id="selectAllCheckboxDesktop"
            aria-label="Select all rows"
            title="Select all rows"
            @checked={{this.areAllItemsSelected}}
            {{on "change" this.toggleAll}}
          />
        </EuiTableHeaderCellCheckbox>
        <EuiTableHeaderCell @width="24px">
          <EuiScreenReaderOnly><span>Type</span></EuiScreenReaderOnly>
        </EuiTableHeaderCell>
        <EuiTableHeaderCell @align="left" @mobileOptions={{hash show=false}}>
          Title
        </EuiTableHeaderCell>
        <EuiTableHeaderCell
          @mobileOptions={{hash only=true header=false enlarge=true width="100%"}}
        >
          Title
        </EuiTableHeaderCell>
        <EuiTableHeaderCell @align="left">Health</EuiTableHeaderCell>
        <EuiTableHeaderCell
          @align="left"
          @onSort={{fn this.onSort "dateCreated"}}
          @isSorted={{eq this.sortedColumn "dateCreated"}}
          @isSortAscending={{this.ascendingByName.dateCreated}}
        >
          Date created
        </EuiTableHeaderCell>
        <EuiTableHeaderCell
          @align="right"
          @onSort={{fn this.onSort "magnitude"}}
          @isSorted={{eq this.sortedColumn "magnitude"}}
          @isSortAscending={{this.ascendingByName.magnitude}}
        >
          Orders of magnitude
        </EuiTableHeaderCell>
        <EuiTableHeaderCell @width="32px">
          <EuiScreenReaderOnly><span>Actions</span></EuiScreenReaderOnly>
        </EuiTableHeaderCell>
      </EuiTableHeader>

      <EuiTableBody>
        {{#each this.pageOfItems key="id" as |item|}}
          <EuiTableRow
            @isSelected={{get this.itemIdToSelectedMap item.id}}
            @hasSelection={{true}}
            @hasActions={{true}}
          >
            <EuiTableRowCellCheckbox>
              <EuiCheckbox
                @id="{{item.id}}-checkbox"
                @checked={{get this.itemIdToSelectedMap item.id}}
                {{on "change" (fn this.toggleItem item.id)}}
                title="Select this row"
                aria-label="Select this row"
              />
            </EuiTableRowCellCheckbox>
            <EuiTableRowCell
              @align="left"
              @textOnly={{false}}
              @mobileOptions={{hash header="Type" show=false}}
            >
              <EuiIcon @type={{item.type}} @size="m" />
            </EuiTableRowCell>
            <EuiTableRowCell
              @align="left"
              @truncateText={{item.truncateText}}
              @textOnly={{false}}
              @mobileOptions={{hash header="Title" show=false}}
            >
              {{#if item.isLink}}
                <EuiLink @href="#">{{item.title}}</EuiLink>
              {{else}}
                {{item.title}}
              {{/if}}
            </EuiTableRowCell>
            <EuiTableRowCell
              @truncateText={{item.truncateText}}
              @textOnly={{false}}
              @mobileOptions={{hash only=true header=false enlarge=true width="100%"}}
            >
              <EuiIcon @type={{item.type}} @size="m" style="vertical-align: text-top" />
              {{#if item.isLink}}
                <EuiLink @href="#">{{item.title}}</EuiLink>
              {{else}}
                {{item.title}}
              {{/if}}
            </EuiTableRowCell>
            <EuiTableRowCell
              @align="left"
              @textOnly={{false}}
              @mobileOptions={{hash header="Health"}}
            >
              {{#if item.health.asHealth}}
                <EuiHealth @color={{item.health.color}}>{{item.health.label}}</EuiHealth>
              {{else}}
                <EuiBadge @color={{item.health.color}}>{{item.health.label}}</EuiBadge>
              {{/if}}
            </EuiTableRowCell>
            <EuiTableRowCell
              @align="left"
              @textOnly={{false}}
              @mobileOptions={{hash header="Date created"}}
            >
              {{item.dateCreated}}
            </EuiTableRowCell>
            <EuiTableRowCell
              @align="right"
              @textOnly={{false}}
              @mobileOptions={{hash header="Orders of magnitude"}}
            >
              {{item.magnitude}}
            </EuiTableRowCell>
            <EuiTableRowCell
              @textOnly={{false}}
              @hasActions={{true}}
              @align="right"
              @mobileOptions={{hash header="Actions"}}
            >
              <EuiPopover
                id="{{item.id}}-actions"
                @isOpen={{get this.itemIdToOpenActionsPopoverMap item.id}}
                @closePopover={{fn this.closePopover item.id}}
                @panelPaddingSize="none"
                @anchorPosition="leftCenter"
              >
                <:button>
                  <EuiToolTip @content="Actions" @disableScreenReaderOutput={{true}}>
                    <EuiButtonIcon
                      aria-label="Actions"
                      @iconType="gear"
                      @size="s"
                      @color="text"
                      {{on "click" (fn this.togglePopover item.id)}}
                    />
                  </EuiToolTip>
                </:button>
                <:content>
                  <EuiContextMenuPanel>
                    <EuiContextMenuItem @icon="pencil" {{on "click" (fn this.closePopover item.id)}}>
                      Edit
                    </EuiContextMenuItem>
                    <EuiContextMenuItem @icon="share" {{on "click" (fn this.closePopover item.id)}}>
                      Share
                    </EuiContextMenuItem>
                    <EuiContextMenuItem @icon="trash" {{on "click" (fn this.closePopover item.id)}}>
                      Delete
                    </EuiContextMenuItem>
                  </EuiContextMenuPanel>
                </:content>
              </EuiPopover>
            </EuiTableRowCell>
          </EuiTableRow>
        {{/each}}
      </EuiTableBody>

      <EuiTableFooter>
        <EuiTableFooterCell />
        <EuiTableFooterCell @align="left" />
        <EuiTableFooterCell @align="left"><em>Title</em></EuiTableFooterCell>
        <EuiTableFooterCell @align="left" />
        <EuiTableFooterCell @align="left">Date created</EuiTableFooterCell>
        <EuiTableFooterCell @align="right"><strong>Total: {{this.pageTotal}}</strong></EuiTableFooterCell>
        <EuiTableFooterCell @align="right" />
      </EuiTableFooter>
    </EuiTable>

    <EuiSpacer @size="m" />

    <EuiTablePagination
      aria-label="Custom EuiTable demo"
      @ariaControls="example-id"
      @activePage={{this.pageIndex}}
      @itemsPerPage={{this.itemsPerPage}}
      @itemsPerPageOptions={{array 5 10 20}}
      @pageCount={{this.pageCount}}
      @onChangeItemsPerPage={{this.onChangeItemsPerPage}}
      @onChangePage={{this.onChangePage}}
      @compressed={{true}}
    />
  </template>
}
```
