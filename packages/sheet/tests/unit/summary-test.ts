import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  summarize
} from '#src/core/index.ts';

import type {
  EuiSheetField,
  FieldTypeRegistry,
  SheetSummaryKind
} from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const ctx = { types: builtInFieldTypes, messages: defaultMessages };

const QTY: EuiSheetField<Row> = { id: 'qty', type: 'number' };
const DUE: EuiSheetField<Row> = { id: 'due', type: 'date' };
const DONE: EuiSheetField<Row> = { id: 'done', type: 'checkbox' };
const CITY: EuiSheetField<Row> = { id: 'city' };

const ROWS: Row[] = [
  { id: 'a', qty: 4, due: '2026-03-01', done: true, city: 'Lima' },
  { id: 'b', qty: null, due: null, done: false, city: '' },
  { id: 'c', qty: 1.5, due: '2025-12-31', done: true, city: 'lima' },
  { id: 'd', qty: 10, due: '2026-11-19', city: 'Lima' },
  { id: 'e', qty: -2, due: '', done: false, city: 'Madrid' }
];

function all(field: EuiSheetField<Row>, kinds: SheetSummaryKind[]) {
  return Object.fromEntries(
    kinds.map((kind) => [kind, summarize(ctx, ROWS, field, kind)])
  );
}

module('Unit | Sheet | summarize', function () {
  test('SM1 each kind on numbers with empties', function (assert) {
    assert.deepEqual(
      all(QTY, [
        'count',
        'filled',
        'empty',
        'percentFilled',
        'unique',
        'sum',
        'average',
        'min',
        'max'
      ]),
      {
        count: '5',
        filled: '4',
        empty: '1',
        percentFilled: '80%',
        unique: '4',
        sum: '13.5',
        average: '3.375',
        min: '-2',
        max: '10'
      }
    );
    assert.strictEqual(summarize(ctx, [], QTY, 'sum'), '', 'nothing to sum');
    assert.strictEqual(summarize(ctx, [], QTY, 'count'), '0');
    assert.strictEqual(
      summarize(ctx, [], QTY, 'percentFilled'),
      '',
      'no percent of nothing'
    );
  });

  test('SM2 date min and max by compare; no sum of dates', function (assert) {
    assert.deepEqual(all(DUE, ['min', 'max', 'filled', 'sum', 'average']), {
      min: '31/12/2025',
      max: '19/11/2026',
      filled: '3',
      sum: '',
      average: ''
    });
  });

  test('SM3 checkbox: checked, unchecked, filled', function (assert) {
    assert.deepEqual(all(DONE, ['checked', 'unchecked', 'filled', 'empty']), {
      checked: '2',
      unchecked: '3',
      filled: '2',
      empty: '3'
    });
  });

  test('SM4 unique counts distinct non-empty values by their copy text', function (assert) {
    assert.strictEqual(
      summarize(ctx, ROWS, CITY, 'unique'),
      '3',
      'Lima, lima, Madrid (case counts; the empty one does not)'
    );
    assert.strictEqual(
      summarize(ctx, ROWS, CITY, 'min'),
      ['Lima', 'lima'].sort((a, b) => a.localeCompare(b))[0],
      'text min by compare (localeCompare)'
    );
    assert.strictEqual(summarize(ctx, ROWS, CITY, 'max'), 'Madrid');
  });

  test('SM5 formatted through the type', function (assert) {
    const comma: EuiSheetField<Row> = {
      id: 'qty',
      type: 'number',
      decimalSeparator: ','
    };
    assert.strictEqual(summarize(ctx, ROWS, comma, 'sum'), '13,5');
    const types: FieldTypeRegistry = {
      ...builtInFieldTypes,
      money: {
        parse: (text) => ({ value: Number(text) }),
        format: (value) =>
          value == null ? '' : `$${Number(value).toFixed(2)}`,
        toNumber: (value) => (typeof value === 'number' ? value : null)
      }
    };
    const money: EuiSheetField<Row> = { id: 'qty', type: 'money' };
    assert.strictEqual(
      summarize({ types, messages: defaultMessages }, ROWS, money, 'average'),
      '$3.38',
      'an app type with toNumber and its own format'
    );
    const plain: EuiSheetField<Row> = { id: 'city' };
    assert.strictEqual(
      summarize(ctx, ROWS, plain, 'sum'),
      '',
      'a type without toNumber has no sum'
    );
  });
});
