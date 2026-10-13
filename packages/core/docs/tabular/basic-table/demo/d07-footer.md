---
order: 7
---

# Adding a footer to a table

<EuiText>

Add a footer to your table by adding `footer` to your column definitions.
If one or more columns have a `footer`, the footer area appears. Columns
without a footer show an empty cell to keep the table layout consistent.

A footer is text (an `htmlSafe` string for markup), or a function that
receives `{ items, pagination }` and returns it. See the
[Table](../table) page for footers built from the low-level table
components.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';
import { EuiHealth, EuiBasicTable } from '@ember-eui/core/components';
import { array, hash } from '@ember/helper';

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

export default class BasicTableFooter extends Component {
  users = USERS.slice(0, 5);

  columns = [
    {
      field: 'firstName',
      name: 'First Name',
      footer: htmlSafe('<em>Page totals:</em>'),
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
      footer: ({ items }) => {
        const uniqueCountries = new Set(items.map((user) => user.location.country));
        return `${uniqueCountries.size} countries`;
      },
      render: (location) => `${location.city}, ${location.country}`,
    },
    {
      field: 'online',
      name: 'Online',
      footer: ({ items }) => `${items.filter((user) => !!user.online).length} online`,
      dataType: 'boolean',
      component: OnlineCell,
    },
  ];

  <template>
    <EuiBasicTable
      @tableCaption="Demo of EuiBasicTable with footer"
      @responsiveBreakpoint={{false}}
      @items={{this.users}}
      @itemId="id"
      @columns={{this.columns}}
      @selection={{hash initialSelected=(array)}}
    />
  </template>
}
```
