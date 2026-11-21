---
order: 3
---

# Linked records and bulk resolve

<EuiText>

Contacts is a `linkedRecord` field and Reviewer a `user` field without a
list: both search a fake API (300 ms) in their pickers, and typed or
pasted names go to `@onResolve`, which looks them up in one call per
paste (500 ms). The log under the sheet shows each call.

Try: Enter on a Contacts cell, type `a`, click two people, Tab. Then copy
this and paste it on the first Name:

```text
Gloves	Ana Ruiz, Bruno Vela	Carla Soto
Masks	Zed	Ana Ruiz
Boots	Diego Paz	Bruno Vela
```

The names are written at once, and the Contacts and
Reviewer cells show their text in grey until the answer comes: then the
chips and avatars, and `Zed` is marked "could not be resolved". The log
has one call with the distinct names per field. One Ctrl/Cmd+Z undoes the
paste and the resolve together. Paste on a cell and type in it before the
answer: the newer write wins and the call's signal is aborted. Typing a
name in the picker and clicking elsewhere without picking resolves it too.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiCodeBlock, EuiSpacer } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const PEOPLE = [
  { id: 'c1', label: 'Ana Ruiz' },
  { id: 'c2', label: 'Bruno Vela' },
  { id: 'c3', label: 'Carla Soto' },
  { id: 'c4', label: 'Diego Paz' },
  { id: 'c5', label: 'Elena Mora' },
];

const wait = (ms, signal) =>
  new Promise((resolve, reject) => {
    const timer = setTimeout(resolve, ms);
    signal?.addEventListener('abort', () => {
      clearTimeout(timer);
      reject(new DOMException('Aborted', 'AbortError'));
    });
  });

/** The fake API: people whose name contains the query. */
async function searchPeople(query, { signal }) {
  await wait(300, signal);
  const q = query.trim().toLowerCase();
  return PEOPLE.filter((person) => person.label.toLowerCase().includes(q));
}

const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  { id: 'contacts', label: 'Contacts', type: 'linkedRecord', search: searchPeople, width: 240 },
  { id: 'reviewer', label: 'Reviewer', type: 'user', search: searchPeople, width: 180 },
];

const RECORDS = [
  { id: 'r1', name: 'Helmets', contacts: [PEOPLE[0]], reviewer: PEOPLE[1] },
  { id: 'r2', name: 'Vests', contacts: [], reviewer: null },
  { id: 'r3', name: 'Goggles', contacts: [PEOPLE[2], PEOPLE[3]], reviewer: null },
];

export default class SheetLinkedRecords extends Component {
  @tracked log = [];
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  onResolve = async (requests, { signal }) => {
    const entry = { requests: requests.map((r) => `${r.fieldId}: ${r.texts.join(' | ')}`), status: 'pending' };
    this.log = [entry, ...this.log].slice(0, 5);
    signal.addEventListener('abort', () => {
      if (entry.status === 'pending') this.setStatus(entry, 'aborted (no pending cell left)');
    });
    await wait(500);
    const result = {};
    for (const { fieldId, texts } of requests) {
      result[fieldId] = Object.fromEntries(
        texts.map((text) => [text, PEOPLE.find((p) => p.label.toLowerCase() === text.toLowerCase()) ?? null]),
      );
    }
    if (entry.status === 'pending') this.setStatus(entry, 'answered');
    return result;
  };

  setStatus(entry, status) {
    entry.status = status;
    this.log = [...this.log];
  }

  get logText() {
    if (!this.log.length) return 'No @onResolve call yet.';
    return this.log.map((entry) => `${entry.status}\n  ${entry.requests.join('\n  ')}`).join('\n');
  }

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @onResolve={{this.onResolve}}
      @height={{240}}
      @ariaLabel='Products and contacts'
    />
    <EuiSpacer @size='s' />
    <EuiCodeBlock @fontSize='s' @paddingSize='s'>{{this.logText}}</EuiCodeBlock>
  </template>
}
```
