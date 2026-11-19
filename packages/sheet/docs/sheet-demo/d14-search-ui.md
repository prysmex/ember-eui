---
order: 14
---

# Sheet with EmberSearchUi

<EuiText>

`EuiSheetSearch` (from `@ember-eui/sheet/search-ui`) shows an
[EmberSearchUi](https://github.com/bengala-tech/ember-search-ui) driver's
results in a sheet. The driver owns the query: here 2,000 generated records
in memory (`memoryBackend`, with a 150 ms fake latency), 50 per page. The
sheet draws the driver's sort, page and search term, and sends the user's
sort and page changes back to it. Edits go to `@onChange`, which writes the
store: inserts land in the right place of the whole array, although the
sheet only saw one page, because each insert names its neighbour.

The toolbar is the app's own, here EUI controls bound to the same
driver: a search field (`driver.setQuery`), a sort select that reads and
sets `driver.state.sort`, and two filters that replace the driver's filter
tree. The demo subscribes to the driver (`driver.subscribe`) so the
controls follow changes made elsewhere, such as a sort from a column menu.
EmberSearchUi's own views (`ember-search-ui-views`) work here too, but
their stylesheet is light only and global (it also restyles EUI's combo
boxes on the page). The footer has the default pagination and a line
computed from the driver's result.

Try it:

- Sort by Name from its column menu (⋯): the driver sorts, the arrow
  shows, and the sort menu in the toolbar follows. Or pick a sort in the
  toolbar: the arrow follows.
- With Name sorted A-Z, edit the first name to `Zz`: the row stays where
  it is and **Re-apply** appears. Click it: the driver searches again and
  the row moves to where the sort puts it, the last page (40); go there to
  see it last.
- Search `ana`: the rows are filtered and the term is marked in the cells.
- Go to page 2: the row numbers continue from 51.
- Add a record from the last row ("+ Add record") and type a name: it shows
  at once; after Re-apply it is wherever the sort puts it (or on another
  page).
- Pick a status or a city in the filters: the driver filters, back to
  page 1.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { on } from '@ember/modifier';
import {
  EuiComboBox,
  EuiFieldSearch,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSelect,
  EuiText,
} from '@ember-eui/core/components';
import { applyChangeSet } from '@ember-eui/sheet';
import { EuiSheetSearch } from '@ember-eui/sheet/search-ui';
import {
  SearchDriver,
  defineProperty,
  memoryBackend,
  schemaFrom,
} from 'ember-search-ui-driver';

const STATUSES = [
  { value: 'todo', label: 'To do' },
  { value: 'doing', label: 'Doing' },
  { value: 'done', label: 'Done' },
];

const NAMES = ['Ana', 'Luis', 'Marta', 'Jorge', 'Sofía', 'Pablo', 'Elena', 'Diego'];
const CITIES = ['Monterrey', 'Madrid', 'Lima', 'Bogotá', 'Quito'];

const DOCS = Array.from({ length: 2000 }, (_, i) => ({
  id: `r${i + 1}`,
  name: `${NAMES[i % NAMES.length]} ${i + 1}`,
  status: STATUSES[(i * 7) % 3].value,
  city: CITIES[(i * 3) % CITIES.length],
  hours: (i * 13) % 41,
  start: `2026-${String(1 + (i % 12)).padStart(2, '0')}-${String(1 + ((i * 5) % 28)).padStart(2, '0')}`,
  active: i % 4 !== 0,
}));

// what the driver knows about each field (its schema)
const PROPERTIES = [
  defineProperty({ label: 'Name', field: { path: 'name', type: 'text' } }),
  defineProperty({ label: 'Status', field: { path: 'status', type: 'keyword', options: STATUSES } }),
  defineProperty({
    label: 'City',
    field: {
      path: 'city',
      type: 'keyword',
      options: CITIES.map((city) => ({ value: city, label: city })),
    },
  }),
  defineProperty({ label: 'Hours', field: { path: 'hours', type: 'number' } }),
  defineProperty({ label: 'Active', field: { path: 'active', type: 'boolean' } }),
];

// what the sheet shows and edits
const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  { id: 'status', label: 'Status', type: 'singleSelect', options: STATUSES },
  { id: 'city', label: 'City' },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'start', label: 'Start', type: 'date' },
  { id: 'active', label: 'Active', type: 'checkbox' },
];

// the toolbar's sort select: a key per sort, '' for none
const SORTS = {
  '': [],
  'name-asc': [{ field: 'name', direction: 'asc' }],
  'name-desc': [{ field: 'name', direction: 'desc' }],
  'hours-desc': [{ field: 'hours', direction: 'desc' }],
};
const SORT_OPTIONS = [
  { value: '', text: 'Unsorted' },
  { value: 'name-asc', text: 'Name A-Z' },
  { value: 'name-desc', text: 'Name Z-A' },
  { value: 'hours-desc', text: 'Most hours' },
];
const sortKey = (sort) => sort.map(({ field, direction }) => `${field}-${direction}`).join(',');

const STATUS_OPTIONS = STATUSES.map(({ value, label }) => ({ value, label }));
const CITY_OPTIONS = CITIES.map((city) => ({ value: city, label: city }));

