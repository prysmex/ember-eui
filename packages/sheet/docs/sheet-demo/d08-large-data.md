---
order: 8
---

# Large data

<EuiText>

Ten thousand generated rows. `EuiDataGrid` renders only the rows in
view, so scrolling and editing stay fast. For a large range, click a
cell, scroll down and Shift+click another one: Delete clears the range
in one change set, and Ctrl/Cmd+C copies it. Ctrl+End jumps to the last
cell. The line under the sheet shows how long the last change set took
to apply.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiSpacer, EuiText } from '@ember-eui/core/components';
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
  }));
}

export default class SheetLargeData extends Component {
  getId = (record) => record.id;
  store = localRecords(generate(10_000), { getRecordId: this.getId });

  @tracked last = null;

  onChange = (changeSet) => {
    const start = performance.now();
    this.store.apply(changeSet);
    const ms = performance.now() - start;
    this.last = `${changeSet.source}: ${changeSet.patches.length} patches, ${changeSet.inserts.length} inserts, applied in ${ms.toFixed(1)} ms`;
  };

  <template>
    <EuiSheet
      @fields={{FIELDS}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @height={{420}}
      @ariaLabel='Employees'
    />
    <EuiSpacer @size='s' />
    <EuiText @size='xs' @color='subdued'>
      <p>{{this.store.records.length}} records. {{if this.last this.last 'No change yet.'}}</p>
    </EuiText>
  </template>
}
```
