---
order: 2
---

# Saving: what the server refused, until it is fixed

<EuiText>

Each change set is saved at once: the store applies it, and a fake
server answers 600 ms later. The server refuses two things: a stock
below the units already reserved for open orders, and an SKU another
product has. What it refuses comes back as `@cellErrors` on those cells
(shown after the sheet's own messages), and stays until the cell is
written again: the next change set for that cell takes its error away
before it is sent, so a fix clears it at once, and a second refusal
brings it back. Try a stock of `5` on Hard hat (10 reserved), or the SKU
`7501234567906` on another row; then fix it, or press Ctrl/Cmd+Z.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { products, wait } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'sku', label: 'SKU', required: true, width: 150 },
  { id: 'name', label: 'Product', required: true, width: 180 },
  { id: 'stock', label: 'Stock', type: 'number', min: 0 },
  { id: 'reserved', label: 'Reserved', type: 'number', readOnly: true }
];

const RESERVED = { p1: 10, p2: 30, p3: 18, p4: 0, p5: 50 };

/** A fake API: refuses the patches it cannot save, with a message each. */
async function save(changeSet, records) {
  await wait(600);
  const refused = [];
  for (const { recordId, fieldId, to } of changeSet.patches) {
    const record = records.find((r) => r.id === recordId);
    if (fieldId === 'stock' && to !== null && to < record.reserved) {
      refused.push({
        recordId,
        fieldId,
        message: `${record.reserved} units are reserved for open orders`
      });
    }
    if (
      fieldId === 'sku' &&
      records.some((r) => r.id !== recordId && r.sku === to)
    ) {
      refused.push({
        recordId,
        fieldId,
        message: 'Another product has this SKU'
      });
    }
  }
  return refused;
}

export default class SaveRejections extends Component {
  getId = (record) => record.id;
  store = localRecords(
    products().map((product) => ({
      ...product,
      reserved: RESERVED[product.id]
    })),
    { getRecordId: this.getId, fields: FIELDS }
  );

  @tracked cellErrors = {};
  @tracked status = 'Edit a Stock or an SKU.';

  onChange = async (changeSet) => {
    this.store.apply(changeSet);

    // a cell written again loses the server's old error
    const errors = structuredClone(this.cellErrors);
    for (const { recordId, fieldId } of changeSet.patches)
      delete errors[recordId]?.[fieldId];
    this.cellErrors = errors;

    this.status = 'Saving…';
    const refused = await save(changeSet, this.store.records);
    const next = structuredClone(this.cellErrors);
    for (const { recordId, fieldId, message } of refused)
      (next[recordId] ??= {})[fieldId] = message;
    this.cellErrors = next;
    this.status = refused.length
      ? `Saved, ${refused.length} cell refused by the server.`
      : 'Saved.';
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @cellErrors={{this.cellErrors}}
      @height={{230}}
      @ariaLabel='Stock'
    />
    <p>{{this.status}}</p>
  </template>
}
```
