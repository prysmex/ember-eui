---
order: 28
---

# Import screen

<EuiText>

**Import…** opens a file picker; the chosen file opens the import screen
(`<EuiSheetImport>`) in a modal. The screen reads the file (UTF-8, or
windows-1252 as Excel saves it), maps its columns to the fields by
`importAliases`, label and id, guesses each column's type, and shows a
preview with the totals over every line. Here the fields have Spanish
aliases; `Precio` uses a decimal comma, so set its decimal separator to
"Comma"; map the `Estado` texts to the options under **Values**;
`Proveedor` has no field, so it goes to a new field (a single select,
guessed from its texts), created by the `localRecords` store on Import.
Two transforms are offered (upper case, first word). Import appends the
lines with `api.appendRows`, one undo step; the last mapping is passed
back, so the same file opens mapped the same way. **Download sample
file** gives a CSV with a bad price and a bad date.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiButtonEmpty, EuiFlexGroup, EuiFlexItem, EuiModal, EuiModalBody, EuiModalHeader, EuiModalHeaderTitle, EuiText } from '@ember-eui/core/components';
import { EuiSheet, EuiSheetImport, localRecords } from '@ember-eui/sheet';

const STATUS = [
  { value: 'available', label: 'Available', color: 'success' },
  { value: 'low', label: 'Low stock', color: 'warning' },
  { value: 'out', label: 'Out of stock', color: 'danger' },
];

const FIELDS = [
  { id: 'item', label: 'Item', importAliases: ['Nombre', 'Producto'], width: 160 },
  { id: 'price', label: 'Unit price', type: 'number', importAliases: ['Precio'], width: 100 },
  { id: 'due', label: 'Next count', type: 'date', importAliases: ['Fecha'], width: 120 },
  { id: 'active', label: 'Active', type: 'checkbox', importAliases: ['Activo'], width: 80 },
  { id: 'status', label: 'Status', type: 'singleSelect', options: STATUS, importAliases: ['Estado'], width: 130 },
];

const RECORDS = [
  { id: 'p1', item: 'Bolt M8', price: 0.35, due: '2026-12-01', active: true, status: 'available' },
  { id: 'p2', item: 'Washer, 8 mm', price: 0.05, due: '2026-12-01', active: true, status: 'low' },
];

const SAMPLE = [
  'Nombre;Precio;Fecha;Activo;Estado;Proveedor',
  'Tornillo M6;0,25;15/11/2026;Sí;Disponible;Aceros del Norte',
  'Tuerca M6;0,10;15/11/2026;Sí;Disponible;Aceros del Norte',
  'Arandela 6 mm;0,05;18/11/2026;No;Agotado;Ferretería Lupita',
  'Broca 3/8;18,50;20/11/2026;Sí;Poco stock;Herramientas Peña',
  'Taquete 1/4;doce;22/11/2026;Sí;Disponible;Ferretería Lupita',
  'Llave Allen 5 mm;35,00;31/02/2026;No;Agotado;Herramientas Peña',
  'Cinta métrica 5 m;89,90;25/11/2026;Sí;Poco stock;Aceros del Norte',
  'Martillo de uña;1.250,00;28/11/2026;Sí;Disponible;Herramientas Peña',
].join('\r\n');

const TRANSFORMS = [
  { id: 'upper', label: 'Upper case', apply: (text) => text.toUpperCase() },
  {
    id: 'firstWord',
    label: 'First word',
    description: 'Split a full name: its first part',
    apply: (text) => text.trim().split(/\s+/)[0] ?? '',
  },
];

function download(name, text) {
  // the BOM tells Excel the file is UTF-8 (accents)
  const blob = new Blob([String.fromCharCode(0xfeff) + text], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = name;
  link.click();
  URL.revokeObjectURL(url);
}

export default class SheetImportScreen extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });
  transforms = TRANSFORMS;
  api = null;
  @tracked file = null;
  @tracked lastMapping = null;
  @tracked status = '';

  registerApi = (api) => (this.api = api);

  pick = () => document.getElementById('sheetImportDemoFile')?.click();

  chosen = (event) => {
    this.file = event.target.files?.[0] ?? null;
    event.target.value = '';
  };

  close = () => (this.file = null);

  sample = () => download('inventario.csv', SAMPLE);

  // the store creates each field (its id is a slug of the label) at the end
  createFields = (drafts) =>
    drafts.map((draft) => {
      this.store.createField(draft, { index: this.store.fields.length });
      return this.store.fields[this.store.fields.length - 1];
    });

  import = (result) => {
    if (result.mapping) this.lastMapping = result.mapping;
    // chunks of 1,000 lines, each one undo step
    for (let i = 0; i < result.rows.length; i += 1000) {
      this.api?.appendRows(result.rows.slice(i, i + 1000), result.fieldIds, { fields: result.fields });
    }
    const created = result.createdFields.map((field) => field.label).join(', ');
    this.status =
      `${this.file?.name}: ${result.rows.length} lines imported` +
      (result.skippedLines.length ? `, ${result.skippedLines.length} skipped` : '') +
      (created ? `; new fields: ${created}` : '');
    this.close();
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @onFieldCreate={{this.store.createField}}
      @onFieldUpdate={{this.store.updateField}}
      @onFieldDelete={{this.store.deleteField}}
      @registerApi={{this.registerApi}}
      @height={{300}}
      @ariaLabel='Inventory'
    >
      <:toolbar>
        <EuiFlexGroup @gutterSize='s' @alignItems='center' @responsive={{false}}>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @size='s' @iconType='importAction' data-test-subj='importScreenButton' {{on 'click' this.pick}}>
              Import…
            </EuiButtonEmpty>
            <input id='sheetImportDemoFile' type='file' accept='.csv,.tsv,.txt,text/csv' hidden data-test-subj='importScreenInput' {{on 'change' this.chosen}} />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @size='s' @iconType='download' data-test-subj='importScreenSample' {{on 'click' this.sample}}>
              Download sample file
            </EuiButtonEmpty>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
      <:footer>
        <EuiText @size='xs' @color='subdued' data-test-subj='importScreenStatus'>
          <p>{{if this.status this.status 'Import a CSV file (Download sample file has one in Spanish).'}}</p>
        </EuiText>
      </:footer>
    </EuiSheet>
    {{#if this.file}}
      <EuiModal aria-labelledby='sheetImportDemoTitle' style='width: 1180px; max-width: calc(100vw - 32px)' @onClose={{this.close}}>
        <EuiModalHeader>
          <EuiModalHeaderTitle id='sheetImportDemoTitle'>Import {{this.file.name}}</EuiModalHeaderTitle>
        </EuiModalHeader>
        <EuiModalBody>
          <EuiSheetImport
            @fields={{this.store.fields}}
            @file={{this.file}}
            @transforms={{this.transforms}}
            @onCreateFields={{this.createFields}}
            @savedMapping={{this.lastMapping}}
            @onImport={{this.import}}
            @onCancel={{this.close}}
          />
        </EuiModalBody>
      </EuiModal>
    {{/if}}
  </template>
}
```
