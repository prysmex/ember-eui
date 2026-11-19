import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  fillDown,
  fillRange,
  fillRight,
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

  test('F4 fillRight: each row’s left value to the right; one column from the left', function (assert) {
    const records: Row[] = [
      { id: 'r0', x: 'x0', y: 'y0', z: 'z0' },
      { id: 'r1', x: 'x1', y: 'x1', z: 'z1' }
    ];
    const context = {
      ...ctx(records),
      fields: [{ id: 'x' }, { id: 'y' }, { id: 'z' }] as EuiSheetField<Row>[]
    };
    const set = fillRight(context, { top: 0, left: 0, bottom: 1, right: 2 });
    assert.strictEqual(set?.source, 'fill');
    assert.deepEqual(set?.patches, [
      { recordId: 'r0', fieldId: 'y', from: 'y0', to: 'x0' },
      { recordId: 'r0', fieldId: 'z', from: 'z0', to: 'x0' },
      // r1's y already holds x1: no patch
      { recordId: 'r1', fieldId: 'z', from: 'z1', to: 'x1' }
    ]);
    const one = fillRight(context, { top: 0, left: 1, bottom: 0, right: 1 });
    assert.deepEqual(one?.patches, [
      { recordId: 'r0', fieldId: 'y', from: 'y0', to: 'x0' }
    ]);
    assert.strictEqual(
      fillRight(context, { top: 0, left: 0, bottom: 0, right: 0 }),
      null,
      'nothing left of the first column'
    );
    // read-only cells are skipped (b on r2, c always)
    const guarded = fillRight(ctx(rows()), {
      top: 2,
      left: 0,
      bottom: 2,
      right: 2
    });
    assert.strictEqual(guarded, null);
  });

  test('F4b fillRight across types goes through text, like a paste', function (assert) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'label' },
      { id: 'count', type: 'number' },
      { id: 'done', type: 'checkbox' }
    ];
    const context = {
      ...ctx([
        { id: 'r0', label: '12', count: 1, done: false },
        { id: 'r1', label: 'abc', count: 1, done: false }
      ]),
      fields
    };
    const set = fillRight(context, { top: 0, left: 0, bottom: 1, right: 1 });
    assert.deepEqual(set?.patches, [
      { recordId: 'r0', fieldId: 'count', from: 1, to: 12 }
    ]);
    assert.deepEqual(
      set?.rejected.map((r) => [r.recordId, r.fieldId, r.text]),
      [['r1', 'count', 'abc']],
      'a text the number cannot read is a rejection'
    );
  });

  const numbers = (values: unknown[]): SheetContext<Row> => ({
    ...ctx(values.map((n, i) => ({ id: `r${i}`, n }))),
    fields: [{ id: 'n', type: 'number' }]
  });
  const column = (set: ReturnType<typeof fillRange>) =>
    set?.patches.map((patch) => [patch.recordId, patch.to]);

  test('F5 fillRange down, up, right, left', function (assert) {
    // down: two text samples repeat
    const text = {
      ...ctx(['a', 'b', '', '', ''].map((t, i) => ({ id: `r${i}`, t }))),
      fields: [{ id: 't' }] as EuiSheetField<Row>[]
    };
    assert.deepEqual(
      column(
        fillRange(
          text,
          { top: 0, left: 0, bottom: 1, right: 0 },
          { top: 0, left: 0, bottom: 4, right: 0 }
        )
      ),
      [
        ['r2', 'a'],
        ['r3', 'b'],
        ['r4', 'a']
      ]
    );
    // up: the pattern ends next to the samples
    const up = {
      ...ctx(['', '', '', 'a', 'b'].map((t, i) => ({ id: `r${i}`, t }))),
      fields: [{ id: 't' }] as EuiSheetField<Row>[]
    };
    assert.deepEqual(
      column(
        fillRange(
          up,
          { top: 3, left: 0, bottom: 4, right: 0 },
          { top: 0, left: 0, bottom: 4, right: 0 }
        )
      ),
      [
        ['r2', 'b'],
        ['r1', 'a'],
        ['r0', 'b']
      ]
    );
    // right and left: along a row of number fields, a series
    const wide = {
      ...ctx([{ id: 'r0', a: null, b: 5, c: 6, d: null, e: null }]),
      fields: ['a', 'b', 'c', 'd', 'e'].map((id) => ({
        id,
        type: 'number'
      })) as EuiSheetField<Row>[]
    };
    assert.deepEqual(
      fillRange(
        wide,
        { top: 0, left: 1, bottom: 0, right: 2 },
        { top: 0, left: 1, bottom: 0, right: 4 }
      )?.patches.map((patch) => [patch.fieldId, patch.to]),
      [
        ['d', 7],
        ['e', 8]
      ]
    );
    assert.deepEqual(
      fillRange(
        wide,
        { top: 0, left: 1, bottom: 0, right: 2 },
        { top: 0, left: 0, bottom: 0, right: 2 }
      )?.patches.map((patch) => [patch.fieldId, patch.to]),
      [['a', 4]]
    );
    // the target past the last record is clamped; the same range: null
    assert.strictEqual(
      fillRange(
        text,
        { top: 0, left: 0, bottom: 1, right: 0 },
        { top: 0, left: 0, bottom: 1, right: 0 }
      ),
      null
    );
    assert.strictEqual(
      column(
        fillRange(
          text,
          { top: 0, left: 0, bottom: 0, right: 0 },
          { top: 0, left: 0, bottom: 99, right: 0 }
        )
      )?.length,
      4,
      'to the last record'
    );
  });

  test('F6 number series: 1, 2 → 3, 4; one sample copies; 1, 2, 4 repeats', function (assert) {
    const source = { top: 0, left: 0, bottom: 1, right: 0 };
    const target = { top: 0, left: 0, bottom: 3, right: 0 };
    assert.deepEqual(
      column(fillRange(numbers([1, 2, null, null]), source, target)),
      [
        ['r2', 3],
        ['r3', 4]
      ]
    );
    assert.deepEqual(
      column(
        fillRange(
          numbers([7, null, null]),
          { top: 0, left: 0, bottom: 0, right: 0 },
          { top: 0, left: 0, bottom: 2, right: 0 }
        )
      ),
      [
        ['r1', 7],
        ['r2', 7]
      ],
      'one sample is copied'
    );
    assert.deepEqual(
      column(
        fillRange(
          numbers([1, 2, 4, null, null, null]),
          { top: 0, left: 0, bottom: 2, right: 0 },
          { top: 0, left: 0, bottom: 5, right: 0 }
        )
      ),
      [
        ['r3', 1],
        ['r4', 2],
        ['r5', 4]
      ],
      'no constant step: the samples repeat'
    );
    assert.deepEqual(
      column(
        fillRange(
          numbers([null, null, 0.3, 0.2]),
          { top: 2, left: 0, bottom: 3, right: 0 },
          { top: 0, left: 0, bottom: 3, right: 0 }
        )
      ),
      [
        ['r1', 0.4],
        ['r0', 0.5]
      ],
      'up continues backwards, without float noise'
    );
    // the other numeric types
    const typed = (type: string, values: unknown[], extra = {}) => ({
      ...ctx(values.map((n, i) => ({ id: `r${i}`, n }))),
      fields: [{ id: 'n', type, ...extra }] as EuiSheetField<Row>[]
    });
    assert.deepEqual(
      column(
        fillRange(typed('percent', [0.1, 0.2, null, null]), source, target)
      ),
      [
        ['r2', 0.3],
        ['r3', 0.4]
      ]
    );
    assert.deepEqual(
      column(
        fillRange(
          typed('currency', [10, 12.5, null, null], { currency: 'USD' }),
          source,
          target
        )
      ),
      [
        ['r2', 15],
        ['r3', 17.5]
      ]
    );
    assert.deepEqual(
      column(
        fillRange(typed('duration', [60, 90, null, null]), source, target)
      ),
      [
        ['r2', 120],
        ['r3', 150]
      ]
    );
    assert.deepEqual(
      column(fillRange(typed('rating', [4, 5, null, null]), source, target)),
      [
        ['r2', 5],
        ['r3', 5]
      ],
      'a rating stays within its max'
    );
  });

  test('F7 date series: one sample by a day; a weekly step', function (assert) {
    const dates = (values: unknown[]) => ({
      ...ctx(values.map((d, i) => ({ id: `r${i}`, d }))),
      fields: [{ id: 'd', type: 'date' }] as EuiSheetField<Row>[]
    });
    assert.deepEqual(
      column(
        fillRange(
          dates(['2026-02-27', null, null, null]),
          { top: 0, left: 0, bottom: 0, right: 0 },
          { top: 0, left: 0, bottom: 3, right: 0 }
        )
      ),
      [
        ['r1', '2026-02-28'],
        ['r2', '2026-03-01'],
        ['r3', '2026-03-02']
      ]
    );
    assert.deepEqual(
      column(
        fillRange(
          dates(['2026-01-01', '2026-01-08', null, null]),
          { top: 0, left: 0, bottom: 1, right: 0 },
          { top: 0, left: 0, bottom: 3, right: 0 }
        )
      ),
      [
        ['r2', '2026-01-15'],
        ['r3', '2026-01-22']
      ]
    );
    assert.deepEqual(
      column(
        fillRange(
          dates([null, '2026-01-01']),
          { top: 1, left: 0, bottom: 1, right: 0 },
          { top: 0, left: 0, bottom: 1, right: 0 }
        )
      ),
      [['r0', '2025-12-31']],
      'up goes back a day'
    );
  });

  test('F8 copy: true always repeats', function (assert) {
    assert.deepEqual(
      column(
        fillRange(
          numbers([1, 2, null, null]),
          { top: 0, left: 0, bottom: 1, right: 0 },
          { top: 0, left: 0, bottom: 3, right: 0 },
          { copy: true }
        )
      ),
      [
        ['r2', 1],
        ['r3', 2]
      ]
    );
  });

  test('F9 read-only cells are skipped; the series still counts them; values by reference', function (assert) {
    const list = ['x'];
    const context: SheetContext<Row> = {
      ...ctx([
        { id: 'r0', n: 1, tags: list },
        { id: 'r1', n: 2, tags: null },
        { id: 'r2', n: null, tags: null, locked: true },
        { id: 'r3', n: null, tags: null }
      ]),
      fields: [
        { id: 'n', type: 'number', readOnly: (record) => !!record['locked'] },
        {
          id: 'tags',
          type: 'multiSelect',
          options: [{ value: 'x', label: 'X' }]
        }
      ]
    };
    const set = fillRange(
      context,
      { top: 0, left: 0, bottom: 1, right: 1 },
      { top: 0, left: 0, bottom: 3, right: 1 }
    );
    assert.deepEqual(
      set?.patches.map((patch) => [patch.recordId, patch.fieldId, patch.to]),
      [
        // r2 is read-only for n; r3 gets the series' second value
        ['r3', 'n', 4],
        // tags repeat (no series); r3 would get null, which it holds
        ['r2', 'tags', ['x']]
      ]
    );
    assert.strictEqual(set?.patches[1]?.to, list, 'the same array, not a copy');
  });
});
