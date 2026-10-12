---
order: 2
---

# Sorting, pagination and selection

<EuiText>

The table calls `@onChange` with the next sort and page; the component
sorts and slices the items. Selected rows disable the row actions.

</EuiText>

```hbs template
<EuiText @size="s"><p>{{this.selected.length}} selected</p></EuiText>
<EuiSpacer @size="s" />
<EuiBasicTable
  @items={{this.pageOfItems}}
  @itemId="id"
  @columns={{this.columns}}
  @pagination={{this.pagination}}
  @sorting={{this.sorting}}
  @selection={{this.selection}}
  @onChange={{this.onTableChange}}
  @panelled={{true}}
/>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const NAMES = ['Ada', 'Alan', 'Grace', 'Linus', 'Margaret', 'Dennis', 'Barbara', 'Ken', 'Frances', 'Edsger', 'Donald', 'Radia'];
const PEOPLE = NAMES.map((name, id) => ({ id, name, age: 25 + ((id * 7) % 40), online: id % 3 !== 0 }));

export default class BasicTableControlled extends Component {
  @tracked pageIndex = 0;
  @tracked pageSize = 5;
  @tracked sortField = 'name';
  @tracked sortDirection = 'asc';
  @tracked selected = [];

  columns = [
    { field: 'name', name: 'Name', sortable: true, truncateText: true },
    { field: 'age', name: 'Age', dataType: 'number', sortable: true },
    { field: 'online', name: 'Online', dataType: 'boolean' },
    {
      name: 'Actions',
      actions: [
        { name: 'Email', description: 'Email this person', type: 'icon', icon: 'email', onClick: () => {} },
        { name: 'Remove', description: 'Remove this person', type: 'icon', icon: 'trash', color: 'danger', onClick: () => {} },
      ],
    },
  ];

  selection = {
    selectable: (person) => person.online,
    selectableMessage: (selectable) => (selectable ? undefined : 'Offline people cannot be selected'),
    onSelectionChange: (selected) => (this.selected = selected),
  };

  get sorting() {
    return { sort: { field: this.sortField, direction: this.sortDirection } };
  }

  get pagination() {
    return { pageIndex: this.pageIndex, pageSize: this.pageSize, totalItemCount: PEOPLE.length, pageSizeOptions: [3, 5, 0] };
  }

  get pageOfItems() {
    const sorted = [...PEOPLE].sort((a, b) => {
      const result = a[this.sortField] > b[this.sortField] ? 1 : a[this.sortField] < b[this.sortField] ? -1 : 0;
      return this.sortDirection === 'asc' ? result : -result;
    });
    return this.pageSize ? sorted.slice(this.pageIndex * this.pageSize, (this.pageIndex + 1) * this.pageSize) : sorted;
  }

  @action
  onTableChange({ page, sort }) {
    if (page) {
      this.pageIndex = page.index;
      this.pageSize = page.size;
    }
    if (sort) {
      this.sortField = sort.field;
      this.sortDirection = sort.direction;
    }
  }
}
```
