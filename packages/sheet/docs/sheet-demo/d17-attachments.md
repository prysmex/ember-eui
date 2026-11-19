---
order: 17
---

# Attachments

<EuiText>

Files is an `attachment` field with a fake `upload` that takes 800 ms and
fails for a file whose name contains `fail`. Up to four files per cell
(`maxFiles`). Uploaded images are shown from `blob:` URLs, so they last
until the page is reloaded.

Try: click the paperclip on a Files cell (or Enter): the panel lists the
files (each name opens it in a new tab) with remove buttons and a file
picker; pick a file, and the panel stays open while it uploads and then
lists it. Drag a file from your desktop onto a Files cell: the cell is
outlined while you hover it, shows as pending, then gets the file. Copy
an image (a screenshot) and paste it on a Files cell. Drop a file named
`fail.txt`: the cell is marked "Upload failed". Pasting text on a Files
cell is rejected ("Text is not a file"); copying a Files cell gives its
URLs.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

/** A small coloured square as an image URL (no network). */
const swatch = (color) =>
  `data:image/svg+xml,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48"><rect width="48" height="48" fill="${color}"/></svg>`)}`;

let uploads = 0;

/** The fake storage: 800 ms, and a file named fail… fails. */
function upload(files, { signal }) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      if (files.some((file) => file.name.toLowerCase().includes('fail'))) {
        reject(new Error('The storage refused the file'));
        return;
      }
      resolve(
        files.map((file) => ({
          id: `up-${++uploads}`,
          name: file.name,
          url: URL.createObjectURL(file),
          type: file.type,
          size: file.size,
        })),
      );
    }, 800);
    signal.addEventListener('abort', () => clearTimeout(timer));
  });
}

const FIELDS = [
  { id: 'name', label: 'Inspection', required: true },
  { id: 'files', label: 'Files', type: 'attachment', upload, maxFiles: 4, accept: 'image/*,.pdf,.txt', width: 220 },
  { id: 'notes', label: 'Notes', type: 'longText' },
];

const RECORDS = [
  {
    id: 'i1',
    name: 'Line 3, week 46',
    files: [
      { id: 'f1', name: 'photo-red.svg', url: swatch('#E7664C'), type: 'image/svg+xml' },
      { id: 'f2', name: 'report.pdf', url: 'https://example.com/report.pdf', type: 'application/pdf' },
    ],
    notes: 'Two photos missing',
  },
  { id: 'i2', name: 'Warehouse 1', files: [], notes: '' },
  {
    id: 'i3',
    name: 'Boiler room',
    files: [{ id: 'f3', name: 'photo-green.svg', url: swatch('#54B399'), type: 'image/svg+xml' }],
    notes: '',
  },
];

export default class SheetAttachments extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{200}}
      @ariaLabel='Inspections'
    />
  </template>
}
```
