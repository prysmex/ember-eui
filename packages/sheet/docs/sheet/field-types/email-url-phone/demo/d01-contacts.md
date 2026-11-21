---
order: 1
---

# Supplier contacts

<EuiText>

**Website** is a `url`, **Email** an `email` and **Phone** a `phone`:
strings drawn as links. A click on the text opens it in a new tab (an
email as `mailto:`, a phone as `tel:`); a click beside the text selects
the cell, and the row menu (right-click) has "Open link". A website
without a scheme gets `https://`. The third supplier's values break
each rule: `eppbajio` is not a web address (a host needs a dot),
`compras(at)eppbajio.mx` is not an email and `call the office` is not a
phone (digits, spaces and `+ ( ) -`). They are stored and marked, and
open nothing.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { suppliers } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'name', label: 'Supplier', required: true, width: 190 },
  { id: 'website', label: 'Website', type: 'url', width: 260 },
  { id: 'email', label: 'Email', type: 'email', width: 250 },
  { id: 'phone', label: 'Phone', type: 'phone', width: 170 }
];

export default class Contacts extends Component {
  getId = (record) => record.id;
  store = localRecords(suppliers(), {
    getRecordId: this.getId,
    fields: FIELDS
  });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{220}}
      @ariaLabel='Suppliers'
    />
  </template>
}
```
