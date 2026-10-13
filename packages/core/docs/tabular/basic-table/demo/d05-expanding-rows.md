---
order: 5
---

# Expanding rows

<EuiText>

You can expand rows by passing an `@itemIdToExpandedRowMap`: the rows whose
ids are keys of the map are expanded, and the `<:expandedRow>` block renders
their content (it yields the item, its id and the map's value; a text value
is shown as-is without the block). When building your table manually (not
using `EuiBasicTable`), add `@isExpandedRow={{true}}` to the row that will
be revealed.

Here the toggle column's component receives the column as `@column`, so the
column object carries the expanded map and the toggle action.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { array, fn, get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  EuiButtonIcon,
  EuiHealth,
  EuiToolTip,
  EuiBasicTable,
  EuiDescriptionList,
  EuiDescriptionListDescription,
  EuiDescriptionListTitle,
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

const ExpandToggle = <template>
  {{#let (if (get @column.expandedMap @item.id) "Collapse" "Expand") as |label|}}
    <EuiToolTip @content={{label}} @disableScreenReaderOutput={{true}}>
      <EuiButtonIcon
        aria-label={{label}}
        @iconType={{if (get @column.expandedMap @item.id) "arrowDown" "arrowRight"}}
        {{on "click" (fn @column.onToggle @item)}}
      />
    </EuiToolTip>
  {{/let}}
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
  },
  {
    name: 'Actions',
    actions: [
      {
        name: 'Clone',
        description: 'Clone this person',
        type: 'icon',
        icon: 'copy',
        onClick: () => '',
      },
    ],
  },
];

export default class BasicTableExpandingRows extends Component {
  users = USERS.slice(0, 5);

  @tracked itemIdToExpandedRowMap = {};

  @action
  toggleDetails(user) {
    const itemIdToExpandedRowMapValues = { ...this.itemIdToExpandedRowMap };
    if (itemIdToExpandedRowMapValues[user.id]) {
      delete itemIdToExpandedRowMapValues[user.id];
    } else {
      itemIdToExpandedRowMapValues[user.id] = true;
    }
    this.itemIdToExpandedRowMap = itemIdToExpandedRowMapValues;
  }

  get columnsWithExpandingRowToggle() {
    return [
      ...columns,
      {
        align: 'right',
        width: '40px',
        isExpander: true,
        // no visible header text; `description` is read by screen readers
        name: '',
        description: 'Expand row',
        mobileOptions: { header: false },
        component: ExpandToggle,
        expandedMap: this.itemIdToExpandedRowMap,
        onToggle: this.toggleDetails,
      },
    ];
  }

  <template>
    <EuiBasicTable
      @tableCaption="Demo of EuiBasicTable with expanding rows"
      @responsiveBreakpoint={{false}}
      @items={{this.users}}
      @itemId="id"
      @itemIdToExpandedRowMap={{this.itemIdToExpandedRowMap}}
      @columns={{this.columnsWithExpandingRowToggle}}
      @selection={{hash initialSelected=(array)}}
    >
      <:expandedRow as |user|>
        <EuiDescriptionList>
          <EuiDescriptionListTitle>Location</EuiDescriptionListTitle>
          <EuiDescriptionListDescription>
            {{user.location.city}}, {{user.location.country}}
          </EuiDescriptionListDescription>
          <EuiDescriptionListTitle>Online</EuiDescriptionListTitle>
          <EuiDescriptionListDescription>
            <EuiHealth @color={{if user.online "success" "danger"}}>
              {{if user.online "Online" "Offline"}}
            </EuiHealth>
          </EuiDescriptionListDescription>
        </EuiDescriptionList>
      </:expandedRow>
    </EuiBasicTable>
  </template>
}
```
