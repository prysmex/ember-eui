---
order: 11
---

# Manual pagination

<EuiText>

`EuiBasicTable`'s `@pagination` and `@sorting` arguments _only_ control the
UI displayed on the table (like showing sorting arrows or pagination
numbers). They don't paginate or sort your `@items`: the table calls
`@onChange` with the new `{ page, sort }` criteria and you pass the
matching items.

This is mainly useful for large amounts of API-based data, where storing or
sorting all rows in memory would cause performance problems. Your API
backend should handle sorting, filtering, and caching your data
asynchronously. For smaller datasets (hundreds of items or less) that don't
use APIs, we recommend [EuiInMemoryTable](../in-memory-table), which
handles pagination, sorting, and searching in memory.

This example sets up pagination with the `@pagination` argument.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiHealth,
  EuiBasicTable,
  EuiCode,
  EuiHorizontalRule,
  EuiSpacer,
  EuiSwitch,
  EuiText,
} from '@ember-eui/core/components';
import { formatDate } from '@ember-eui/core/utils/eui/format';
import { not } from 'ember-truth-helpers';

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

export default class BasicTablePagination extends Component {
  users = USERS;

  @tracked pageIndex = 0;
  @tracked pageSize = 5;
  @tracked showPerPageOptions = true;

  columns = [
    {
      field: 'firstName',
      name: 'First Name',
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
      field: 'dateOfBirth',
      name: 'Date of Birth',
      dataType: 'date',
      render: (dateOfBirth) => formatDate(dateOfBirth, 'dobLong'),
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
    },
  ];

  get totalItemCount() {
    return this.users.length;
  }

  // Manually handle pagination of data
  get pageOfItems() {
    const { pageIndex, pageSize, users } = this;
    if (!pageIndex && !pageSize) {
      return users;
    }
    const startIndex = pageIndex * pageSize;
    return users.slice(startIndex, Math.min(startIndex + pageSize, users.length));
  }

  get firstShown() {
    return this.pageSize * this.pageIndex + 1;
  }

  get lastShown() {
    return this.pageSize * this.pageIndex + this.pageSize;
  }

  get pagination() {
    return {
      pageIndex: this.pageIndex,
      pageSize: this.pageSize,
      totalItemCount: this.totalItemCount,
      pageSizeOptions: [10, 0],
      showPerPageOptions: this.showPerPageOptions,
    };
  }

  @action
  onTableChange({ page }) {
    if (page) {
      this.pageIndex = page.index;
      this.pageSize = page.size;
    }
  }

  @action
  togglePerPageOptions() {
    this.showPerPageOptions = !this.showPerPageOptions;
  }

  <template>
    <EuiSwitch
      @checked={{not this.showPerPageOptions}}
      @onChange={{this.togglePerPageOptions}}
    >
      <:label>
        Hide per page options with
        <EuiCode>pagination.showPerPageOptions = false</EuiCode>
      </:label>
    </EuiSwitch>
    <EuiSpacer @size="xl" />
    <EuiText @size="xs">
      Showing
      {{#if this.pageSize}}
        <strong>{{this.firstShown}}-{{this.lastShown}}</strong> of {{this.totalItemCount}}
      {{else}}
        <strong>All</strong>
      {{/if}}
      <strong>Users</strong>
    </EuiText>
    <EuiSpacer @size="s" />
    <EuiHorizontalRule @margin="none" style="height: 2px" />
    <EuiBasicTable
      @tableCaption="Demo for EuiBasicTable with pagination"
      @responsiveBreakpoint={{false}}
      @items={{this.pageOfItems}}
      @columns={{this.columns}}
      @pagination={{this.pagination}}
      @onChange={{this.onTableChange}}
    />
  </template>
}
```
