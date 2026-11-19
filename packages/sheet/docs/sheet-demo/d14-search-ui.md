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

The toolbar holds EmberSearchUi's own views, bound to the same driver: a
search box, a sort menu, a filter bar and its chips. The footer has the
default pagination and EmberSearchUi's paging info.

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
- Filter by Status in the filter bar: the chips show the filter.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { EuiFlexGroup, EuiFlexItem, EuiText } from '@ember-eui/core/components';
import { applyChangeSet } from '@ember-eui/sheet';
import { EuiSheetSearch } from '@ember-eui/sheet/search-ui';
import {
  SearchDriver,
  defineProperty,
  memoryBackend,
  schemaFrom,
  searchUiCompat,
} from 'ember-search-ui-driver';
import { Search } from 'ember-search-ui';
import { FilterBar, FilterChips, PagingInfo, SearchBox, Sorting } from 'ember-search-ui-views';

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

// what the views and the driver know about each field
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

const SORT_OPTIONS = [
  { name: 'Unsorted', value: '', direction: '' },
  { name: 'Name A-Z', value: 'name', direction: 'asc' },
  { name: 'Name Z-A', value: 'name', direction: 'desc' },
  { name: 'Most hours', value: 'hours', direction: 'desc' },
];

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
  // the search-ui shaped API that SearchBox, Sorting and PagingInfo read
  compat = searchUiCompat(this.driver);

  constructor(owner, args) {
    super(owner, args);
    registerDestructor(this, () => this.driver.destroy());
  }

  // "persist" the change set: here, the in-memory store
  write = (changeSet) => {
    this.store.docs = applyChangeSet(this.store.docs, changeSet, { getRecordId: getId });
  };

  <template>
    <Search @driver={{this.driver}} as |search|>
      <EuiSheetSearch
        @driver={{this.driver}}
        @getRecordId={{getId}}
        @onChange={{this.write}}
        @fields={{FIELDS}}
        @height={{420}}
      >
        <:toolbar>
          <div style='flex: 1 1 100%; min-width: 0'>
            <EuiFlexGroup @gutterSize='m' @alignItems='center' @wrap={{true}} @responsive={{false}}>
              <EuiFlexItem style='min-width: 240px'>
                <SearchBox @driver={{this.compat}} @searchAsYouType={{true}} @debounceLength={{200}} />
              </EuiFlexItem>
              <EuiFlexItem @grow={{false}} style='min-width: 180px'>
                <Sorting @driver={{this.compat}} @sortOptions={{SORT_OPTIONS}} />
              </EuiFlexItem>
            </EuiFlexGroup>
            <FilterBar @search={{search}} @properties={{PROPERTIES}} />
            <FilterChips @search={{search}} @properties={{PROPERTIES}} />
          </div>
        </:toolbar>
        <:footer>
          <EuiText @size='s' @color='subdued'>
            <PagingInfo @driver={{this.compat}} />
          </EuiText>
        </:footer>
      </EuiSheetSearch>
    </Search>
  </template>
}
```
