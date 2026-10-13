---
order: 10
---

# Inline scrolling (beta)

<EuiText>

`EuiBasicTable` supports inline (horizontal) scrolling on overflow, which
you enable with `@scrollableInline={{true}}`. It sets the minimum table
width to 100% and allows it to grow beyond that when the content cannot
fit the available space.

We recommend that all high-density tables have it enabled, so that they
can adjust to all screen resolutions and extend what
`@responsiveBreakpoint` provides on its own. Use the `width`, `minWidth`
and `maxWidth` options of the columns to adjust their sizes to the type of
data they display. For best results, never use container- or
viewport-relative length units (e.g., `%`, `vw` or `cqw`/`cqi`).

Enabling inline scrolling automatically switches `@tableLayout` to `auto`
because in that configuration the table's width depends on its cell
widths. See the [table layout guidelines](../table-layout-guidelines).

Keep the actions column visible at any scroll position with `sticky: true`
(it must be the last column), and consider turning on
`@stickyScrollbar={{true}}` so long tables can be scrolled without
reaching their bottom.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiHealth, EuiBasicTable } from '@ember-eui/core/components';
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

export default class BasicTableInlineScrolling extends Component {
  users = USERS.slice(0, 5);

  columns = [
    { field: 'firstName', name: 'First Name', minWidth: '10em' },
    { field: 'lastName', name: 'Last Name', minWidth: '12em' },
    { field: 'github', name: 'Github', minWidth: '10em' },
    {
      field: 'dateOfBirth',
      name: 'Date of Birth',
      dataType: 'date',
      minWidth: '14em',
      render: (dateOfBirth) => formatDate(dateOfBirth, 'dobLong'),
    },
    {
      field: 'location',
      name: 'Location',
      minWidth: '20em',
      render: (location) => `${location.city}, ${location.country}`,
    },
    { field: 'online', name: 'Online', minWidth: '8em', component: OnlineCell },
    {
      name: 'Actions',
      sticky: true,
      actions: [
        { name: 'Edit', description: 'Edit this user', type: 'icon', icon: 'pencil', onClick: () => {} },
        { name: 'Delete', description: 'Delete this user', type: 'icon', icon: 'trash', color: 'danger', onClick: () => {} },
      ],
    },
  ];

  <template>
    <EuiBasicTable
      @tableCaption="Demo of EuiBasicTable with inline scrolling"
      @responsiveBreakpoint={{false}}
      @scrollableInline={{true}}
      @stickyScrollbar={{true}}
      @items={{this.users}}
      @columns={{this.columns}}
    />
  </template>
}
```
