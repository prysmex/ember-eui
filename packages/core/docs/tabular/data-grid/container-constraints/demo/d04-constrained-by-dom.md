---
order: 4
---

# Constrained by DOM

<EuiText>

Here the grid has no `@height` or `@width`: the resizable panel around it
constrains it, so it scrolls within its container and only renders the
visible cells.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { isDestroying } from '@ember/destroyable';
import { modifier } from 'ember-modifier';
import { array, get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import {
  EuiDataGrid,
  EuiLink,
  EuiResizableContainer,
  EuiText,
} from '@ember-eui/core/components';

const FIRST = ['Lorenzo', 'Adela', 'Celestino', 'Marlene', 'Dario', 'Ines', 'Rex', 'Nyah', 'Toby', 'Bridie', 'Elias', 'Mafalda'];
const LAST = ['Kertzmann', 'Hessel', 'Bauch', 'Wiza', 'Okuneva', 'Gleichner', 'Pacocha', 'Lindgren', 'Murazik', 'Feest', 'Hand'];
const SUFFIX = ['Jr.', 'Sr.', 'I', 'II', 'III', 'IV', 'V', 'MD', 'DDS', 'PhD', 'DVM'];
const CITIES = ['Port Isom', 'Lake Kianfort', 'Fort Gilberto', 'New Teagan', 'West Mabel', 'Schultzburgh', 'East Lorine'];
const COUNTRIES = ['Portugal', 'Kenya', 'Chile', 'Norway', 'Japan', 'Canada', 'Brazil', 'Sweden', 'Ireland'];

// deterministic stand-in for faker: the same row index always gets the same values
const pick = (rowIndex, salt, length) => ((rowIndex * 2654435761 + salt * 40503) >>> 0) % length;

function generateRow(rowIndex) {
  const first = FIRST[pick(rowIndex, 1, FIRST.length)];
  const last = LAST[pick(rowIndex, 2, LAST.length)];
  return {
    name: `${last}, ${first} ${SUFFIX[pick(rowIndex, 3, SUFFIX.length)]}`,
    email: `${first}.${last}${rowIndex}@example.com`.toLowerCase(),
    city: CITIES[pick(rowIndex, 4, CITIES.length)],
    country: COUNTRIES[pick(rowIndex, 5, COUNTRIES.length)],
    date: `${new Date(Date.UTC(2025, 9, 1) - pick(rowIndex, 6, 365 * 24 * 3600) * 1000)}`,
    account: String(pick(rowIndex, 7, 100000000)).padStart(8, '0'),
    amount: (pick(rowIndex, 8, 100000) / 100).toFixed(2),
    phone: `(${200 + pick(rowIndex, 9, 800)}) 555-${String(pick(rowIndex, 10, 10000)).padStart(4, '0')}`,
    version: `${pick(rowIndex, 11, 10)}.${pick(rowIndex, 12, 20)}.${pick(rowIndex, 13, 30)}`
  };
}

const columns = [
  { id: 'name', displayAsText: 'Name', defaultSortDirection: 'asc' },
  { id: 'email' },
  { id: 'location' },
  { id: 'account' },
  { id: 'date', defaultSortDirection: 'desc' },
  { id: 'amount' },
  { id: 'phone', isSortable: false },
  { id: 'version', defaultSortDirection: 'desc', initialWidth: 65, isResizable: false }
];

export default class ConstrainedByDomDemo extends Component {
  columns = columns;

  // values are generated when a cell first renders, not up front
  rawData = new Map();

  row = (rowIndex) => {
    if (!this.rawData.has(rowIndex)) this.rawData.set(rowIndex, generateRow(rowIndex));
    return this.rawData.get(rowIndex);
  };

  // count the mounted cells (a modifier runs when a cell's content is
  // inserted and cleans up when it is removed)
  @tracked mountedCellCount = 0;
  pendingCount = 0;
  isCountScheduled = false;

  countMountedCell = modifier(() => {
    this.adjustMountedCellCount(1);
    return () => this.adjustMountedCellCount(-1);
  });

  adjustMountedCellCount(adjustment) {
    this.pendingCount += adjustment;
    if (this.isCountScheduled) return;
    // batch the updates of one render into one change after it
    this.isCountScheduled = true;
    Promise.resolve().then(() => {
      this.isCountScheduled = false;
      if (isDestroying(this)) return;
      this.mountedCellCount += this.pendingCount;
      this.pendingCount = 0;
    });
  }

  // column visibility
  @tracked visibleColumns = columns.map(({ id }) => id);

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  // pagination
  @tracked pageIndex = 0;
  @tracked pageSize = 50;

  @action onChangeItemsPerPage(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }

  @action onChangePage(pageIndex) {
    this.pageIndex = pageIndex;
  }

  <template>
    <EuiText>
      <p>There are {{this.mountedCellCount}} rendered cells</p>
    </EuiText>

    <EuiResizableContainer style="height: 400px;" as |c|>
      <c.Panel @initialSize={{50}} @minSize="30%">
        <EuiDataGrid
          aria-label="Virtualized and constrained data grid demo"
          @columns={{this.columns}}
          @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
          @rowCount={{10000}}
          @pagination={{hash
            pageIndex=this.pageIndex
            pageSize=this.pageSize
            pageSizeOptions=(array 50 250 1000)
            onChangeItemsPerPage=this.onChangeItemsPerPage
            onChangePage=this.onChangePage
          }}
        >
          <:cell as |cell|>
            <span {{this.countMountedCell}}>
              {{#let (this.row cell.rowIndex) as |row|}}
                {{#if (eq cell.columnId "email")}}
                  <EuiLink @href="">{{row.email}}</EuiLink>
                {{else if (eq cell.columnId "location")}}
                  {{row.city}}, <EuiLink @href="https://google.com">{{row.country}}</EuiLink>
                {{else}}
                  {{get row cell.columnId}}
                {{/if}}
              {{/let}}
            </span>
          </:cell>
        </EuiDataGrid>
      </c.Panel>

      <c.Button />

      <c.Panel @initialSize={{50}} @minSize="200px">
        <EuiText>
          <p>
            This panel is constraining the datagrid. You can resize it using the
            drag handle and <strong>EuiDataGrid</strong> automatically detects
            the changes to its container size.
          </p>
        </EuiText>
      </c.Panel>
    </EuiResizableContainer>
  </template>
}
```
