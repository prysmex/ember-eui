---
order: 1
---

# Errors that block your submit, a colour that warns

<EuiText>

Inspection hours for the week. The sheet stores every value it can read
and marks the ones that break a rule; it is the app that decides what
blocks. Here **Submit** stays disabled while any cell breaks a field
rule (an inspector and a date are required, hours are 0 to 24): the app
runs the same rules with `validateCell`, so its list and the red cells
agree. More than 10 hours is not an error but a warning: the app draws
it with `@cellColor` (a yellow bar) and lists it, since a colour alone
is not read out. Type `abc` on Hours: the text is rejected and the
record keeps its old value, so nothing wrong reaches your records or
your submit. Fill the missing inspector and date of the last row, and
Submit turns on.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiButton, EuiSpacer, EuiText } from '@ember-eui/core/components';
import {
  builtInFieldTypes,
  defaultMessages,
  EuiSheet,
  localRecords,
  validateCell
} from '@ember-eui/sheet';
import { INSPECTORS } from 'site/utils/sheet-docs-data';

const FIELDS = [
  {
    id: 'inspector',
    label: 'Inspector',
    type: 'user',
    options: INSPECTORS,
    required: true,
    width: 160
  },
  { id: 'date', label: 'Date', type: 'date', required: true },
  { id: 'area', label: 'Area', width: 160 },
  { id: 'hours', label: 'Hours', type: 'number', min: 0, max: 24 }
];

const HOURS = [
  {
    id: 'h1',
    inspector: INSPECTORS[0],
    date: '2026-11-16',
    area: 'Dock 2',
    hours: 6
  },
  {
    id: 'h2',
    inspector: INSPECTORS[1],
    date: '2026-11-16',
    area: 'Hall B',
    hours: 11.5
  },
  {
    id: 'h3',
    inspector: INSPECTORS[2],
    date: '2026-11-17',
    area: 'Store 1',
    hours: 8
  },
  {
    id: 'h4',
    inspector: INSPECTORS[3],
    date: '2026-11-18',
    area: 'Press line',
    hours: 26
  },
  { id: 'h5', inspector: null, date: null, area: 'Mezzanine', hours: 4 }
];

const CTX = { types: builtInFieldTypes, messages: defaultMessages };
const isLong = (record, field) =>
  field.id === 'hours' && record.hours > 10 && record.hours <= 24;

export default class BlockingAndWarnings extends Component {
  getId = (record) => record.id;
  store = localRecords(HOURS, { getRecordId: this.getId, fields: FIELDS });

  @tracked submitted = '';

  /** The field rules, as the sheet runs them: [{ record, field, message }]. */
  get errors() {
    return this.store.records.flatMap((record) =>
      FIELDS.flatMap((field) =>
        validateCell(CTX, field, record).map((message) => ({
          record,
          field,
          message
        }))
      )
    );
  }

  get warnings() {
    return this.store.records.filter((record) => isLong(record, FIELDS[3]));
  }

  cellColor = (record, field) =>
    isLong(record, field) ? 'warning' : undefined;

  submit = () => {
    this.submitted = `Submitted ${this.store.records.length} records (${this.warnings.length} with a warning).`;
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @cellColor={{this.cellColor}}
      @height={{230}}
      @ariaLabel='Inspection hours'
    />
    <EuiSpacer @size='s' />
    <EuiText @size='s'>
      <p><strong>Errors: {{this.errors.length}}</strong>
        (Submit is blocked while there are any)</p>
      <ul>
        {{#each this.errors as |error|}}
          <li>{{error.record.area}},
            {{error.field.label}}:
            {{error.message}}</li>
        {{/each}}
      </ul>
      <p><strong>Warnings: {{this.warnings.length}}</strong>
        (they do not block)</p>
      <ul>
        {{#each this.warnings as |record|}}
          <li>{{record.area}}: {{record.hours}} hours is more than a shift</li>
        {{/each}}
      </ul>
    </EuiText>
    <EuiButton
      @size='s'
      @isDisabled={{if this.errors.length true false}}
      {{on 'click' this.submit}}
    >Submit</EuiButton>
    <p>{{this.submitted}}</p>
  </template>
}
```
