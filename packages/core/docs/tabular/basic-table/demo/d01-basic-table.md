---
order: 1
---

# Basic table

<EuiText>

This example shows the basic `EuiBasicTable` setup with the required
`@items` and `@columns` arguments and some display options for each column.

Some columns display the value as-is (like `firstName` and `lastName`).
Other columns customize how the data appears before displaying it. You can
customize the display in two ways (and you can use both):

- **Data type hints**: tell the table what type of data you're showing (like
  the "Date of Birth" column using the `date` type). This adjusts the
  built-in formatting and alignment (for example, numbers become
  right-aligned, like in Excel).
- **Custom rendering**: a `render(value, item)` function returns the text
  to display (like the formatted "Date of Birth"), and a `component`
  renders an Ember component that receives `@value`, `@item` and `@column`
  (like the "Online" and "Github" columns).

If a column name needs a longer description, add an icon with a tooltip
using the column's `nameTooltip`. This keeps the icon visible even if the
text gets cut off. If the column header is sortable, the tooltip applies to
the entire cell instead of just the icon for better accessibility.

`@rowProps` and `@cellProps` add attributes, classes and event handlers
(like `onClick`) to rows and cells: pass an object, or a function of the
item (and column).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiHealth, EuiLink, EuiBasicTable } from '@ember-eui/core/components';
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

// `render` returns text; a `component` renders the cell's `@value`
const OnlineCell = <template>
  <EuiHealth @color={{if @value "success" "danger"}}>{{if @value "Online" "Offline"}}</EuiHealth>
</template>;

const GithubCell = <template><EuiLink @href="#" @target="_blank">{{@value}}</EuiLink></template>;

export default class BasicTableDemo extends Component {
  users = USERS.slice(0, 10);

  columns = [
    {
      field: 'firstName',
      name: 'First Name',
      'data-test-subj': 'firstNameCell',
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
      field: 'github',
      name: 'Github',
      nameTooltip: { content: 'Their mascot is the Octokitty' },
      component: GithubCell,
      truncateText: true,
    },
    {
      field: 'dateOfBirth',
      name: 'Date of Birth',
      dataType: 'date',
      render: (dateOfBirth) => formatDate(dateOfBirth, 'dobShort'),
    },
    {
      field: 'online',
      name: 'Online',
      dataType: 'boolean',
      component: OnlineCell,
    },
  ];

  getRowProps = (user) => ({
    'data-test-subj': `row-${user.id}`,
    className: 'customRowClass',
    onClick: () => {},
  });

  getCellProps = (user, column) => ({
    className: 'customCellClass',
    'data-test-subj': `cell-${user.id}-${String(column.field)}`,
  });

  <template>
    <EuiBasicTable
      @tableCaption="Demo of EuiBasicTable"
      @responsiveBreakpoint={{false}}
      @items={{this.users}}
      @rowHeader="firstName"
      @columns={{this.columns}}
      @rowProps={{this.getRowProps}}
      @cellProps={{this.getCellProps}}
    />
  </template>
}
```
