---
order: 1
---

# Large data at scale

<EuiText>

The d08 demo ("Employees") with its size from the URL: `?rows=100000`
(default 10,000), `&weeks=24` (the number of "Week" fields, default 24:
30 fields), `&frozen=1` (`@frozenFields={{1}}`), `&mode=grid` (a plain
`EuiDataGrid` with a trivial cell and the same columns, for comparing
the sheet's own cost). The records are generated when the page loads;
the sheet mounts on "Mount", so its first render can be timed alone.
Timings go to `window.__perf`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiButton, EuiDataGrid, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const params = new URLSearchParams(globalThis.location?.search ?? '');
const ROWS = Number(params.get('rows') ?? 10_000);
const WEEKS = Number(params.get('weeks') ?? 24);
const FROZEN = params.get('frozen') === '1' ? 1 : 0;
const MODE = params.get('mode') ?? 'sheet';

const DEPARTMENTS = [
  { value: 'ops', label: 'Operations', color: 'primary' },
  { value: 'hse', label: 'Safety', color: 'success' },
  { value: 'qa', label: 'Quality', color: 'warning' },
  { value: 'it', label: 'IT', color: 'accent' },
];

const FIELDS = [
  { id: 'code', label: 'Code', readOnly: true },
  { id: 'name', label: 'Name', required: true },
  { id: 'department', label: 'Department', type: 'singleSelect', options: DEPARTMENTS },
  { id: 'hours', label: 'Hours', type: 'number', min: 0, max: 60 },
  { id: 'start', label: 'Start', type: 'date' },
  { id: 'active', label: 'Active', type: 'checkbox' },
  ...Array.from({ length: WEEKS }, (_, i) => ({
    id: `w${i + 1}`,
    label: `Week ${i + 1}`,
    type: 'number',
    min: 0,
    width: 110,
  })),
];

const TrivialCell = <template>{{@value}}</template>;
const TrivialHeader = <template>#</template>;
const TrivialRowNumber = <template>{{@rowIndex}}</template>;

const GRID_COLUMNS = FIELDS.map((f) => ({ id: f.id, displayAsText: f.label, initialWidth: f.width ?? 150 }));
const GRID_LEADING = [{ id: 'row', width: 48, headerCellRender: TrivialHeader, rowCellRender: TrivialRowNumber }];

function generate(count) {
  return Array.from({ length: count }, (_, i) => ({
    id: i + 1,
    code: `E-${String(i + 1).padStart(6, '0')}`,
    name: `Employee ${i + 1}`,
    department: DEPARTMENTS[i % DEPARTMENTS.length].value,
    hours: (i * 13) % 61,
    start: `20${String(10 + (i % 17)).padStart(2, '0')}-${String(1 + (i % 12)).padStart(2, '0')}-${String(1 + (i % 28)).padStart(2, '0')}`,
    active: i % 5 !== 0,
    ...Object.fromEntries(Array.from({ length: WEEKS }, (_, w) => [`w${w + 1}`, (i + w) % 41])),
  }));
}

class GridCell extends Component {
  get value() {
    return this.args.cellContext.store.records[this.args.rowIndex]?.[this.args.columnId];
  }
  <template><TrivialCell @value={{this.value}} /></template>
}

const perf = (globalThis.__perf = { rows: ROWS, fields: FIELDS.length, frozen: FROZEN, mode: MODE, applies: [] });

export default class SheetPerfLarge extends Component {
  getId = (record) => record.id;
  store;
  @tracked mounted = false;
  @tracked last = null;

  constructor(owner, args) {
    super(owner, args);
    let t = performance.now();
    const records = generate(ROWS);
    perf.generateMs = performance.now() - t;
    t = performance.now();
    this.store = localRecords(records, { getRecordId: this.getId });
    perf.storeMs = performance.now() - t;
    this.cellContext = { store: this.store };
  }

  // one object for the grid's whole life (a new one each render would re-render every cell)
  cellContext;

  mount = () => {
    perf.mountAt = performance.now();
    this.mounted = true;
  };

  onChange = (changeSet) => {
    const start = performance.now();
    this.store.apply(changeSet);
    const ms = performance.now() - start;
    perf.applies.push({ at: start, source: changeSet.source, patches: changeSet.patches.length, inserts: changeSet.inserts.length, removes: changeSet.removes?.length ?? 0, ms });
    this.last = `${changeSet.source}: ${changeSet.patches.length} patches, ${changeSet.inserts.length} inserts, applied in ${ms.toFixed(1)} ms`;
  };

  <template>
    <EuiButton data-test-subj="perfMount" {{on "click" this.mount}}>Mount</EuiButton>
    <EuiSpacer @size='s' />
    {{#if this.mounted}}
      {{#if (eq MODE "grid")}}
        <EuiDataGrid
          aria-label="Employees"
          @columns={{GRID_COLUMNS}}
          @leadingControlColumns={{GRID_LEADING}}
          @rowCount={{this.store.records.length}}
          @renderCellValue={{GridCell}}
          @cellContext={{this.cellContext}}
          @toolbarVisibility={{false}}
          @height={{420}}
        />
      {{else}}
        <EuiSheet
          @fields={{FIELDS}}
          @records={{this.store.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.onChange}}
          @height={{420}}
          @frozenFields={{FROZEN}}
          @ariaLabel='Employees'
        />
      {{/if}}
    {{/if}}
    <EuiSpacer @size='s' />
    <EuiText @size='xs' @color='subdued'>
      <p data-test-subj="perfStatus">{{this.store.records.length}} records. {{if this.last this.last 'No change yet.'}}</p>
    </EuiText>
  </template>
}

function eq(a, b) {
  return a === b;
}
```
