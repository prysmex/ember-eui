import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  summarizeCells
} from '#src/core/index.ts';

import type { EuiSheetField, SheetCellSummaryKind } from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const ctx = { types: builtInFieldTypes, messages: defaultMessages };

const QTY: EuiSheetField<Row> = { id: 'qty', type: 'number' };
const PRICE: EuiSheetField<Row> = {
  id: 'price',
  type: 'currency',
  currency: 'USD'
} as EuiSheetField<Row>;
const NAME: EuiSheetField<Row> = { id: 'name' };

const ROWS: Row[] = [
  { id: 'a', qty: 4, price: 2.5, name: 'Ana' },
  { id: 'b', qty: null, price: 10, name: '' },
  { id: 'c', qty: 1, price: null, name: 'Bo' }
];

const KINDS: SheetCellSummaryKind[] = [
  'count',
  'filled',
  'sum',
  'average',
  'min',
  'max'
];

function all(fields: EuiSheetField<Row>[], records: Row[] = ROWS) {
  return Object.fromEntries(
    KINDS.map((kind) => [kind, summarizeCells(ctx, { records, fields }, kind)])
  );
}

module('Unit | Sheet | summarizeCells', function () {
  test('SL4 sum, average, min, max over two numeric fields; one field uses its format; text only gives ""', function (assert) {
    // numbers: 4, 1 (qty) and 2.5, 10 (price)
    assert.deepEqual(
      all([QTY, PRICE]),
      {
        count: '6',
        filled: '4',
        sum: '17.5',
        average: '4.38',
        min: '1',
        max: '10'
      },
      'two fields: plain numbers (at most two decimals)'
    );
    const price = all([PRICE]);
    const format = (n: number) =>
      builtInFieldTypes['currency']!.format(n, PRICE, {
        record: undefined,
        messages: defaultMessages
      });
    assert.deepEqual(
      price,
      {
        count: '3',
        filled: '2',
        sum: format(12.5),
        average: format(6.25),
        min: format(2.5),
        max: format(10)
      },
      "one field: the field's format"
    );
    assert.true(price['sum']!.includes('12.50'), `formatted (${price['sum']})`);
    assert.deepEqual(
      all([NAME]),
      {
        count: '3',
        filled: '2',
        sum: '',
        average: '',
        min: '',
        max: ''
      },
      'text only: no number'
    );
    assert.deepEqual(
      all([QTY, NAME], []),
      { count: '0', filled: '0', sum: '', average: '', min: '', max: '' },
      'no records'
    );
  });
});
