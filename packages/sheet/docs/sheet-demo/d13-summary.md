---
order: 13
---

# Summary bar

<EuiText>

Pass `@summary`, an object of texts by field id, and the sheet shows a
footer row with each text under its field (`''` is the row-number column).
The sheet computes nothing: with paged data a sum of the loaded page would
be wrong, so the owner takes the values from its backend, or, as here,
computes them over every record with the core's `summarize` helper.
Choosing what to summarize is the app's control; here the two button
groups in the toolbar. Edit an hour, paste a column or delete a record:
the owner recomputes, the bar follows. The first field stays in view when
you scroll right, and so do its summary and the count under the row
numbers.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButtonGroup, EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';
import { EuiSheet, builtInFieldTypes, defaultMessages, localRecords, summarize } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'start', label: 'Start', type: 'date' },
  { id: 'done', label: 'Done', type: 'checkbox' },
  { id: 'city', label: 'City' },
  { id: 'notes', label: 'Notes', width: 260 },
];

const RECORDS = Array.from({ length: 40 }, (_, i) => ({
  id: i + 1,
  name: `Task ${i + 1}`,
  hours: i % 7 === 0 ? null : (i * 3) % 17,
  start: `2026-${String(1 + (i % 12)).padStart(2, '0')}-${String(1 + ((i * 5) % 28)).padStart(2, '0')}`,
  done: i % 4 === 0,
  city: ['Monterrey', 'Madrid', 'Lima'][i % 3],
  notes: '',
}));

const LABELS = {
  count: 'Count',
  filled: 'Filled',
  unique: 'Unique',
  sum: 'Sum',
  average: 'Average',
  min: 'Earliest',
  max: 'Latest',
  checked: 'Checked',
};

const HOUR_KINDS = [
  { id: 'sum', label: 'Sum' },
  { id: 'average', label: 'Average' },
  { id: 'max', label: 'Max' },
];

const START_KINDS = [
  { id: 'min', label: 'Earliest' },
  { id: 'max', label: 'Latest' },
];

const CONTEXT = { types: builtInFieldTypes, messages: defaultMessages };

export default class SheetSummary extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId });
  hourKinds = HOUR_KINDS;
  startKinds = START_KINDS;

  @tracked hours = 'sum';
  @tracked start = 'min';

  get kinds() {
    return { name: 'filled', hours: this.hours, start: this.start, done: 'checked', city: 'unique' };
  }

  // a new object whenever the records or the choices change
  get summary() {
    const records = this.store.records;
    const summary = { '': `${records.length}` };
    for (const [fieldId, kind] of Object.entries(this.kinds)) {
      const field = FIELDS.find((f) => f.id === fieldId);
      const value = summarize(CONTEXT, records, field, kind);
      const label = kind === 'max' && fieldId === 'hours' ? 'Max' : LABELS[kind];
      summary[fieldId] = value === '' ? '' : `${label} ${value}`;
    }
    return summary;
  }

  setHours = (kind) => (this.hours = kind);
  setStart = (kind) => (this.start = kind);

  <template>
    <EuiSheet
      @fields={{FIELDS}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @summary={{this.summary}}
      @height={{360}}
      @ariaLabel='Tasks'
    >
      <:toolbar>
        <EuiFlexGroup @gutterSize='m' @alignItems='center' @responsive={{false}} @wrap={{true}}>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonGroup
              @legend='Hours summary'
              @options={{this.hourKinds}}
              @idSelected={{this.hours}}
              @onChange={{this.setHours}}
              @buttonSize='compressed'
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonGroup
              @legend='Start summary'
              @options={{this.startKinds}}
              @idSelected={{this.start}}
              @onChange={{this.setStart}}
              @buttonSize='compressed'
            />
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
    </EuiSheet>
  </template>
}
```
