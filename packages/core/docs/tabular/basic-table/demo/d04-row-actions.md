---
order: 4
---

# Row actions

<EuiText>

An "actions" column defines actions for each row with `{ name, actions }`.
The most basic actions are `button` or `icon` types, but you can also
create custom actions: `{ component }` renders an Ember component that
receives the row's `@item` and whether the action is `@enabled`.

Actions follow these UI/UX rules:

- Only 2 actions can be visible per row. When you define more than two
  actions, the first 2 `isPrimary` actions stay visible, and all actions
  appear in a popover triggered by an ellipsis button.
- Actions become semi-transparent when you hover over the row. With more
  than 2 actions, only the ellipsis button stays visible at all times.
- When one or more rows are selected, all individual actions are disabled.
  Users should use bulk actions outside the table instead.

### Accessibility

`name` and `description` should be different. The name is a short
identifier, while the description should explain the purpose of the action
or provide hints. Both can be functions of the item:

```js
const action = {
  name: 'User profile',
  description: ({ firstName, lastName }) => `Visit ${firstName} ${lastName}'s profile`,
  // ...
};
```

If a meaningful description is not possible, setting the exact same string
for `name` and `description` makes the button's tooltip visual-only, so the
text is not announced to screen readers twice.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  EuiHealth,
  EuiLink,
  EuiBasicTable,
  EuiButton,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch,
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

// The users and the selection live outside the demo component, so the
// custom action components can change them too.
class UsersStore {
  @tracked users = USERS.slice(0, 5);
  @tracked selectedItems = [];
}
const store = new UsersStore();

const cloneUser = (user) => {
  const users = [...store.users];
  const index = users.findIndex(({ id }) => id === user.id);
  if (index >= 0) {
    const id = Math.max(...users.map(({ id }) => id)) + 1;
    users.splice(index, 0, { ...users[index], id });
    store.users = users;
  }
  store.selectedItems = [];
};

const deleteUsersByIds = (...ids) => {
  store.users = store.users.filter((user) => !ids.includes(user.id));
};

const deleteUser = (user) => {
  deleteUsersByIds(user.id);
  store.selectedItems = [];
};

const DeleteLink = <template>
  <EuiLink @color="danger" {{on "click" (fn deleteUser @item)}}>Delete</EuiLink>
</template>;

const CloneLink = <template>
  <EuiLink @color="success" {{on "click" (fn cloneUser @item)}}>Clone</EuiLink>
</template>;

const EditLink = <template><EuiLink>Edit</EuiLink></template>;

// `render` returns text; a `component` renders the cell's `@value`
const OnlineCell = <template>
  <EuiHealth @color={{if @value "success" "danger"}}>{{if @value "Online" "Offline"}}</EuiHealth>
</template>;

const columns = [
  {
    field: 'firstName',
    name: 'First Name',
    truncateText: true,
    sortable: true,
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
  },
];

export default class BasicTableActions extends Component {
  @tracked multiAction = false;
  @tracked customAction = false;

  store = store;

  get actions() {
    if (this.customAction) {
      let actions = [{ component: DeleteLink }];
      if (this.multiAction) {
        actions = [
          { ...actions[0], isPrimary: true, showOnHover: true },
          { component: CloneLink },
          { component: EditLink },
        ];
      }
      return actions;
    }

    let actions = [
      {
        name: 'User profile',
        description: ({ firstName, lastName }) => `Visit ${firstName} ${lastName}'s profile`,
        icon: 'editorLink',
        color: 'primary',
        type: 'icon',
        enabled: ({ online }) => !!online,
        href: ({ id }) => `${window.location.href}?id=${id}`,
        target: '_self',
        'data-test-subj': 'action-outboundlink',
      },
    ];
    if (this.multiAction) {
      actions = [
        {
          name: 'Clone',
          description: 'Clone this user',
          icon: 'copy',
          type: 'icon',
          onClick: cloneUser,
          'data-test-subj': 'action-clone',
        },
        {
          name: (user) => (user.id ? 'Delete' : 'Remove'),
          description: ({ firstName, lastName }) => `Delete ${firstName} ${lastName}`,
          icon: 'trash',
          color: 'danger',
          type: 'icon',
          onClick: deleteUser,
          isPrimary: true,
          'data-test-subj': ({ id }) => `action-delete-${id}`,
        },
        {
          name: 'Edit',
          isPrimary: true,
          available: ({ online }) => !online,
          enabled: ({ online }) => !!online,
          description: 'Edit this user',
          icon: 'pencil',
          type: 'icon',
          onClick: () => {},
          'data-test-subj': 'action-edit',
        },
        {
          name: 'Share',
          isPrimary: true,
          description: 'Share this user',
          icon: 'share',
          type: 'icon',
          onClick: () => {},
          'data-test-subj': 'action-share',
        },
        ...actions,
      ];
    }
    return actions;
  }

  get columnsWithActions() {
    return [...columns, { name: 'Actions', actions: this.actions }];
  }

  selection = {
    selectable: (user) => user.online,
    selectableMessage: (selectable, user) =>
      !selectable
        ? `${user.firstName} ${user.lastName} is currently offline`
        : `Select ${user.firstName} ${user.lastName}`,
    onSelectionChange: (selectedItems) => (store.selectedItems = selectedItems),
  };

  @action
  toggleMultiAction() {
    this.multiAction = !this.multiAction;
  }

  @action
  toggleCustomAction() {
    this.customAction = !this.customAction;
  }

  @action
  deleteSelectedUsers() {
    deleteUsersByIds(...store.selectedItems.map((user) => user.id));
    store.selectedItems = [];
  }

  <template>
    <EuiFlexGroup @alignItems="center" style="min-height: 48px">
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Multiple Actions"
          @checked={{this.multiAction}}
          @onChange={{this.toggleMultiAction}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Custom Actions"
          @checked={{this.customAction}}
          @onChange={{this.toggleCustomAction}}
        />
      </EuiFlexItem>
      <EuiFlexItem />
      {{#if this.store.selectedItems.length}}
        <EuiButton @color="danger" @iconType="trash" {{on "click" this.deleteSelectedUsers}}>
          Delete {{this.store.selectedItems.length}} Users
        </EuiButton>
      {{/if}}
    </EuiFlexGroup>

    <EuiSpacer @size="l" />

    <EuiBasicTable
      @tableCaption="Demo of EuiBasicTable with actions"
      @responsiveBreakpoint={{false}}
      @items={{this.store.users}}
      @itemId="id"
      @columns={{this.columnsWithActions}}
      @selection={{this.selection}}
    />
  </template>
}
```
