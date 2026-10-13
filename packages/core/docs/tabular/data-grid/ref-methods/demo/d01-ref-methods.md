---
order: 1
---

# Ref methods demo

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiDataGrid,
  EuiFieldNumber,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
  EuiModal,
  EuiModalBody,
  EuiModalFooter,
  EuiModalHeader,
  EuiModalHeaderTitle,
  EuiSpacer,
  EuiText,
} from '@ember-eui/core/components';

const LAST = ['Schmidt', 'Okafor', 'Lindqvist', 'Moreau', 'Tanaka', 'Novak', 'Ferreira', 'Kowalski', 'Haddad'];
const FIRST = ['Amara', 'Bruno', 'Chloe', 'Dmitri', 'Elena', 'Felix', 'Grace', 'Hiro', 'Ines', 'Jonas', 'Keira'];
const CITIES = ['Lake Ottoport', 'North Kaleigh', 'East Damian', 'Port Ellis', 'New Brayden', 'West Coraline'];
const COUNTRIES = ['Portugal', 'Norway', 'Japan', 'Peru', 'Kenya', 'Canada', 'Iceland', 'Chile'];

const rawData = Array.from({ length: 99 }, (_, i) => ({
  name: `${LAST[i % LAST.length]}, ${FIRST[(i * 7) % FIRST.length]}`,
  email: `${FIRST[(i * 7) % FIRST.length]}.${LAST[i % LAST.length]}${i}@example.com`.toLowerCase(),
  location: `${CITIES[(i * 5) % CITIES.length]}, ${COUNTRIES[(i * 3) % COUNTRIES.length]}`,
  account: String(10000000 + (((i + 1) * 7919 * 104729) % 89999999)),
  date: `${new Date(Date.UTC(2024, (i * 5) % 12, 1 + ((i * 11) % 28), (i * 7) % 24))}`
}));

export default class RefMethodsDemo extends Component {
  data = rawData;
  dataGridApi = null;

  // Modal
  @tracked isModalVisible = false;
  lastFocusedCell = { rowIndex: 0, colIndex: 0 };

  showModal = (rowIndex, colIndex) => {
    this.isModalVisible = true;
    this.dataGridApi.closeCellPopover(); // Close any open cell popovers
    this.lastFocusedCell = { rowIndex, colIndex }; // Store the cell that opened this modal
  };

  // Columns: the cell action closes over the demo's `showModal`
  columns = (() => {
    const showModal = this.showModal;
    const OpenModalAction = <template>
      <@Component
        @iconType="faceHappy"
        aria-label="Open modal"
        {{on "click" (fn showModal @rowIndex @colIndex)}}
      >Open modal</@Component>
    </template>;

    return [
      { id: 'name', displayAsText: 'Name', cellActions: [OpenModalAction] },
      { id: 'email', displayAsText: 'Email address', initialWidth: 130, cellActions: [OpenModalAction] },
      { id: 'location', displayAsText: 'Location', cellActions: [OpenModalAction] },
      { id: 'account', displayAsText: 'Account', cellActions: [OpenModalAction] },
      { id: 'date', displayAsText: 'Date', cellActions: [OpenModalAction] }
    ];
  })();

  // Column visibility
  @tracked visibleColumns = this.columns.map(({ id }) => id);

  // Pagination
  @tracked pageIndex = 0;
  @tracked pageSize;

  // Sorting
  @tracked sortingColumns = [];

  // Manual cell focus
  @tracked rowIndexAction = 0;
  @tracked colIndexAction = 0;

  get maxRowIndex() {
    return this.data.length - 1;
  }

  get maxColIndex() {
    return this.visibleColumns.length - 1;
  }

  registerApi = (api) => {
    this.dataGridApi = api;
  };

  @action closeModal() {
    this.isModalVisible = false;
    // Set the data grid focus back to the cell that opened the modal
    this.dataGridApi.setFocusedCell(this.lastFocusedCell);
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

  @action setRowIndexAction(event) {
    this.rowIndexAction = Number(event.target.value);
  }

  @action setColIndexAction(event) {
    this.colIndexAction = Number(event.target.value);
  }

  @action setCellFocus() {
    this.dataGridApi.setFocusedCell({ rowIndex: this.rowIndexAction, colIndex: this.colIndexAction });
  }

  @action scrollToCell() {
    this.dataGridApi.scrollToItem({
      rowIndex: this.rowIndexAction,
      columnIndex: this.colIndexAction,
      align: 'center'
    });
  }

  @action openCellPopover() {
    this.dataGridApi.openCellPopover({ rowIndex: this.rowIndexAction, colIndex: this.colIndexAction });
  }

  @action setFullScreen() {
    this.dataGridApi.setIsFullScreen(true);
  }

  <template>
    <EuiFlexGroup @alignItems="flexEnd" @gutterSize="s">
      <EuiFlexItem @grow={{false}} style="width: 80px">
        <EuiFormRow @label="Row index">
          <EuiFieldNumber
            min="0"
            max={{this.maxRowIndex}}
            @value={{this.rowIndexAction}}
            @compressed={{true}}
            {{on "input" this.setRowIndexAction}}
          />
        </EuiFormRow>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}} style="width: 80px">
        <EuiFormRow @label="Column index">
          <EuiFieldNumber
            min="0"
            max={{this.maxColIndex}}
            @value={{this.colIndexAction}}
            @compressed={{true}}
            {{on "input" this.setColIndexAction}}
          />
        </EuiFormRow>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" this.setCellFocus}}>Set cell focus</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" this.scrollToCell}}>Scroll to cell</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" this.openCellPopover}}>Open cell popover</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" this.setFullScreen}}>Set grid to fullscreen</EuiButton>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer />

    <EuiDataGrid
      aria-label="Data grid ref demo"
      @columns={{this.columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
      @inMemory={{hash level="sorting"}}
      @rowCount={{this.data.length}}
      @pagination={{hash
        pageIndex=this.pageIndex
        pageSize=this.pageSize
        onChangePage=this.onChangePage
        onChangeItemsPerPage=this.onChangePageSize
      }}
      @height={{400}}
      @registerApi={{this.registerApi}}
    >
      <:cell as |cell|>{{get (get this.data cell.rowIndex) cell.columnId}}</:cell>
    </EuiDataGrid>

    {{#if this.isModalVisible}}
      <EuiModal @onClose={{this.closeModal}} style="width: 500px">
        <EuiModalHeader>
          <EuiModalHeaderTitle>Example modal</EuiModalHeaderTitle>
        </EuiModalHeader>
        <EuiModalBody>
          <EuiText>
            <p>When closed, this modal should re-focus into the cell that toggled it.</p>
          </EuiText>
        </EuiModalBody>
        <EuiModalFooter>
          <EuiButton @fill={{true}} {{on "click" this.closeModal}}>Close</EuiButton>
        </EuiModalFooter>
      </EuiModal>
    {{/if}}
  </template>
}
```
