import { module, test } from 'qunit';

import {
  clearRange,
  commitPatch,
  parseTsv,
  pasteMatrix,
  rangeMatrix,
  toRange,
  toTsv
} from '../../spikes/sheet/change-set.ts';
import { localRecords } from '../../spikes/sheet/local-records.ts';

import type {
  EuiSheetField,
  SheetContext
} from '../../spikes/sheet/change-set.ts';

interface Row {
  id: string;
  a: unknown;
  b: unknown;
  c: unknown;
}

const FIELDS: EuiSheetField[] = [{ id: 'a' }, { id: 'b' }, { id: 'c' }];

function ctx(
  records: Row[],
  fields: EuiSheetField[] = FIELDS
): SheetContext<Row> {
  return { records, fields, getRecordId: (record) => record.id };
}

const rows = (): Row[] => [
  { id: 'r0', a: 'a0', b: 'b0', c: 'c0' },
  { id: 'r1', a: 'a1', b: 'b1', c: 'c1' }
];

module('Unit | Spike | EuiSheet change sets', function () {
  test('toRange normalizes two positions', function (assert) {
    assert.deepEqual(toRange({ row: 3, col: 0 }, { row: 1, col: 2 }), {
      top: 1,
      left: 0,
      bottom: 3,
      right: 2
    });
  });

  test('parseTsv', function (assert) {
    assert.deepEqual(parseTsv('a\tb\nc\td'), [
      ['a', 'b'],
      ['c', 'd']
    ]);
    assert.deepEqual(
      parseTsv('a\tb\r\nc\td\r\n'),
      [
        ['a', 'b'],
        ['c', 'd']
      ],
      '\\r\\n, one trailing newline dropped'
    );
    assert.deepEqual(
      parseTsv('a\n'),
      [['a']],
      'only one trailing empty line is dropped'
    );
    assert.deepEqual(parseTsv('a\n\n'), [['a'], ['']]);
    assert.deepEqual(parseTsv('a\t\tc'), [['a', '', 'c']], 'empty cells kept');
    assert.deepEqual(parseTsv('v'), [['v']]);
  });

  test('toTsv(parseTsv(x)) round-trips a block without trailing newline', function (assert) {
    const block = 'a\tb\tc\n\te\tf\ng\th\t';
    assert.strictEqual(toTsv(parseTsv(block)), block);
  });

  test('commitPatch', function (assert) {
    const records = rows();
    assert.deepEqual(commitPatch(ctx(records), { row: 1, col: 1 }, 'x'), {
      source: 'edit',
      patches: [{ recordId: 'r1', fieldId: 'b', from: 'b1', to: 'x' }],
      inserts: []
    });
    assert.strictEqual(
      commitPatch(ctx(records), { row: 1, col: 1 }, 'b1'),
      null,
      'unchanged'
    );
    const readOnly = [{ id: 'a' }, { id: 'b', readOnly: true }, { id: 'c' }];
    assert.strictEqual(
      commitPatch(ctx(records, readOnly), { row: 1, col: 1 }, 'x'),
      null
    );
    const numeric: EuiSheetField[] = [
      { id: 'a', parse: (text) => Number(text) }
    ];
    const numbers = [{ id: 'n', a: 1, b: null, c: null }];
    assert.deepEqual(
      commitPatch(ctx(numbers, numeric), { row: 0, col: 0 }, '2')?.patches,
      [{ recordId: 'n', fieldId: 'a', from: 1, to: 2 }],
      'parse applied'
    );
    assert.strictEqual(
      commitPatch(ctx(numbers, numeric), { row: 0, col: 0 }, '1'),
      null
    );
  });

  test('clearRange', function (assert) {
    const records: Row[] = [
      { id: 'r0', a: 'a0', b: '', c: 'c0' },
      { id: 'r1', a: 'a1', b: 'b1', c: 'c1' }
    ];
    const fields = [{ id: 'a' }, { id: 'b' }, { id: 'c', readOnly: true }];
    assert.deepEqual(
      clearRange(ctx(records, fields), {
        top: 0,
        left: 0,
        bottom: 1,
        right: 2
      }),
      {
        source: 'clear',
        patches: [
          { recordId: 'r0', fieldId: 'a', from: 'a0', to: '' },
          { recordId: 'r1', fieldId: 'a', from: 'a1', to: '' },
          { recordId: 'r1', fieldId: 'b', from: 'b1', to: '' }
        ],
        inserts: []
      },
      'skips empty and read-only cells'
    );
    assert.strictEqual(
      clearRange(ctx(records, fields), {
        top: 0,
        left: 1,
        bottom: 0,
        right: 2
      }),
      null,
      'null when nothing changes'
    );
  });

  test('pasteMatrix', function (assert) {
    const records = rows();
    const result = pasteMatrix(ctx(records), { row: 1, col: 1 }, [
      ['x', 'y', 'dropped'],
      ['p'],
      ['q', 'r']
    ]);
    assert.deepEqual(
      result,
      {
        source: 'paste',
        patches: [
          { recordId: 'r1', fieldId: 'b', from: 'b1', to: 'x' },
          { recordId: 'r1', fieldId: 'c', from: 'c1', to: 'y' }
        ],
        inserts: [
          { tempId: 'new-0', index: 2, values: { b: 'p' } },
          { tempId: 'new-1', index: 3, values: { b: 'q', c: 'r' } }
        ]
      },
      'clips at the last field, ragged rows, inserts past the end with increasing index'
    );
    assert.deepEqual(
      pasteMatrix(ctx(records), { row: 0, col: 0 }, [['a0', 'B']])?.patches,
      [{ recordId: 'r0', fieldId: 'b', from: 'b0', to: 'B' }],
      'unchanged values omitted'
    );
    assert.strictEqual(
      pasteMatrix(ctx(records), { row: 0, col: 0 }, [['a0']]),
      null
    );
    const readOnly = [{ id: 'a' }, { id: 'b', readOnly: true }, { id: 'c' }];
    assert.deepEqual(
      pasteMatrix(ctx(records, readOnly), { row: 0, col: 0 }, [
        ['1', '2', '3']
      ])?.patches.map((patch) => patch.fieldId),
      ['a', 'c'],
      'read-only fields skipped'
    );
  });

  test('rangeMatrix', function (assert) {
    const fields: EuiSheetField[] = [
      { id: 'a', format: (value) => `<${String(value as string)}>` },
      { id: 'b' },
      { id: 'c' }
    ];
    const records: Row[] = [
      { id: 'r0', a: 'a0', b: null, c: 'c0' },
      { id: 'r1', a: 'a1', b: 7, c: 'c1' }
    ];
    assert.deepEqual(
      rangeMatrix(ctx(records, fields), {
        top: 0,
        left: 0,
        bottom: 5,
        right: 1
      }),
      [
        ['<a0>', ''],
        ['<a1>', '7']
      ],
      'format applied, clamped to existing rows'
    );
  });

  test('localRecords().apply', function (assert) {
    const initial = rows();
    const store = localRecords(initial, { getRecordId: (record) => record.id });
    store.apply({
      source: 'paste',
      patches: [{ recordId: 'r1', fieldId: 'a', from: 'a1', to: 'z' }],
      inserts: [
        { tempId: 'new-1', index: 3, values: { a: 'late' } },
        { tempId: 'new-0', index: 2, values: { a: 'early' } }
      ]
    });
    assert.strictEqual(
      store.records[0],
      initial[0],
      'unpatched records keep identity'
    );
    assert.notStrictEqual(
      store.records[1],
      initial[1],
      'patched records are new objects'
    );
    assert.deepEqual(store.records[1], { id: 'r1', a: 'z', b: 'b1', c: 'c1' });
    assert.strictEqual(initial[1]!.a, 'a1', 'the original is untouched');
    assert.deepEqual(
      store.records.slice(2),
      [
        { id: 'new-0', a: 'early' },
        { id: 'new-1', a: 'late' }
      ] as unknown as Row[],
      'inserts appended in index order'
    );
    assert.strictEqual(store.log.length, 1);
    store.apply({ source: 'clear', patches: [], inserts: [] });
    assert.strictEqual(store.log.length, 2, 'log grows');
  });
});
