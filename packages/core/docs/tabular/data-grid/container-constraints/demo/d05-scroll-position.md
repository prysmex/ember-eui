---
order: 5
---

# Scroll position

<EuiText>

If you need access to the current scroll position of a virtualized
**EuiDataGrid** you can make use of the `virtualizationOptions.onScroll`
callback. It passes along the scroll data and provides scroll position
checks out of the box.

```ts
onScroll(args: {
  scrollLeft: number;
  scrollTop: number;
  scrollHeight: number;
  scrollWidth: number;
  clientHeight: number;
  clientWidth: number;
  isScrolledToBlockStart: boolean;
  isScrolledToBlockEnd: boolean;
  isScrolledToInlineStart: boolean;
  isScrolledToInlineEnd: boolean;
}) => void
```

`virtualizationOptions.onItemsRendered` similarly reports the rendered
(overscan) and visible row and column ranges after each render; see the
100,000 rows example below.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { isDestroying } from '@ember/destroyable';
import { modifier } from 'ember-modifier';
import { get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import {
  EuiDataGrid,
  EuiFlexGroup,
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

export default class ScrollPositionDemo extends Component {
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

  rowHeightsOptions = { defaultHeight: 'auto', scrollAnchorRow: 'start' };

  @tracked isScrolledToBlockEnd = false;
  @tracked isScrolledToInlineEnd = false;

  virtualizationOptions = {
    onScroll: ({ isScrolledToBlockEnd, isScrolledToInlineEnd }) => {
      this.isScrolledToBlockEnd = isScrolledToBlockEnd;
      this.isScrolledToInlineEnd = isScrolledToInlineEnd;
    }
  };

  <template>
    <EuiFlexGroup>
      <EuiText>
        <p>
          <code>isScrolledToBlockEnd</code>: <b>{{if this.isScrolledToBlockEnd "true" "false"}}</b>
        </p>
      </EuiText>
      <EuiText>
        <p>
          <code>isScrolledToInlineEnd:</code> <b>{{if this.isScrolledToInlineEnd "true" "false"}}</b>
        </p>
      </EuiText>
    </EuiFlexGroup>

    <EuiSpacer @size="m" />

    <EuiDataGrid
      aria-label="Virtualized data grid scrolling demo"
      @height={{300}}
      @width={{400}}
      @columns={{this.columns}}
      @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
      @rowCount={{10}}
      @rowHeightsOptions={{this.rowHeightsOptions}}
      @virtualizationOptions={{this.virtualizationOptions}}
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
  </template>
}
```
