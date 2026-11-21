---
order: 1
---

# Import with aliases and number formats

<EuiText>

Edit the CSV and press **Import**. The Spanish headers match the fields'
`importAliases`; the dates are month/day/year and the prices have a
decimal comma, so each is read with a per-column copy of its field
(`dateOrder: 'mdy'`, `decimalSeparator: ','`) passed to `appendRows`. A
column no field matches is listed as not imported. Ctrl/Cmd+Z removes the
lines.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiText,
  EuiTextArea
} from '@ember-eui/core/components';
import {
  EuiSheet,
  importMatrix,
  localRecords,
  parseCsv
} from '@ember-eui/sheet';

const FIELDS = [
  {
    id: 'title',
    label: 'Inspection',
    importAliases: ['Inspección'],
    width: 200
  },
  {
    id: 'date',
    label: 'Date',
    type: 'date',
    dateOrder: 'dmy',
    importAliases: ['Fecha'],
    width: 120
  },
  {
    id: 'cost',
    label: 'Repair cost',
    type: 'number',
    importAliases: ['Costo'],
    width: 110
  },
  {
    id: 'findings',
    label: 'Findings',
    type: 'number',
    importAliases: ['Hallazgos'],
    width: 100
  }
];

const RECORDS = [
  {
    id: 'r1',
    title: 'Forklift pre-shift check',
    date: '2026-11-03',
    cost: 0,
    findings: 1
  }
];

const CSV = [
  'Inspección;Fecha;Costo;Hallazgos;Inspector',
  'Extintores, nave B;11/05/2026;1250,50;3;Bruno Vela',
  'Salidas de emergencia;11/17/2026;0;2;Ana Ruiz',
  '"Bloqueo, prensa 4";11/12/2026;3400,00;5;Diego Paz'
].join('\n');

export default class SheetCsvImport extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });
  api = null;
  @tracked text = CSV;
  @tracked status = '';
  @tracked unmatched = [];

  registerApi = (api) => (this.api = api);
  edit = (event) => (this.text = event.target.value);

  import = () => {
    const { rows, fieldIds, unmatched } = importMatrix(
      parseCsv(this.text),
      FIELDS
    );
    const dates = FIELDS.find((field) => field.id === 'date');
    const cost = FIELDS.find((field) => field.id === 'cost');
    this.api?.appendRows(rows, fieldIds, {
      fields: [
        { ...dates, dateOrder: 'mdy' },
        { ...cost, decimalSeparator: ',' }
      ]
    });
    this.unmatched = unmatched;
    this.status = `${rows.length} lines into ${fieldIds.length} fields`;
  };

  <template>
    <EuiTextArea
      @value={{this.text}}
      @fullWidth={{true}}
      @rows={{5}}
      aria-label='CSV to import'
      {{on 'input' this.edit}}
    />
    <EuiSpacer @size='s' />
    <EuiFlexGroup @gutterSize='m' @alignItems='center' @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiButton
          @size='s'
          @fill={{true}}
          {{on 'click' this.import}}
        >Import</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiText @size='xs' @color='subdued'>
          <p>
            {{if this.status this.status 'Nothing imported yet.'}}
            {{#if this.unmatched.length}}
              Not imported (no field):
              {{#each this.unmatched as |name|}}<strong>{{name}}</strong>
              {{/each}}
            {{/if}}
          </p>
        </EuiText>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size='s' />
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @registerApi={{this.registerApi}}
      @height={{240}}
      @ariaLabel='Inspections to import into'
    />
  </template>
}
```
