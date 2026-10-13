---
order: 2
---

# Row selection

<EuiText>

This example sets up row selection with the `@selection` argument. For
automatic selection handling, where users control what gets selected, you
can set the initially selected items with `selection.initialSelected`. Use
`selection.onSelectionChange` to track or respond to user selections.
`selection.selectable` decides which rows can be selected and
`selection.selectableMessage` describes each checkbox.

For complete control over the selection, see the next example.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiHealth,
  EuiBasicTable,
  EuiButton,
  EuiFlexGroup,
  EuiSpacer,
} from '@ember-eui/core/components';
import { on } from '@ember/modifier';

const USERS = [
  ['Ada', 'Lovelace', 'adalove', [1991, 11, 10], true, 'London', 'United Kingdom'],
  ['Alan', 'Turing', 'enigma', [1994, 5, 23], false, 'Manchester', 'United Kingdom'],
  ['Grace', 'Hopper', 'gracehopper', [1986, 11, 9], true, 'Arlington', 'United States'],
  ['Linus', 'Torvalds', 'torvalds', [1999, 11, 28], true, 'Helsinki', 'Finland'],
  ['Margaret', 'Hamilton', 'mhamilton', [1996, 7, 17], false, 'Boston', 'United States'],
  ['Edsger', 'Dijkstra', 'ewd', [1980, 4, 11], true, 'Rotterdam', 'Netherlands'],
  ['Barbara', 'Liskov', 'bliskov', [1989, 10, 7], false, 'Los Angeles', 'United States'],
  ['Bjarne', 'Stroustrup', 'bjarne', [1990, 11, 30], true, 'Aarhus', 'Denmark'],
  ['Niklaus', 'Wirth', 'nwirth', [1984, 1, 15], false, 'Winterthur', 'Switzerland'],
  ['Yukihiro', 'Matsumoto', 'matz', [1995, 3, 14], true, 'Osaka', 'Japan'],
  ['James', 'Gosling', 'jgosling', [1985, 4, 19], true, 'Calgary', 'Canada'],
  ['Kristen', 'Nygaard', 'knygaard', [1987, 7, 27], false, 'Oslo', 'Norway'],
  ['Radia', 'Perlman', 'radia', [1993, 11, 18], true, 'Portsmouth', 'United States'],
  ['Roberto', 'Ierusalimschy', 'roberto', [1990, 4, 21], false, 'Rio de Janeiro', 'Brazil'],
  ['Guido', 'van Rossum', 'gvanrossum', [1996, 0, 31], true, 'Haarlem', 'Netherlands'],
  ['Karen', 'Spärck Jones', 'ksj', [1985, 7, 26], false, 'Huddersfield', 'United Kingdom'],
  ['Anders', 'Hejlsberg', 'ahejlsberg', [1990, 11, 2], true, 'Copenhagen', 'Denmark'],
  ['Hedy', 'Lamarr', 'hedy', [1984, 10, 9], false, 'Vienna', 'Austria'],
  ['Tim', 'Berners-Lee', 'timbl', [1995, 5, 8], true, 'London', 'United Kingdom'],
  ['Sophie', 'Wilson', 'sophiew', [1997, 5, 15], false, 'Leeds', 'United Kingdom'],
].map(([firstName, lastName, github, [year, month, day], online, city, country], i) => ({
  id: i + 1,
  firstName,
  lastName,
  github,
  dateOfBirth: new Date(year, month, day),
  online,
  location: { city, country },
}));

// `render` returns text; a `component` renders the cell's `@value`
const OnlineCell = <template>
  <EuiHealth @color={{if @value "success" "danger"}}>{{if @value "Online" "Offline"}}</EuiHealth>
</template>;

const columns = [
  {
    field: 'firstName',
    name: 'First Name',
    sortable: true,
    truncateText: true,
    mobileOptions: {
      render: (user) => `${user.firstName} ${user.lastName}`,
      header: false,
      truncateText: false,
      enlarge: true,
      width: '100%',
    },
  },
  {
    field: 'lastName',
    name: 'Last Name',
    truncateText: true,
    mobileOptions: { show: false },
  },
  {
    field: 'location',
    name: 'Location',
    truncateText: true,
    textOnly: true,
    render: (location) => `${location.city}, ${location.country}`,
  },
  {
    field: 'online',
    name: 'Online',
    dataType: 'boolean',
    component: OnlineCell,
    sortable: true,
    mobileOptions: { show: false },
  },
];

const selectableMessage = (selectable, user) =>
  !selectable
    ? `${user.firstName} ${user.lastName} is currently offline`
    : `Select ${user.firstName} ${user.lastName}`;
export default class BasicTableSelection extends Component {
  @tracked users = USERS.slice(0, 5);
  @tracked selectedItems = [];

  columns = columns;

  selection = {
    selectable: (user) => user.online,
    selectableMessage,
    onSelectionChange: (selectedItems) => (this.selectedItems = selectedItems),
    initialSelected: this.users.filter((user) => user.online),
  };

  get noneSelected() {
    return this.selectedItems.length === 0;
  }

  @action
  deleteSelectedUsers() {
    const ids = this.selectedItems.map((user) => user.id);
    this.users = this.users.filter((user) => !ids.includes(user.id));
    this.selectedItems = [];
  }

  <template>
    <EuiFlexGroup @alignItems="center" @justifyContent="spaceBetween">
      <EuiButton
        @color="danger"
        @iconType="trash"
        @isDisabled={{this.noneSelected}}
        {{on "click" this.deleteSelectedUsers}}
      >
        Delete {{if this.selectedItems.length this.selectedItems.length "selected"}} users
      </EuiButton>
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiBasicTable
      @tableCaption="Demo for an EuiBasicTable with uncontrolled selection"
      @responsiveBreakpoint={{false}}
      @items={{this.users}}
      @itemId="id"
      @rowHeader="firstName"
      @columns={{this.columns}}
      @selection={{this.selection}}
    />
  </template>
}
```
