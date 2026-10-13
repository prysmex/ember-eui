---
order: 3
---

# Virtualization

<EuiText>

Creating a lot of DOM nodes is computationally expensive, and
**EuiDataGrid** uses a couple wrapping divs to build each cell. To help
offset the cost of larger tables, cell virtualization can be opted into by
constraining the grid's height and/or width. There are two ways to enable
this functionality. First, `@height` and/or `@width` can be passed as
arguments, which are applied to the grid's container style. Alternatively,
if **EuiDataGrid** is unable to render at the full dimensions it needs due
to screen real estate or other DOM constraints, it will overflow within a
scrollable container and only render the visible cells.

Only the visible rows and columns, plus `virtualizationOptions.overscanRowCount`
and `overscanColumnCount` extra ones (1 by default), are rendered.

<EuiCallOut @title="Never toggle the height between a value and undefined." @color="warning" @size="s">
  <p>
    <strong>EuiDataGrid</strong> does not accommodate for its height
    switching to or from <code>undefined</code>. For demonstration
    purposes, the example below wraps the grid in an
    <code>\{{#each}}</code> keyed by "constrained" or "unconstrained" to
    force it to completely re-render when its height changes between
    constrained and unconstrained heights.
  </p>
</EuiCallOut>

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
  EuiButtonGroup,
  EuiDataGrid,
  EuiFormRow,
  EuiLink,
  EuiSpacer,
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

export default class VirtualizationDemo extends Component {
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

  rowHeightsOptions = { defaultHeight: 'auto', scrollAnchorRow: 'start' };

  // dimensions
  dimensionSizes = {
    'height-300px': 300,
    'height-600px': 600,

    'width-200px': 200,
    'width-50%': '50%',
    'width-unconstrained': undefined
  };

  heightOptions = [
    { id: 'height-300px', label: '300px' },
    { id: 'height-600px', label: '600px' },
    { id: 'height-unconstrained', label: 'Unconstrained' }
  ];

  widthOptions = [
    { id: 'width-200px', label: '200px' },
    { id: 'width-50%', label: '50%' },
    { id: 'width-unconstrained', label: 'Unconstrained' }
  ];

  @tracked height = 'height-300px';
  @tracked width = 'width-50%';

  get heightMode() {
    return this.height === 'height-unconstrained' ? 'unconstrained' : 'constrained';
  }

  @action setHeight(height) {
    this.height = height;
  }

  @action setWidth(width) {
    this.width = width;
  }

  <template>
    <EuiFormRow @label="Height">
      <EuiButtonGroup
        @legend="Set a height for the following grid"
        @options={{this.heightOptions}}
        @idSelected={{this.height}}
        @onChange={{this.setHeight}}
      />
    </EuiFormRow>

    <EuiFormRow @label="Width">
      <EuiButtonGroup
        @legend="Set a width for the following grid"
        @options={{this.widthOptions}}
        @idSelected={{this.width}}
        @onChange={{this.setWidth}}
      />
    </EuiFormRow>

    <EuiSpacer />

    <EuiText>
      <p>There are {{this.mountedCellCount}} rendered cells</p>
    </EuiText>

    {{! completely reset the grid when switching between constrained & unconstrained heights;
        this is for example only, don't switch between them }}
    {{#each (array this.heightMode) key="@identity"}}
      <EuiDataGrid
        aria-label="Virtualized data grid demo"
        @height={{get this.dimensionSizes this.height}}
        @width={{get this.dimensionSizes this.width}}
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
        @rowHeightsOptions={{this.rowHeightsOptions}}
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
    {{/each}}
  </template>
}
```
