import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  fillDown,
  tileMatrix
} from '#src/core/index.ts';

import type { EuiSheetField, SheetContext } from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'a' },
  { id: 'b', readOnly: (record) => record.id === 'r2' },
  { id: 'c', readOnly: true }
];

function ctx(records: Row[]): SheetContext<Row> {
  return {
    records,
    fields: FIELDS,
    getRecordId: (record) => record.id,
    types: builtInFieldTypes,
    messages: defaultMessages
  };
}

const rows = (): Row[] => [
  { id: 'r0', a: 'a0', b: 'b0', c: 'c0' },
  { id: 'r1', a: 'a1', b: 'b0', c: 'c1' },
  { id: 'r2', a: 'a2', b: 'b2', c: 'c2' }
];

module('Unit | Sheet | fill', function () {
  test('F1 fillDown over several rows copies each top value down', function (assert) {
    const set = fillDown(ctx(rows()), { top: 0, left: 0, bottom: 2, right: 2 });
    assert.deepEqual(set, {
      source: 'fill',
      patches: [
        { recordId: 'r1', fieldId: 'a', from: 'a1', to: 'a0' },
        { recordId: 'r2', fieldId: 'a', from: 'a2', to: 'a0' }
        // b: r1 already b0 (unchanged, omitted), r2 read-only; c read-only
      ],
      inserts: [],
      rejected: [],
      newOptions: []
    });
  });

  test('F2 fillDown on one cell copies the cell above', function (assert) {
    const set = fillDown(ctx(rows()), { top: 2, left: 0, bottom: 2, right: 0 });
    assert.deepEqual(set?.patches, [
      { recordId: 'r2', fieldId: 'a', from: 'a2', to: 'a1' }
    ]);
    assert.strictEqual(
      fillDown(ctx(rows()), { top: 0, left: 0, bottom: 0, right: 0 }),
      null,
      'the first row has nothing above'
    );
    assert.strictEqual(
      fillDown(ctx(rows()), { top: 1, left: 1, bottom: 1, right: 1 }),
      null,
      'an unchanged value gives nothing'
    );
    assert.strictEqual(
      fillDown(ctx(rows()), { top: 2, left: 1, bottom: 2, right: 2 }),
      null,
      'read-only cells are skipped'
    );
    assert.strictEqual(
      fillDown(
        { ...ctx(rows()), readOnly: true },
        { top: 0, left: 0, bottom: 2, right: 0 }
      ),
      null,
      'a read-only sheet'
    );
  });

  test('F3 tileMatrix', function (assert) {
    assert.deepEqual(
      tileMatrix([['x']], 3, 2),
      [
        ['x', 'x'],
        ['x', 'x'],
        ['x', 'x']
      ],
      '1x1 fills the selection'
    );
    assert.deepEqual(
      tileMatrix([['p'], ['q']], 4, 1),
      [['p'], ['q'], ['p'], ['q']],
      '2x1 into 4x1 tiles'
    );
    const block = [['p'], ['q']];
    assert.strictEqual(
      tileMatrix(block, 3, 1),
      block,
      '2x1 into 3x1 falls back to the block'
    );
    assert.strictEqual(
      tileMatrix(block, 1, 1),
      block,
      'a selection smaller than the block'
    );
    assert.deepEqual(
      tileMatrix([['a', 'b']], 2, 4),
      [
        ['a', 'b', 'a', 'b'],
        ['a', 'b', 'a', 'b']
      ],
      '1x2 into 2x4 tiles both ways'
    );
    const ragged = [['a', 'b'], ['c']];
    assert.strictEqual(
      tileMatrix(ragged, 4, 2),
      ragged,
      'a ragged block is not tiled'
    );
  });
});
