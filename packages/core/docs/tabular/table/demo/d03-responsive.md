---
order: 3
---

# Small screens

<EuiText>

Narrow the window: the rows become cards. `@mobileOptions` labels each
value (`header`), makes the name bigger (`enlarge`), and hides the email
there (`show: false`); `EuiTableSortMobile` replaces the header row.

</EuiText>

```hbs template
<EuiTableHeaderMobile>
  <EuiTableSortMobile @items={{this.sortItems}} />
</EuiTableHeaderMobile>
<EuiTable>
  <EuiTableHeader>
    <EuiTableHeaderCell>Name</EuiTableHeaderCell>
    <EuiTableHeaderCell @mobileOptions={{hash show=false}}>Email</EuiTableHeaderCell>
    <EuiTableHeaderCell>City</EuiTableHeaderCell>
  </EuiTableHeader>
  <EuiTableBody>
    {{#each this.sortedPeople as |person|}}
      <EuiTableRow>
        <EuiTableRowCell @mobileOptions={{hash header="Name" enlarge=true}}>{{person.name}}</EuiTableRowCell>
        <EuiTableRowCell @mobileOptions={{hash show=false}}>{{person.email}}</EuiTableRowCell>
        <EuiTableRowCell @mobileOptions={{hash header="City"}}>{{person.city}}</EuiTableRowCell>
      </EuiTableRow>
    {{/each}}
  </EuiTableBody>
</EuiTable>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class ResponsiveTable extends Component {
  @tracked ascending = true;

  people = [
    { name: 'Lina', email: 'lina@example.com', city: 'Oslo' },
    { name: 'Omar', email: 'omar@example.com', city: 'Cairo' },
    { name: 'Chen', email: 'chen@example.com', city: 'Taipei' },
  ];

  get sortedPeople() {
    const direction = this.ascending ? 1 : -1;

    return [...this.people].sort((a, b) => (a.name > b.name ? direction : -direction));
  }

  get sortItems() {
    return [
      {
        name: 'Name',
        isSorted: true,
        isSortAscending: this.ascending,
        onSort: () => (this.ascending = !this.ascending),
      },
    ];
  }
}
```
