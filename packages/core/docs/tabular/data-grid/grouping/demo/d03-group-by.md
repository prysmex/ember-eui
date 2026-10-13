---
order: 3
---

# Group by columns

<EuiText>

Choose the grouping. Sorting (the column actions or "Sort fields") orders
the groups and, with in-memory sorting, the rows inside each group;
pagination pages over the visible rows.

</EuiText>

```hbs template
<EuiButtonGroup
  @legend="Group by"
  @options={{this.groupOptions}}
  @idSelected={{this.groupById}}
  @onChange={{this.setGroupBy}}
  @buttonSize="compressed"
/>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Grouping demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @grouping={{hash groupBy=this.groupBy rows=this.rows defaultExpandedGroupIds="all"}}
  @inMemory={{hash level="sorting"}}
  @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
  @pagination={{hash
    pageIndex=this.pageIndex
    pageSize=this.pageSize
    pageSizeOptions=(array 10 25)
    onChangePage=this.onChangePage
    onChangeItemsPerPage=this.onChangeItemsPerPage
  }}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const GROUPINGS = {
  none: [],
  country: ['country'],
  countryCity: ['country', 'city']
};

const CITIES = [
  ['France', 'Paris'],
  ['France', 'Lyon'],
  ['Mexico', 'Monterrey'],
  ['Mexico', 'Guadalajara'],
  ['Japan', 'Osaka'],
  ['Japan', 'Tokyo']
];
const NAMES = ['Ana', 'Bo', 'Cy', 'Di', 'Ed', 'Flo', 'Gus', 'Hal', 'Ivy', 'Jo', 'Kim', 'Lu'];

export default class GroupByDemo extends Component {
  @tracked groupById = 'country';
  @tracked sortingColumns = [];
  @tracked pageIndex = 0;
  @tracked pageSize = 10;

  groupOptions = [
    { id: 'none', label: 'None' },
    { id: 'country', label: 'Country' },
    { id: 'countryCity', label: 'Country › City' }
  ];

  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 240 },
    { id: 'country', displayAsText: 'Country' },
    { id: 'city', displayAsText: 'City' },
    { id: 'sales', displayAsText: 'Sales', schema: 'numeric' }
  ];

  rows = NAMES.map((name, i) => {
    const [country, city] = CITIES[(i * 5) % CITIES.length];
    return { name, country, city, sales: String(((i * 37) % 90) + 10) };
  });

  get groupBy() {
    return GROUPINGS[this.groupById];
  }

  @action setGroupBy(id) {
    this.groupById = id;
    this.pageIndex = 0;
  }

  @action onSort(columns) {
    this.sortingColumns = columns;
  }

  @action onChangePage(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action onChangeItemsPerPage(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }
}
```
