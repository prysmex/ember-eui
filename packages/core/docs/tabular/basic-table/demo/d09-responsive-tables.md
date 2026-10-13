---
order: 9
---

# Responsive tables

<EuiText>

Tables are mobile-responsive by default, breaking down each row into its
own card section and showing each table header above the cell contents.
The default breakpoint where the table switches to cards is the `m` window
size, which you can customize with the `@responsiveBreakpoint` argument
(like `@responsiveBreakpoint="s"`).

To never make your table responsive (for tables with very few columns),
set `@responsiveBreakpoint={{false}}`. To always render your table in a
mobile-friendly way, pass `true`. The example below switches between
`true` and `false` for an easy preview of the mobile and desktop layouts
at all breakpoints.

To customize how your cells look in the mobile vs. desktop view, use the
columns' `mobileOptions` (`{ render, component, header, show, only,
enlarge, truncateText, width }`). You can also pass `@mobileOptions` to an
`EuiTableRowCell` directly.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiHealth,
  EuiLink,
  EuiBasicTable,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';
import { formatDate } from '@ember-eui/core/utils/eui/format';
import { array, hash } from '@ember/helper';
import { and, not } from 'ember-truth-helpers';

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

const GithubCell = <template><EuiLink @href="#" @target="_blank">{{@value}}</EuiLink></template>;

export default class BasicTableResponsive extends Component {
  @tracked users = USERS.slice(0, 3);
  @tracked customHeader = true;
  @tracked isResponsive = true;

  get columns() {
    const { customHeader, isResponsive } = this;
    return [
      {
        field: 'firstName',
        name: 'First Name',
        truncateText: true,
        sortable: true,
        mobileOptions: {
          render: customHeader ? (user) => `${user.firstName} ${user.lastName}` : undefined,
          header: customHeader ? false : true,
          width: customHeader ? '100%' : undefined,
          enlarge: customHeader ? true : false,
          truncateText: customHeader ? false : true,
        },
      },
      {
        field: 'lastName',
        name: 'Last Name',
        truncateText: true,
        mobileOptions: { show: !isResponsive || !customHeader },
      },
      { field: 'github', name: 'Github', component: GithubCell },
      {
        field: 'dateOfBirth',
        name: 'Date of Birth',
        dataType: 'date',
        render: (dateOfBirth) => formatDate(dateOfBirth, 'dobLong'),
        sortable: true,
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
      {
        name: 'Mobile only',
        mobileOptions: {
          only: true,
          render: () => 'This column only appears on mobile',
        },
      },
      {
        name: 'Actions',
        actions: [
          {
            name: 'Clone',
            description: 'Clone this person',
            icon: 'copy',
            type: 'icon',
            onClick: this.cloneUser,
          },
          {
            name: 'Delete',
            description: 'Delete this person',
            icon: 'trash',
            type: 'icon',
            color: 'danger',
            onClick: this.deleteUser,
          },
        ],
      },
    ];
  }

  @action
  cloneUser(user) {
    const users = [...this.users];
    const index = users.findIndex(({ id }) => id === user.id);
    const id = Math.max(...users.map(({ id }) => id)) + 1;
    users.splice(index, 0, { ...user, id });
    this.users = users;
  }

  @action
  deleteUser(user) {
    this.users = this.users.filter(({ id }) => id !== user.id);
  }

  @action
  toggleResponsive() {
    this.isResponsive = !this.isResponsive;
  }

  @action
  toggleCustomHeader() {
    this.customHeader = !this.customHeader;
  }

  <template>
    <EuiFlexGroup @alignItems="center" @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Responsive"
          @checked={{this.isResponsive}}
          @onChange={{this.toggleResponsive}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Custom header"
          @disabled={{not this.isResponsive}}
          @checked={{and this.isResponsive this.customHeader}}
          @onChange={{this.toggleCustomHeader}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>

    <EuiSpacer @size="l" />

    <EuiBasicTable
      @tableCaption="Demo for responsive EuiBasicTable with mobile options"
      @items={{this.users}}
      @itemId="id"
      @columns={{this.columns}}
      @selection={{hash initialSelected=(array)}}
      @responsiveBreakpoint={{this.isResponsive}}
    />
  </template>
}
```
