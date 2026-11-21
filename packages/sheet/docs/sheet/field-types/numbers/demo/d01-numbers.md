---
order: 1
---

# Stock, prices, discounts and time

<EuiText>

Four number types on safety equipment: **Stock** is a `number` (`12`,
`1,200`; `min: 0`), **Price** a `currency` in Mexican pesos
(`currency: 'MXN'`, `locale: 'es-MX'`; type `$1,234.5` or `MXN 12`),
**Discount** a `percent` stored as a fraction (type `15%` or `15`; at
most 50%, `max: 0.5`) and **Fitting time** a `duration` stored in
seconds (type `1:30`, `1h 30m`, `1.5h` or `90`, minutes). They are
right-aligned and their header menus sort "Low-High". The bar under the
grid sums them with `summarize`, through each type's `toNumber` and
`format`. Select Stock of rows 1 and 2 and drag the fill handle down: a
number with a step continues it.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import {
  builtInFieldTypes,
  defaultMessages,
  EuiSheet,
  localRecords,
  summarize
} from '@ember-eui/sheet';
import { products } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'name', label: 'Product', required: true, width: 200 },
  { id: 'stock', label: 'Stock', type: 'number', min: 0 },
  {
    id: 'price',
    label: 'Price',
    type: 'currency',
    currency: 'MXN',
    locale: 'es-MX',
    min: 0
  },
  { id: 'discount', label: 'Discount', type: 'percent', min: 0, max: 0.5 },
  { id: 'time', label: 'Fitting time', type: 'duration' }
];

const CTX = { types: builtInFieldTypes, messages: defaultMessages };

export default class NumberTypes extends Component {
  getId = (record) => record.id;
  store = localRecords(products(), { getRecordId: this.getId, fields: FIELDS });

  get summary() {
    const records = this.store.records;
    const [, stock, price, discount, time] = FIELDS;

    return {
      '': `${records.length} products`,
      stock: `Sum ${summarize(CTX, records, stock, 'sum')}`,
      price: `Avg ${summarize(CTX, records, price, 'average')}`,
      discount: `Max ${summarize(CTX, records, discount, 'max')}`,
      time: `Sum ${summarize(CTX, records, time, 'sum')}`
    };
  }

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @summary={{this.summary}}
      @height={{260}}
      @ariaLabel='Equipment'
    />
  </template>
}
```
