---
order: 6
---

# External state

<EuiText>

This example uses both external and internal search/filter state: the
facets set a controlled `search.query`, and `search.onChange` keeps it in
sync with what users type or pick in the filters.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';
import {
  EuiFacetButton,
  EuiFacetGroup,
  EuiFlexGroup,
  EuiFlexItem,
  EuiHealth,
  EuiInMemoryTable,
} from '@ember-eui/core/components';

const countries = [
  { code: 'NL', name: 'Netherlands', flag: '🇳🇱' },
  { code: 'CZ', name: 'Czech Republic', flag: '🇨🇿' },
  { code: 'ZA', name: 'South Africa', flag: '🇿🇦' },
  { code: 'US', name: 'United States', flag: '🇺🇲' },
  { code: 'AU', name: 'Australia', flag: '🇦🇺' },
  { code: 'IL', name: 'Israel', flag: '🇮🇱' },
  { code: 'NO', name: 'Norway', flag: '🇳🇴' },
  { code: 'IT', name: 'Italy', flag: '🇮🇹' },
  { code: 'CA', name: 'Canada', flag: '🇨🇦' },
  { code: 'CG', name: 'Congo', flag: '🇨🇬' },
  { code: 'CL', name: 'Chile', flag: '🇨🇱' },
  { code: 'FJ', name: 'Fiji', flag: '🇫🇯' },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧' },
  { code: 'GR', name: 'Greece', flag: '🇬🇷' },
  { code: 'HT', name: 'Haiti', flag: '🇭🇹' },
  { code: 'LB', name: 'Lebanon', flag: '🇱🇧' },
  { code: 'MM', name: 'Myanmar', flag: '🇲🇲' },
  { code: 'MX', name: 'Mexico', flag: '🇲🇽' },
  { code: 'NG', name: 'Nigeria', flag: '🇳🇬' },
  { code: 'SG', name: 'Singapore', flag: '🇸🇬' },
  { code: 'SO', name: 'Somalia', flag: '🇸🇴' },
  { code: 'TN', name: 'Tunisia', flag: '🇹🇳' },
  { code: 'VE', name: 'Venezuela', flag: '🇻🇪' },
  { code: 'ZM', name: 'Zambia', flag: '🇿🇲' },
];

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

const users = USERS.map(({ id, firstName, lastName, online }) => {
  const country = countries[(id * 7) % countries.length];
  return { id, firstName, lastName, online, location: country.code, locationData: country };
});

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
    render: (_, user) => `${user.locationData.flag} ${user.locationData.name}`,
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

const facets = [
  { id: 'eu', label: 'Europe', query: 'location:(NL or CZ or NO or IT or GB or GR)' },
  { id: 'na', label: 'North America', query: 'location:(US or CA or MX or HT)' },
  { id: 'oc', label: 'Oceania', query: 'location:(AU or FJ)' },
  { id: 'as', label: 'Asia', query: 'location:(IL or LB)' },
  { id: 'af', label: 'Africa', query: 'location:(ZA or CG)' },
  { id: 'sa', label: 'South America', query: 'location:(CL)' },
];

export default class InMemoryTableExternalState extends Component {
  @tracked query = '';
  @tracked selectedOptionId = '';

  users = users;
  columns = columns;
  facets = facets;

  handleOnChange = ({ queryText, error }) => {
    this.selectedOptionId = '';
    if (!error) {
      this.query = queryText;
    }
  };

  selectFacet = (facet) => {
    this.selectedOptionId = facet.id;
    this.query = facet.query;
  };

  get search() {
    return {
      query: this.query,
      onChange: this.handleOnChange,
      box: { schema: true },
      filters: [
        { type: 'is', field: 'online', name: 'Online', negatedName: 'Offline' },
        {
          type: 'field_value_selection',
          field: 'location',
          name: 'Location',
          multiSelect: 'or',
          options: countries.map((country) => ({
            value: country.code,
            name: country.name,
            label: `${country.flag} ${country.name}`,
          })),
        },
      ],
    };
  }

  <template>
    <EuiFlexGroup>
      <EuiFlexItem @grow={{1}}>
        <EuiFacetGroup>
          {{#each this.facets as |facet|}}
            <EuiFacetButton
              id={{facet.id}}
              @isSelected={{eq this.selectedOptionId facet.id}}
              {{on "click" (fn this.selectFacet facet)}}
            >
              {{facet.label}}
            </EuiFacetButton>
          {{/each}}
        </EuiFacetGroup>
      </EuiFlexItem>
      <EuiFlexItem @grow={{3}}>
        <EuiInMemoryTable
          @tableCaption="Demo of EuiInMemoryTable with search and external state"
          @responsiveBreakpoint={{false}}
          @items={{this.users}}
          @columns={{this.columns}}
          @search={{this.search}}
          @pagination={{true}}
          @sorting={{true}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
