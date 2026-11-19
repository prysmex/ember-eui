---
order: 8
---

# Large data

<EuiText>

Ten thousand generated rows and thirty fields. `EuiDataGrid` renders
only the rows in view, so scrolling and editing stay fast. For a large
range, click a cell, scroll down and Shift+click another one: Delete
clears the range in one change set, and Ctrl/Cmd+C copies it. Ctrl+End
jumps to the last cell. The line under the sheet shows how long the last
change set took to apply.

Turn on "Freeze the first field" (`@frozenFields={{1}}`) and "Code"
stays in view when you scroll right, with the row numbers. That has a
cost, which is why it is off by default: while a field is frozen the grid
renders every column of the rows in view (not only the columns in view),
so a frozen cell never unmounts: here 31 cells per row instead of the few
in view. Scroll down with it on and off to compare; above 50 visible
fields the sheet does not freeze.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiSpacer, EuiSwitch, EuiText } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

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
  // 24 more, to scroll sideways
  ...Array.from({ length: 24 }, (_, i) => ({
    id: `w${i + 1}`,
    label: `Week ${i + 1}`,
    type: 'number',
    min: 0,
    width: 110,
  })),
];

function generate(count) {
  return Array.from({ length: count }, (_, i) => ({
    id: i + 1,
    code: `E-${String(i + 1).padStart(5, '0')}`,
    name: `Employee ${i + 1}`,
    department: DEPARTMENTS[i % DEPARTMENTS.length].value,
    hours: (i * 13) % 61,
    start: `20${String(10 + (i % 17)).padStart(2, '0')}-${String(1 + (i % 12)).padStart(2, '0')}-${String(1 + (i % 28)).padStart(2, '0')}`,
    active: i % 5 !== 0,
    ...Object.fromEntries(Array.from({ length: 24 }, (_, w) => [`w${w + 1}`, (i + w) % 41])),
  }));
}

export default class SheetLargeData extends Component {
  getId = (record) => record.id;
  store = localRecords(generate(10_000), { getRecordId: this.getId });

  @tracked last = null;
  @tracked frozen = false;

  toggleFrozen = (event) => {
    this.frozen = event.target.checked;
  };

  onChange = (changeSet) => {
    const start = performance.now();
    this.store.apply(changeSet);
    const ms = performance.now() - start;
    this.last = `${changeSet.source}: ${changeSet.patches.length} patches, ${changeSet.inserts.length} inserts, applied in ${ms.toFixed(1)} ms`;
  };

  <template>
    <EuiSwitch @label='Freeze the first field' @checked={{this.frozen}} @onChange={{this.toggleFrozen}} />
    <EuiSpacer @size='s' />
    <EuiSheet
      @fields={{FIELDS}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @height={{420}}
      @frozenFields={{if this.frozen 1 0}}
      @ariaLabel='Employees'
    />
    <EuiSpacer @size='s' />
    <EuiText @size='xs' @color='subdued'>
      <p>{{this.store.records.length}} records. {{if this.last this.last 'No change yet.'}}</p>
    </EuiText>
  </template>
}
```
