---
order: 2
---

# Frozen fields and header lines

<EuiText>

Choose how many fields stay in view when you scroll right
(`@frozenFields`: none, the first, the first two), and scroll the grid to
see it. The labels here are long: with `@headerLines={{2}}` they wrap to
two lines instead of being cut off.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButtonGroup, EuiSpacer } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Inspection title', required: true, width: 200 },
  { id: 'area', label: 'Area of the plant inspected', width: 150 },
  { id: 'date', label: 'Date of the walk-through', type: 'date', width: 150 },
  {
    id: 'findings',
    label: 'Open findings raised',
    type: 'number',
    min: 0,
    width: 130
  },
  {
    id: 'score',
    label: 'Compliance score (0 to 1)',
    type: 'number',
    min: 0,
    max: 1,
    width: 150
  },
  { id: 'passed', label: 'Passed the inspection', type: 'checkbox', width: 130 }
];

const OPTIONS = [
  { id: '0', label: 'None' },
  { id: '1', label: '1 field' },
  { id: '2', label: '2 fields' }
];

export default class SheetFrozenAndHeaderLines extends Component {
  getId = (record) => record.id;
  store = localRecords(inspections(), {
    getRecordId: this.getId,
    fields: FIELDS
  });
  options = OPTIONS;

  @tracked frozen = '1';

  get frozenCount() {
    return Number(this.frozen);
  }

  setFrozen = (id) => {
    this.frozen = id;
  };

  onChange = (changeSet) => {
    this.store.apply(changeSet);
  };

  <template>
    <EuiButtonGroup
      @legend='Frozen fields'
      @options={{this.options}}
      @idSelected={{this.frozen}}
      @onChange={{this.setFrozen}}
      @buttonSize='compressed'
    />
    <EuiSpacer @size='s' />
    <div style='max-width: 560px'>
      <EuiSheet
        @fields={{this.store.fields}}
        @records={{this.store.records}}
        @getRecordId={{this.getId}}
        @onChange={{this.onChange}}
        @frozenFields={{this.frozenCount}}
        @headerLines={{2}}
        @height={{260}}
        @ariaLabel='Inspections with long labels'
      />
    </div>
  </template>
}
```