const getId = (record) => record.id;

/** The app's data: a tracked array the driver reads at each search. */
class Store {
  @tracked docs = DOCS;
}

export default class SheetWithSearchUi extends Component {
  store = new Store();
  driver = new SearchDriver({
    backend: memoryBackend(() => this.store.docs, {
      latencyMs: 150,
      searchFields: ['name', 'city'],
    }),
    schema: schemaFrom(PROPERTIES),
    initialState: { page: { kind: 'offset', page: 1, perPage: 50 } },
  });
  // the driver's state and result, kept tracked so the toolbar and the footer follow them
  @tracked state = this.driver.state;
  @tracked result = this.driver.result;
  @tracked term = '';
  @tracked statuses = [];
  @tracked cities = [];

  constructor(owner, args) {
    super(owner, args);
    const unsubscribe = this.driver.subscribe((snapshot) => {
      if (snapshot.state !== this.state) this.state = snapshot.state;
      if (snapshot.result !== this.result) this.result = snapshot.result;
    });
    registerDestructor(this, () => {
      unsubscribe();
      this.driver.destroy();
    });
  }

  get sortOptions() {
    const key = sortKey(this.state.sort);
    // a sort from a column menu that the select does not list
    return key in SORTS ? SORT_OPTIONS : [...SORT_OPTIONS, { value: key, text: 'Custom (column menu)' }];
  }

  // "Showing 51–100 of 2,000", from the driver's page and the last result
  get pagingText() {
    const { page } = this.state;
    const { total, results } = this.result;
    if (!total) return 'No records';
    const from = (page.page - 1) * page.perPage + 1;
    return `Showing ${from}–${from + results.length - 1} of ${total.toLocaleString('en')}`;
  }

  get sortValue() {
    return sortKey(this.state.sort);
  }

  search = (term) => {
    this.term = term;
    this.driver.setQuery(term, { debounceMs: 200 });
  };

  setSort = (event) => {
    const sort = SORTS[event.target.value];
    if (sort) this.driver.setSort(sort);
  };

  setStatuses = (selected) => {
    this.statuses = selected;
    this.applyFilter();
  };

  setCities = (selected) => {
    this.cities = selected;
    this.applyFilter();
  };

  removeStatus = (option) => this.setStatuses(this.statuses.filter((o) => o !== option));
  removeCity = (option) => this.setCities(this.cities.filter((o) => o !== option));

  // one condition per filter with values, all of them together
  applyFilter() {
    const children = [
      ['status', this.statuses],
      ['city', this.cities],
    ]
      .filter(([, selected]) => selected.length)
      .map(([field, selected]) => ({
        kind: 'condition',
        field,
        operator: 'in',
        value: selected.map((option) => option.value),
      }));
    if (children.length) this.driver.replaceFilter({ kind: 'group', op: 'and', children });
    else this.driver.clearFilter();
  }

  // "persist" the change set: here, the in-memory store
  write = (changeSet) => {
    this.store.docs = applyChangeSet(this.store.docs, changeSet, { getRecordId: getId });
  };

  <template>
    <EuiSheetSearch
      @driver={{this.driver}}
      @getRecordId={{getId}}
      @onChange={{this.write}}
      @fields={{FIELDS}}
      @height={{420}}
    >
      <:toolbar>
        <EuiFlexGroup
          style='flex: 1 1 100%; min-width: 0'
          @gutterSize='s'
          @alignItems='center'
          @wrap={{true}}
          @responsive={{false}}
        >
          <EuiFlexItem style='min-width: 220px'>
            <EuiFieldSearch
              @placeholder='Search names and cities'
              @value={{this.term}}
              @incremental={{true}}
              @onSearch={{this.search}}
              @compressed={{true}}
              @fullWidth={{true}}
              aria-label='Search'
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}} style='min-width: 160px'>
            <EuiComboBox
              @options={{STATUS_OPTIONS}}
              @selectedOptions={{this.statuses}}
              @onChange={{this.setStatuses}}
              @removeTag={{this.removeStatus}}
              @searchField='label'
              @placeholder='Status'
              @compressed={{true}}
              aria-label='Status'
              as |option|
            >
              {{option.label}}
            </EuiComboBox>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}} style='min-width: 160px'>
            <EuiComboBox
              @options={{CITY_OPTIONS}}
              @selectedOptions={{this.cities}}
              @onChange={{this.setCities}}
              @removeTag={{this.removeCity}}
              @searchField='label'
              @placeholder='City'
              @compressed={{true}}
              aria-label='City'
              as |option|
            >
              {{option.label}}
            </EuiComboBox>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}} style='min-width: 170px'>
            <EuiSelect
              @options={{this.sortOptions}}
              @value={{this.sortValue}}
              @compressed={{true}}
              aria-label='Sort'
              {{on 'change' this.setSort}}
            />
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
      <:footer>
        <EuiText @size='s' @color='subdued'>
          {{this.pagingText}}
        </EuiText>
      </:footer>
    </EuiSheetSearch>
  </template>
}
```
