---
order: 15
---

# More field types

<EuiText>

The field types of v0.2, all built in: `multiSelect` (Tags), `user` with
a known list (Owner), `currency` (Price, MXN), `percent` (Discount),
`duration` (Time), `rating` (Score), `url`, `email` and `phone`, and
`longText` (Notes). And three of v0.3: `dateTime` (Ships, shown in UTC,
and Ships (Monterrey), the same value in `America/Monterrey` on a
12-hour clock), `button` (Remind) and `barcode` (SKU).

Try: Enter on a Tags cell, click two options (the list stays open), Tab
to save; paste `Red, "Blue, dark"` on a Tags cell (Tags has
`createOnPaste`, so the quoted part becomes a new option with its comma).
Type `$1,234.5` in a Price, `12.5%` or `30` in a Discount, `1h 30m` or
`90` in a Time. Click a star, click the same star again to clear it, or
press a digit on a Score cell. Click the text of a link (it opens in a
new tab) and beside it (it selects); right-click a link cell for "Open
link". Enter on a Notes cell: Shift+Enter (or Alt+Enter) adds a line and
the editor grows, Enter saves. Copy two Notes cells and paste them in a
text editor: a cell with line breaks is quoted. Space opens the expanded
record, where every type has its cell and editor, and links an "open"
button.

Type `19/11/2026 15:30` in a Ships cell: both date-and-time columns show
the same instant in their zones, and copy gives
`2026-11-19T15:30:00.000Z`; Enter opens the browser's date-and-time
picker in the column's zone. Click "Send reminder": the button waits
about 800 ms (a spinner, a second click is ignored) and fails for
Goggles, whose cell then shows the error until the next press; Enter on a
selected button cell presses it too. On a phone with a camera (Chrome on
Android), the SKU cell's camera icon scans a code; elsewhere type or
paste it, or use a USB scanner, which types it and presses Enter.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const TAGS = [
  { value: 'red', label: 'Red', color: 'danger' },
  { value: 'green', label: 'Green', color: 'success' },
  { value: 'blue', label: 'Blue', color: 'primary' },
  { value: 'gray', label: 'Gray' },
];

const USERS = [
  { id: 'u1', label: 'Ana Ruiz', email: 'ana@example.com' },
  { id: 'u2', label: 'Bruno Vela', email: 'bruno@example.com' },
  { id: 'u3', label: 'Carla Soto', email: 'carla@example.com' },
];

const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  { id: 'tags', label: 'Tags', type: 'multiSelect', options: TAGS, createOnPaste: true, width: 180 },
  { id: 'owner', label: 'Owner', type: 'user', options: USERS, width: 160 },
  { id: 'price', label: 'Price', type: 'currency', currency: 'MXN', locale: 'es-MX', min: 0 },
  { id: 'discount', label: 'Discount', type: 'percent', max: 1 },
  { id: 'time', label: 'Time', type: 'duration' },
  { id: 'score', label: 'Score', type: 'rating', width: 120 },
  { id: 'site', label: 'Website', type: 'url' },
  { id: 'mail', label: 'Email', type: 'email' },
  { id: 'phone', label: 'Phone', type: 'phone' },
  { id: 'notes', label: 'Notes', type: 'longText', width: 220 },
  { id: 'ships', label: 'Ships', type: 'dateTime', timeZone: 'utc', width: 170 },
  {
    id: 'shipsLocal', label: 'Ships (Monterrey)', type: 'dateTime',
    timeZone: 'America/Monterrey', hour12: true, width: 190,
  },
  {
    id: 'remind', label: 'Remind', type: 'button', buttonLabel: 'Send reminder',
    icon: 'bell', width: 160,
  },
  { id: 'sku', label: 'SKU', type: 'barcode', pattern: '^\\d{8,13}$', width: 170 },
];

const RECORDS = [
  {
    id: 'p1', name: 'Gloves', tags: ['red', 'blue'], owner: USERS[0], price: 120, discount: 0.1,
    time: 5400, score: 4, site: 'example.com', mail: 'sales@example.com', phone: '+52 81 1234 5678',
    notes: 'Nitrile\nSizes S–XL', ships: '2026-11-19T15:30:00.000Z', shipsLocal: '2026-11-19T15:30:00.000Z',
    sku: '7501234567890',
  },
  {
    id: 'p2', name: 'Helmets', tags: ['green'], owner: USERS[1], price: 849.5, discount: 0.25,
    time: 1800, score: 5, site: 'https://example.org/helmets', mail: 'info@example.org', phone: '81 2222 3333',
    notes: 'ANSI Z89.1', ships: '2026-12-01T09:00:00.000Z', shipsLocal: '2026-12-01T09:00:00.000Z',
    sku: '4006381333931',
  },
  {
    id: 'p3', name: 'Goggles', tags: [], owner: null, price: null, discount: null,
    time: null, score: null, site: 'javascript:alert(1)', mail: 'not an email', phone: 'call me',
    notes: '', ships: null, shipsLocal: null, sku: 'ABC',
  },
  {
    id: 'p4', name: 'Vests', tags: ['red', 'green', 'blue', 'gray'], owner: USERS[2], price: 60, discount: 0,
    time: 600, score: 2, site: '', mail: '', phone: '', notes: 'Reflective',
    ships: null, shipsLocal: null, sku: null,
  },
];

export default class SheetMoreFieldTypes extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  /** A fake action of about 800 ms that fails for Goggles. */
  onButtonPress = ({ record }, { signal }) =>
    new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        if (record.name === 'Goggles') reject(new Error(`No contact for ${record.name}`));
        else resolve();
      }, 800);
      signal.addEventListener('abort', () => clearTimeout(timer));
    });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @onButtonPress={{this.onButtonPress}}
      @rowHeight='medium'
      @height={{300}}
      @ariaLabel='Products'
    />
  </template>
}
```
