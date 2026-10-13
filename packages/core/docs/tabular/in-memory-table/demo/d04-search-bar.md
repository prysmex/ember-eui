---
order: 4
---

# Search bar

<EuiText>

Pass `@search` to display a search bar. For more about the syntax and the
options it accepts, see [EuiSearchBar](../../forms/search-bar).
`box: { schema: true }` builds a strict schema from the columns' `field` and
`dataType`, so unknown fields and wrong types are errors.

With `@searchFormat="text"` the search matches the text as typed (no search
syntax or filters), so reserved characters such as `"`, `(` or `:` need no
escaping. The `<:childrenBetween>` block injects content between the
search bar and the table.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { and, not } from 'ember-truth-helpers';
import {
  EuiCallOut,
  EuiCode,
  EuiFlexGroup,
  EuiHealth,
  EuiInMemoryTable,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';
import { formatDate } from '@ember-eui/core/utils/eui/format';

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

const SYMBOLS = ['(){}[]', '#@!:*', '<>?\\/', '+-=&%', '$^~`|'];
const EMOJIS = ['🦄', '🐙', '🚀', '🌮', '🎉'];

const users = USERS.map(({ location, ...user }) => ({ ...user, location: location.country }));
const usersWithSpecialCharacters = users.map((user, i) => ({
  ...user,
  firstName: `${user.firstName} "${SYMBOLS[i % SYMBOLS.length]}"`,
  lastName: `${user.lastName} ${EMOJIS[i % EMOJIS.length]}`,
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

export default class InMemoryTableSearchBar extends Component {
  @tracked incremental = false;
  @tracked filters = false;
  @tracked contentBetween = false;
  @tracked textSearchFormat = false;

  columns = columns;

  get items() {
    return this.textSearchFormat ? usersWithSpecialCharacters : users;
  }

  get search() {
    return {
      box: { incremental: this.incremental, schema: true },
      filters: !this.filters
        ? undefined
        : [
            { type: 'is', field: 'online', name: 'Online', negatedName: 'Offline' },
            {
              type: 'field_value_selection',
              field: 'location',
              name: 'Location',
              multiSelect: false,
              options: [...new Set(users.map(({ location }) => location))].map((location) => ({
                value: location,
              })),
            },
          ],
    };
  }

  toggle = (name) => () => (this[name] = !this[name]);

  toggleIncremental = this.toggle('incremental');
  toggleFilters = this.toggle('filters');
  toggleContentBetween = this.toggle('contentBetween');
  toggleTextSearchFormat = this.toggle('textSearchFormat');

  <template>
    <EuiFlexGroup>
      <EuiSwitch
        @label="Incremental"
        @checked={{this.incremental}}
        @onChange={{this.toggleIncremental}}
      />
      <EuiSwitch
        @label="With Filters"
        @checked={{and this.filters (not this.textSearchFormat)}}
        @onChange={{this.toggleFilters}}
        @disabled={{this.textSearchFormat}}
      />
      <EuiSwitch
        @label="Content between"
        @checked={{this.contentBetween}}
        @onChange={{this.toggleContentBetween}}
      />
      <EuiSwitch
        @label="Plain text search"
        @checked={{this.textSearchFormat}}
        @onChange={{this.toggleTextSearchFormat}}
      />
    </EuiFlexGroup>
    <EuiSpacer @size="l" />
    <EuiInMemoryTable
      @tableCaption="Demo of EuiInMemoryTable with search"
      @responsiveBreakpoint={{false}}
      @items={{this.items}}
      @columns={{this.columns}}
      @search={{this.search}}
      @searchFormat={{if this.textSearchFormat "text" "eql"}}
      @pagination={{true}}
      @sorting={{true}}
    >
      <:childrenBetween>
        {{#if this.contentBetween}}
          <EuiCallOut @size="s">
            <:title>
              You can inject custom content between the search bar and the table
              using the <EuiCode>&lt;:childrenBetween&gt;</EuiCode> block.
            </:title>
          </EuiCallOut>
        {{/if}}
      </:childrenBetween>
    </EuiInMemoryTable>
  </template>
}
```
