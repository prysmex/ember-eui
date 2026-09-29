---
order: 2
---

# Sorting, selection and pagination

<EuiText>

Everything is computed in the component: click a header to sort, check
rows to select them, and move between pages. The actions show while a
row is hovered.

</EuiText>

```hbs template
<EuiTable>
  <EuiTableHeader>
    <EuiTableHeaderCellCheckbox @width={{32}}>
      <EuiCheckbox
        aria-label="Select all rows on this page"
        @checked={{this.allSelected}}
        @indeterminate={{this.someSelected}}
        {{on "change" this.toggleAll}}
      />
    </EuiTableHeaderCellCheckbox>
    {{#each this.columns as |column|}}
      <EuiTableHeaderCell
        @align={{column.align}}
        @onSort={{fn this.sortBy column.field}}
        @isSorted={{eq this.sortField column.field}}
        @isSortAscending={{this.ascending}}
      >{{column.name}}</EuiTableHeaderCell>
    {{/each}}
    <EuiTableHeaderCell @width={{60}} />
  </EuiTableHeader>
  <EuiTableBody>
    {{#each this.pageRows key="id" as |row|}}
      <EuiTableRow @isSelected={{get this.selected row.id}} @isSelectable={{true}} @hasActions={{true}}>
        <EuiTableRowCellCheckbox>
          <EuiCheckbox
            aria-label="Select {{row.name}}"
            @checked={{get this.selected row.id}}
            {{on "change" (fn this.toggle row.id)}}
          />
        </EuiTableRowCellCheckbox>
        <EuiTableRowCell>{{row.name}}</EuiTableRowCell>
        <EuiTableRowCell>{{row.role}}</EuiTableRowCell>
        <EuiTableRowCell @align="right">{{row.age}}</EuiTableRowCell>
        <EuiTableRowCell @hasActions={{true}} @showOnHover={{true}} @textOnly={{false}}>
          <EuiButtonIcon @iconType="trash" @color="danger" aria-label="Delete {{row.name}}" />
        </EuiTableRowCell>
      </EuiTableRow>
    {{/each}}
  </EuiTableBody>
</EuiTable>
<EuiSpacer @size="m" />
<EuiTablePagination
  @activePage={{this.page}}
  @pageCount={{this.pageCount}}
  @itemsPerPage={{this.perPage}}
  @itemsPerPageOptions={{array 3 5 10}}
  @onChangePage={{this.goTo}}
  @onChangeItemsPerPage={{this.setPerPage}}
/>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const PEOPLE = [
  ['Ada', 'Engineer', 36], ['Alan', 'Researcher', 41], ['Grace', 'Admiral', 79],
  ['Linus', 'Maintainer', 28], ['Margaret', 'Director', 33], ['Dennis', 'Engineer', 42],
  ['Barbara', 'Professor', 50], ['Ken', 'Engineer', 39], ['Frances', 'Engineer', 45],
].map(([name, role, age], id) => ({ id, name, role, age }));

export default class SortablePagedTable extends Component {
  columns = [
    { field: 'name', name: 'Name' },
    { field: 'role', name: 'Role' },
    { field: 'age', name: 'Age', align: 'right' },
  ];

  @tracked sortField = 'name';
  @tracked ascending = true;
  @tracked selected = {};
  @tracked page = 0;
  @tracked perPage = 5;

  get sortedRows() {
    const direction = this.ascending ? 1 : -1;

    return [...PEOPLE].sort((a, b) =>
      a[this.sortField] > b[this.sortField] ? direction : -direction,
    );
  }

  get pageCount() {
    return Math.ceil(PEOPLE.length / this.perPage);
  }

  get pageRows() {
    return this.sortedRows.slice(this.page * this.perPage, (this.page + 1) * this.perPage);
  }

  get selectedOnPage() {
    return this.pageRows.filter((row) => this.selected[row.id]).length;
  }

  get allSelected() {
    return this.selectedOnPage === this.pageRows.length;
  }

  get someSelected() {
    return this.selectedOnPage > 0 && !this.allSelected;
  }

  @action
  sortBy(field) {
    this.ascending = this.sortField === field ? !this.ascending : true;
    this.sortField = field;
  }

  @action
  toggle(id) {
    this.selected = { ...this.selected, [id]: !this.selected[id] };
  }

  @action
  toggleAll() {
    const value = !this.allSelected;
    const selected = { ...this.selected };

    this.pageRows.forEach((row) => (selected[row.id] = value));
    this.selected = selected;
  }

  @action
  goTo(page) {
    this.page = page;
  }

  @action
  setPerPage(perPage) {
    this.perPage = perPage;
    this.page = 0;
  }
}
```
