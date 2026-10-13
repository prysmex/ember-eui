---
order: 3
---

# Table selection: controlled

<EuiText>

To completely control the selection, pass `selection.selected` instead
(which requires `selection.onSelectionChange`). This can be useful if you
want to handle selections based on user interaction with another part of
the UI, like the "Select online users" button.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { or } from 'ember-truth-helpers';
import {
  EuiButton,
  EuiEmptyPrompt,
  EuiHealth,
  EuiInMemoryTable,
  EuiSpacer,
  EuiText,
  EuiTitle,
} from '@ember-eui/core/components';

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

const userData = USERS;

const noItemsFoundMsg = 'No users match search criteria';

export default class InMemoryTableControlledSelection extends Component {
  @tracked users = [];
  @tracked selectedItems = [];
  // `null` shows the "No users" prompt
  @tracked message = null;
  @tracked error;
  @tracked loading = false;

  columns = columns;
  timeout;

  get selection() {
    return {
      selectable: (user) => user.online,
      selectableMessage,
      onSelectionChange: (selectedItems) => (this.selectedItems = selectedItems),
      selected: this.selectedItems,
    };
  }

  search = {
    box: { incremental: true },
    filters: [
      { type: 'is', field: 'online', name: 'Online' },
      {
        type: 'field_value_selection',
        field: 'location.country',
        name: 'Country',
        multiSelect: false,
        options: [...new Set(userData.map(({ location: { country } }) => country))].map(
          (country) => ({ value: country })
        ),
      },
    ],
  };

  pagination = {
    initialPageSize: 5,
    pageSizeOptions: [3, 5, 8],
  };

  get noneSelected() {
    return this.selectedItems.length === 0;
  }

  get noUsers() {
    return this.users.length === 0;
  }

  load(users, error) {
    this.message = 'Loading users...';
    this.loading = true;
    this.users = [];
    this.error = undefined;
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.loading = false;
      this.message = noItemsFoundMsg;
      this.error = error;
      this.users = users;
    }, 1000);
  }

  @action
  loadUsers() {
    this.load(userData);
  }

  @action
  loadUsersWithError() {
    this.load([], 'ouch!... again... ');
  }

  @action
  selectOnlineUsers() {
    this.selectedItems = this.users.filter((user) => user.online);
  }

  @action
  deleteUsers() {
    const ids = this.selectedItems.map((user) => user.id);
    this.users = this.users.filter((user) => !ids.includes(user.id));
    this.selectedItems = [];
  }

  willDestroy() {
    super.willDestroy();
    clearTimeout(this.timeout);
  }

  <template>
    <EuiInMemoryTable
      @tableCaption="Demo for an EuiInMemoryTable with controlled selection"
      @responsiveBreakpoint={{false}}
      @items={{this.users}}
      @itemId="id"
      @rowHeader="firstName"
      @error={{this.error}}
      @loading={{this.loading}}
      @search={{this.search}}
      @sorting={{true}}
      @pagination={{this.pagination}}
      @columns={{this.columns}}
      @selection={{this.selection}}
    >
      <:toolsLeft>
        <EuiButton
          @isDisabled={{or this.loading this.noUsers}}
          {{on "click" this.selectOnlineUsers}}
        >
          Select online users
        </EuiButton>
        <EuiButton
          @color="danger"
          @iconType="trash"
          @isDisabled={{this.noneSelected}}
          {{on "click" this.deleteUsers}}
        >
          Delete {{this.selectedItems.length}} users
        </EuiButton>
      </:toolsLeft>
      <:toolsRight>
        <EuiButton @isDisabled={{this.loading}} {{on "click" this.loadUsers}}>
          Load users
        </EuiButton>
        <EuiButton @isDisabled={{this.loading}} {{on "click" this.loadUsersWithError}}>
          Load users (Error)
        </EuiButton>
      </:toolsRight>
      <:noItemsMessage>
        {{#if this.message}}
          {{this.message}}
        {{else}}
          <EuiEmptyPrompt>
            <:content>
              <EuiTitle @size="xs"><h3>No users</h3></EuiTitle>
              <EuiSpacer @size="s" />
              <EuiText @color="subdued">
                Looks like you don’t have any users. Let’s create some!
              </EuiText>
              <EuiSpacer @size="l" />
              <EuiButton @size="s" {{on "click" this.loadUsers}}>Load users</EuiButton>
            </:content>
          </EuiEmptyPrompt>
        {{/if}}
      </:noItemsMessage>
    </EuiInMemoryTable>
  </template>
}
```
