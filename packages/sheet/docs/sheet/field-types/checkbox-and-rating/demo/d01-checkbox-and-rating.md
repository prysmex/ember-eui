---
order: 1
---

# Checks and conditions

<EuiText>

A pre-shift checklist. **Passed** and **Signed** are `checkbox`
fields: a click anywhere in the cell, or Space on it, toggles it, and a
paste reads `yes`, `x`, `✓`, `sí` or `1` as checked and `no`, `0` or an
empty text as not. **Condition** is a `rating` of five stars and
**Priority** one of three (`max: 3`): click a star to set it, the same
star again to clear it, or press a digit on the cell (`0` clears).
Neither type has an editor. The bar under the grid counts the checked
rows with `summarize(…, 'checked')`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import {
  builtInFieldTypes,
  defaultMessages,
  EuiSheet,
  localRecords,
  summarize
} from '@ember-eui/sheet';

const FIELDS = [
  { id: 'item', label: 'Check', required: true, width: 220 },
  { id: 'passed', label: 'Passed', type: 'checkbox' },
  { id: 'condition', label: 'Condition', type: 'rating', width: 130 },
  { id: 'priority', label: 'Priority', type: 'rating', max: 3 },
  { id: 'signed', label: 'Signed', type: 'checkbox' }
];

const CHECKS = [
  {
    id: 'c1',
    item: 'Brakes and horn',
    passed: true,
    condition: 5,
    priority: null,
    signed: true
  },
  {
    id: 'c2',
    item: 'Forks and chains',
    passed: true,
    condition: 4,
    priority: 1,
    signed: true
  },
  {
    id: 'c3',
    item: 'Tyres',
    passed: false,
    condition: 2,
    priority: 3,
    signed: false
  },
  {
    id: 'c4',
    item: 'Seat belt',
    passed: true,
    condition: 3,
    priority: 2,
    signed: false
  },
  {
    id: 'c5',
    item: 'Lights and alarm',
    passed: false,
    condition: null,
    priority: 3,
    signed: false
  }
];

const CTX = { types: builtInFieldTypes, messages: defaultMessages };

export default class CheckboxAndRating extends Component {
  getId = (record) => record.id;
  store = localRecords(CHECKS, { getRecordId: this.getId, fields: FIELDS });

  get summary() {
    const records = this.store.records;

    return {
      passed: `${summarize(CTX, records, FIELDS[1], 'checked')} passed`,
      condition: `Avg ${summarize(CTX, records, FIELDS[2], 'average')}`,
      signed: `${summarize(CTX, records, FIELDS[4], 'checked')} signed`
    };
  }

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @summary={{this.summary}}
      @height={{250}}
      @ariaLabel='Pre-shift checklist'
    />
  </template>
}
```
