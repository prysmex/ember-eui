---
order: 1
---

# Scanning products into a count

<EuiText>

A stock count. **Barcode** is a `barcode` field: its text in a
monospace font, with a `pattern` (8 to 13 digits) and its own message.
Type or paste a code, or use a USB scanner, which types it and presses
Enter, so you can scan down the column. The field also has a `scan`
function, so its cells have a camera icon: a click on it opens the scan
panel and calls `scan({ formats, signal })`. Here `scan` is a stand-in
that "reads" the next code of a list after a second, so the panel works
on any computer; a real app passes a camera library's reader there (a
zxing wrapper, say), or leaves `scan` out and the sheet uses the
browser's `BarcodeDetector` with the camera where there is one
(Chromium on Android, ChromeOS and macOS). Cancel or Escape stops it.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { products, wait } from 'site/utils/sheet-docs-data';

const CODES = ['7501234567944', '7501234567951', '4006381333931'];
let next = 0;

/** A stand-in for a camera reader: the next code of the list after a second. */
async function scan({ signal }) {
  await wait(1000, signal);
  return CODES[next++ % CODES.length];
}

const FIELDS = [
  {
    id: 'sku',
    label: 'Barcode',
    type: 'barcode',
    pattern: '^\\d{8,13}$',
    patternMessage: 'A barcode has 8 to 13 digits',
    formats: ['ean_13', 'ean_8', 'code_128'],
    scan,
    width: 190
  },
  { id: 'name', label: 'Product', width: 200 },
  { id: 'counted', label: 'Counted', type: 'number', min: 0 }
];

export default class Barcodes extends Component {
  getId = (record) => record.id;
  store = localRecords(
    [
      ...products().map((product) => ({ ...product, counted: null })),
      { id: 'p6', sku: 'ABC-12', name: 'Unlabelled box', counted: 3 }
    ],
    { getRecordId: this.getId, fields: FIELDS }
  );

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{270}}
      @ariaLabel='Stock count'
    />
  </template>
}
```
