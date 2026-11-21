---
order: 26
---

# CSV export and import

<EuiText>

Both buttons are the app's, in `<:toolbar>`. **Export CSV** calls
`toCsv` with the view's fields (the block's `fields`) and every record,
and downloads the text; a cell a spreadsheet would run as a formula
(`=…`, `@…`) gets a leading `'`. **Import CSV** reads the chosen file
with `parseCsv` (the delimiter is detected: `,`, `;` or a tab),
`importMatrix` matches its header line to the fields (by
`importAliases`, then label, then id, ignoring case, accents, spaces,
`_` and `-`), and `api.appendRows` adds the lines as records, in chunks
of 1,000, exactly as a paste on the add row would: a text a field
cannot read shows as a rejection in its cell, and Ctrl/Cmd+Z removes
the chunk. The fields here have Spanish aliases (`Producto`, `Precio`,
`Existencias`, `Fecha`, `Activo`), so a file with Spanish headers
imports as is. **Sample file** downloads one, with a price that is not
a number and a column with no field.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { EuiButtonEmpty, EuiFlexGroup, EuiFlexItem, EuiText } from '@ember-eui/core/components';
import { EuiSheet, builtInFieldTypes, defaultMessages, importMatrix, localRecords, parseCsv, toCsv } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'item', label: 'Item', importAliases: ['Producto', 'Artículo'], width: 150 },
  { id: 'price', label: 'Unit price', type: 'number', importAliases: ['Precio'], width: 110 },
  { id: 'stock', label: 'Stock', type: 'number', importAliases: ['Existencias'], width: 90 },
  { id: 'due', label: 'Next count', type: 'date', importAliases: ['Fecha'], width: 120 },
  { id: 'active', label: 'Active', type: 'checkbox', importAliases: ['Activo'], width: 80 },
  { id: 'notes', label: 'Notes', importAliases: ['Notas'], width: 200 },
];

const RECORDS = [
  { id: 'p1', item: 'Bolt M8', price: 0.35, stock: 1200, due: '2026-12-01', active: true, notes: 'Box of 100' },
  { id: 'p2', item: 'Washer, 8 mm', price: 0.05, stock: 5400, due: '2026-12-01', active: true, notes: '' },
  { id: 'p3', item: 'Cable "flex" 2 m', price: 4.2, stock: 80, due: null, active: false, notes: '=HYPERLINK("http://example.com")' },
];

const SAMPLE = [
  'Producto;Precio;Existencias;Fecha;Activo;Proveedor',
  'Tuerca M8;0.12;900;15/12/2026;Sí;Aceros del Norte',
  'Taquete 1/4;doce;300;20/12/2026;No;Ferretería Lupita',
  '"Broca 3/8, cobalto";18.5;40;;sí;',
].join('\r\n');

function download(name, text) {
  // the BOM tells Excel the file is UTF-8 (accents)
  const blob = new Blob(['﻿' + text], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = name;
  link.click();
  URL.revokeObjectURL(url);
}

export default class SheetCsv extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });
  api = null;
  @tracked status = '';

  registerApi = (api) => (this.api = api);

  exportCsv = (sheet) => {
    const ctx = { types: builtInFieldTypes, messages: defaultMessages };
    download('inventory.csv', toCsv(ctx, this.store.records, sheet.fields));
  };

  sample = () => download('inventario.csv', SAMPLE);

  importFile = async (sheet, event) => {
    const input = event.target;
    const file = input.files?.[0];
    if (!file) return;
    const text = await file.text();
    // the view's fields, hidden ones too
    const fields = [...sheet.fields, ...sheet.hiddenFields];
    const { rows, fieldIds, unmatched } = importMatrix(parseCsv(text), fields);
    for (let i = 0; i < rows.length; i += 1000) {
      this.api?.appendRows(rows.slice(i, i + 1000), fieldIds);
    }
    this.status =
      `${file.name}: ${rows.length} lines into ${fieldIds.length} fields` +
      (unmatched.length ? `; not imported: ${unmatched.join(', ')}` : '');
    input.value = '';
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @registerApi={{this.registerApi}}
      @height={{300}}
      @ariaLabel='Inventory'
    >
      <:toolbar as |sheet|>
        <EuiFlexGroup @gutterSize='s' @alignItems='center' @responsive={{false}}>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @size='s' @iconType='exportAction' data-test-subj='exportCsvButton' {{on 'click' (fn this.exportCsv sheet)}}>
              Export CSV
            </EuiButtonEmpty>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiText @size='xs'>
              <label>
                Import CSV
                <input type='file' accept='.csv,.tsv,.txt,text/csv' data-test-subj='importCsvInput' {{on 'change' (fn this.importFile sheet)}} />
              </label>
            </EuiText>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @size='s' @iconType='download' data-test-subj='sampleCsvButton' {{on 'click' this.sample}}>
              Sample file
            </EuiButtonEmpty>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
      <:footer>
        <EuiText @size='xs' @color='subdued' data-test-subj='csvStatus'>
          <p>{{if this.status this.status 'Export the records, or import a CSV file (Sample file has one in Spanish).'}}</p>
        </EuiText>
      </:footer>
    </EuiSheet>
  </template>
}
```
