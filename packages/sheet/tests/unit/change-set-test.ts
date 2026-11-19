import { module, test } from 'qunit';

import {
  applyChangeSet,
  applyNewOptions,
  builtInFieldTypes,
  clearRange,
  commitText,
  commitValue,
  defaultMessages,
  deleteRecords,
  duplicateRecords,
  insertRecords,
  mergeChangeSets,
  pasteMatrix,
  rangeMatrix,
  toRange
} from '#src/core/index.ts';
import { localRecords } from '#src/local-records.ts';

import type {
  ChangeSet,
  EuiSheetField,
  SheetContext
} from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const FIELDS: EuiSheetField<Row>[] = [{ id: 'a' }, { id: 'b' }, { id: 'c' }];

function ctx(
  records: Row[],
  fields: EuiSheetField<Row>[] = FIELDS,
  extra: Partial<SheetContext<Row>> = {}
): SheetContext<Row> {
  return {
    records,
    fields,
    getRecordId: (record) => record.id,
    types: builtInFieldTypes,
    messages: defaultMessages,
    ...extra
  };
}

const rows = (): Row[] => [
  { id: 'r0', a: 'a0', b: 'b0', c: 'c0' },
  { id: 'r1', a: 'a1', b: 'b1', c: 'c1' }
];

const empty = { rejected: [], newOptions: [] };

const STATUS: EuiSheetField<Row> = {
  id: 'status',
  type: 'singleSelect',
  options: [
    { value: 'open', label: 'Open' },
    { value: 'closed', label: 'Closed' }
  ]
};

module('Unit | Sheet | change sets', function () {
  test('U1 toRange normalizes two positions', function (assert) {
    assert.deepEqual(toRange({ row: 3, col: 0 }, { row: 1, col: 2 }), {
      top: 1,
      left: 0,
      bottom: 3,
      right: 2
    });
  });

  test('U4 commitText', function (assert) {
    const records = rows();
    assert.deepEqual(commitText(ctx(records), { row: 1, col: 1 }, 'x'), {
      source: 'edit',
      patches: [{ recordId: 'r1', fieldId: 'b', from: 'b1', to: 'x' }],
      inserts: [],
      ...empty
    });
    assert.strictEqual(
      commitText(ctx(records), { row: 1, col: 1 }, 'b1'),
      null,
      'unchanged'
    );
    const readOnly = [{ id: 'a' }, { id: 'b', readOnly: true }, { id: 'c' }];
    assert.strictEqual(
      commitText(ctx(records, readOnly), { row: 1, col: 1 }, 'x'),
      null,
      'read-only'
    );
    const numeric: EuiSheetField<Row>[] = [{ id: 'a', type: 'number' }];
    const numbers: Row[] = [{ id: 'n', a: 1 }];
    assert.deepEqual(
      commitText(ctx(numbers, numeric), { row: 0, col: 0 }, '7')?.patches,
      [{ recordId: 'n', fieldId: 'a', from: 1, to: 7 }],
      'parse applied'
    );
    assert.strictEqual(
      commitText(ctx(numbers, numeric), { row: 0, col: 0 }, '1'),
      null
    );
    assert.strictEqual(
      commitText(ctx(numbers, numeric), { row: 5, col: 0 }, '1'),
      null,
      'no such cell'
    );
  });

  test('U5 clearRange', function (assert) {
    const records: Row[] = [
      { id: 'r0', a: 'a0', b: '', c: 'c0', n: 5 },
      { id: 'r1', a: 'a1', b: 'b1', c: 'c1', n: null }
    ];
    const fields: EuiSheetField<Row>[] = [
      { id: 'a' },
      { id: 'b' },
      { id: 'c', readOnly: true },
      { id: 'n', type: 'number' }
    ];
    assert.deepEqual(
      clearRange(ctx(records, fields), {
        top: 0,
        left: 0,
        bottom: 1,
        right: 3
      }),
      {
        source: 'clear',
        patches: [
          { recordId: 'r0', fieldId: 'a', from: 'a0', to: '' },
          { recordId: 'r0', fieldId: 'n', from: 5, to: null },
          { recordId: 'r1', fieldId: 'a', from: 'a1', to: '' },
          { recordId: 'r1', fieldId: 'b', from: 'b1', to: '' }
        ],
        inserts: [],
        ...empty
      },
      'text clears to "", number to null; skips empty and read-only cells'
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

  test('U6 pasteMatrix', function (assert) {
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
          {
            tempId: 'new-0',
            index: 2,
            values: { b: 'p' },
            anchor: { recordId: 'r1', position: 'after' }
          },
          {
            tempId: 'new-1',
            index: 3,
            values: { b: 'q', c: 'r' },
            anchor: { recordId: 'new-0', position: 'after' }
          }
        ],
        ...empty
      },
      'clips at the last field, ragged rows, inserts past the end with increasing index, anchored after the last record and each other (v0.2)'
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
    let n = 10;
    assert.deepEqual(
      pasteMatrix(ctx(records), { row: 2, col: 0 }, [['z'], ['w']], {
        nextTempId: () => `t${n++}`
      })?.inserts.map((insert) => insert.tempId),
      ['t10', 't11'],
      'nextTempId'
    );
  });

  test('U7 rangeMatrix', function (assert) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'a', type: 'date' },
      { id: 'b' },
      { id: 'c' }
    ];
    const records: Row[] = [
      { id: 'r0', a: '2026-11-19', b: null, c: 'c0' },
      { id: 'r1', a: null, b: 7, c: 'c1' }
    ];
    assert.deepEqual(
      rangeMatrix(ctx(records, fields), {
        top: 0,
        left: 0,
        bottom: 5,
        right: 1
      }),
      [
        ['2026-11-19', ''],
        ['', '7']
      ],
      'copyText applied (ISO, not the display format), clamped to existing rows'
    );
  });

  test('U8 localRecords().apply', function (assert) {
    const initial = rows();
    const store = localRecords(initial, { getRecordId: (record) => record.id });
    const set: ChangeSet = {
      source: 'paste',
      patches: [{ recordId: 'r1', fieldId: 'a', from: 'a1', to: 'z' }],
      inserts: [
        { tempId: 'new-1', index: 3, values: { a: 'late' } },
        { tempId: 'new-0', index: 2, values: { a: 'early' } }
      ],
      ...empty
    };
    const pure = applyChangeSet(initial, set, {
      getRecordId: (record) => record.id
    });
    store.apply(set);
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
    assert.strictEqual(initial[1]!['a'], 'a1', 'the original is untouched');
    assert.deepEqual(
      store.records.slice(2),
      [
        { id: 'new-0', a: 'early' },
        { id: 'new-1', a: 'late' }
      ],
      'inserts appended in index order'
    );
    assert.deepEqual(store.records, pure, 'same as a pure applyChangeSet');
    assert.strictEqual(store.log.length, 1);
    store.apply({ source: 'clear', patches: [], inserts: [], ...empty });
    assert.strictEqual(store.log.length, 2, 'log grows');
  });

  test('U9 commitText of an unreadable text gives a rejection, no patch', function (assert) {
    const fields: EuiSheetField<Row>[] = [{ id: 'qty', type: 'number' }];
    assert.deepEqual(
      commitText(
        ctx([{ id: 'r0', qty: 1 }], fields),
        { row: 0, col: 0 },
        'abc'
      ),
      {
        source: 'edit',
        patches: [],
        inserts: [],
        rejected: [
          {
            recordId: 'r0',
            fieldId: 'qty',
            text: 'abc',
            message: '"abc" is not a number'
          }
        ],
        newOptions: []
      }
    );
  });

  test('U10 commitValue', function (assert) {
    const records = rows();
    assert.deepEqual(commitValue(ctx(records), { row: 0, col: 2 }, 'v'), {
      source: 'edit',
      patches: [{ recordId: 'r0', fieldId: 'c', from: 'c0', to: 'v' }],
      inserts: [],
      ...empty
    });
    assert.strictEqual(
      commitValue(ctx(records), { row: 0, col: 2 }, 'c0'),
      null,
      'unchanged'
    );
    assert.strictEqual(
      commitValue(
        ctx(records, [{ id: 'a', readOnly: () => true }]),
        { row: 0, col: 0 },
        'v'
      ),
      null,
      'read-only'
    );
  });

  test('U11 readOnly as a function of the record, and sheet-level readOnly', function (assert) {
    const records: Row[] = [
      { id: 'r0', a: 'a0', b: 'b0', locked: false },
      { id: 'r1', a: 'a1', b: 'b1', locked: true }
    ];
    const fields: EuiSheetField<Row>[] = [
      { id: 'a' },
      { id: 'b', readOnly: (record) => record['locked'] === true }
    ];
    const all = { top: 0, left: 0, bottom: 1, right: 1 };
    assert.deepEqual(
      clearRange(ctx(records, fields), all)?.patches.map(
        (patch) => `${patch.recordId}.${patch.fieldId}`
      ),
      ['r0.a', 'r0.b', 'r1.a'],
      'clearRange skips only the locked record'
    );
    assert.deepEqual(
      pasteMatrix(ctx(records, fields), { row: 0, col: 0 }, [
        ['x', 'y'],
        ['p', 'q']
      ])?.patches.map((patch) => `${patch.recordId}.${patch.fieldId}`),
      ['r0.a', 'r0.b', 'r1.a'],
      'pasteMatrix skips only the locked record'
    );
    const locked = ctx(records, fields, { readOnly: true });
    assert.strictEqual(clearRange(locked, all), null, 'sheet readOnly: clear');
    assert.strictEqual(
      pasteMatrix(locked, { row: 0, col: 0 }, [['x', 'y']]),
      null,
      'sheet readOnly: paste'
    );
    assert.strictEqual(
      commitText(locked, { row: 0, col: 0 }, 'x'),
      null,
      'sheet readOnly: edit'
    );
  });

  test('U12 pasteMatrix with createOnPaste', function (assert) {
    const records: Row[] = [
      { id: 'r0', status: 'open' },
      { id: 'r1', status: 'open' }
    ];
    const created = pasteMatrix(
      ctx(records, [{ ...STATUS, createOnPaste: true }]),
      { row: 0, col: 0 },
      [['Purple'], ['Purple']]
    );
    assert.deepEqual(created, {
      source: 'paste',
      patches: [
        { recordId: 'r0', fieldId: 'status', from: 'open', to: 'Purple' },
        { recordId: 'r1', fieldId: 'status', from: 'open', to: 'Purple' }
      ],
      inserts: [],
      rejected: [],
      newOptions: [
        { fieldId: 'status', option: { value: 'Purple', label: 'Purple' } }
      ]
    });
    const rejected = pasteMatrix(ctx(records, [STATUS]), { row: 0, col: 0 }, [
      ['Purple'],
      ['Purple']
    ]);
    assert.deepEqual(rejected?.patches, []);
    assert.deepEqual(rejected?.newOptions, []);
    assert.deepEqual(
      rejected?.rejected.map((r) => [r.recordId, r.text, r.message]),
      [
        ['r0', 'Purple', '"Purple" is not an option'],
        ['r1', 'Purple', '"Purple" is not an option']
      ]
    );
  });

  test('U13 pasteMatrix past the end with a rejected cell', function (assert) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'name' },
      { id: 'qty', type: 'number' }
    ];
    const records: Row[] = [{ id: 'r0', name: 'n0', qty: 0 }];
    const result = pasteMatrix(ctx(records, fields), { row: 0, col: 0 }, [
      ['a', '1'],
      ['b', 'x']
    ]);
    assert.deepEqual(result?.inserts, [
      {
        tempId: 'new-0',
        index: 1,
        values: { name: 'b' },
        anchor: { recordId: 'r0', position: 'after' }
      }
    ]);
    assert.deepEqual(result?.rejected, [
      {
        tempId: 'new-0',
        fieldId: 'qty',
        text: 'x',
        message: '"x" is not a number'
      }
    ]);
    const onlyRejected = pasteMatrix(ctx(records, fields), { row: 0, col: 1 }, [
      ['2'],
      ['zz']
    ]);
    assert.deepEqual(onlyRejected?.patches, [
      { recordId: 'r0', fieldId: 'qty', from: 0, to: 2 }
    ]);
    assert.deepEqual(
      onlyRejected?.inserts,
      [
        {
          tempId: 'new-0',
          index: 1,
          values: {},
          anchor: { recordId: 'r0', position: 'after' }
        }
      ],
      'a row with only rejected cells is still inserted'
    );
    assert.deepEqual(onlyRejected?.rejected, [
      {
        tempId: 'new-0',
        fieldId: 'qty',
        text: 'zz',
        message: '"zz" is not a number'
      }
    ]);
  });

  test('U14 applyNewOptions and localRecords({ fields })', function (assert) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'name' },
      STATUS,
      { id: 'dyn', type: 'singleSelect', options: () => [] }
    ];
    const none: ChangeSet = {
      source: 'paste',
      patches: [],
      inserts: [],
      ...empty
    };
    assert.strictEqual(applyNewOptions(fields, none), fields, 'same array');
    const set: ChangeSet = {
      ...none,
      newOptions: [
        { fieldId: 'status', option: { value: 'Purple', label: 'Purple' } },
        { fieldId: 'status', option: { value: 'open', label: 'Open again' } },
        { fieldId: 'dyn', option: { value: 'x', label: 'x' } }
      ]
    };
    const next = applyNewOptions(fields, set);
    assert.notStrictEqual(next, fields);
    assert.strictEqual(next[0], fields[0], 'untouched field kept');
    assert.notStrictEqual(next[1], fields[1], 'affected field replaced');
    assert.deepEqual(
      next[1]!['options'],
      [
        { value: 'open', label: 'Open' },
        { value: 'closed', label: 'Closed' },
        { value: 'Purple', label: 'Purple' }
      ],
      'appended; an existing value not duplicated'
    );
    assert.strictEqual(next[2], fields[2], 'function options untouched');

    const store = localRecords<Row>([{ id: 'r0', status: 'open' }], {
      getRecordId: (record) => record.id,
      fields
    });
    store.apply({
      ...set,
      patches: [
        { recordId: 'r0', fieldId: 'status', from: 'open', to: 'Purple' }
      ]
    });
    assert.deepEqual(
      (store.fields[1]!['options'] as { value: string }[]).map((o) => o.value),
      ['open', 'closed', 'Purple'],
      'store.fields updated by apply'
    );
    assert.strictEqual(store.records[0]!['status'], 'Purple');
  });

  test('S1 applyChangeSet inserts at an index, clamps, and keeps paste appends', function (assert) {
    const getRecordId = (record: Row) => record.id;
    const set = (inserts: ChangeSet['inserts']): ChangeSet => ({
      source: 'insert',
      patches: [],
      inserts,
      ...empty
    });
    assert.deepEqual(
      applyChangeSet(
        rows(),
        set([{ tempId: 't0', index: 1, values: { a: 'n' } }]),
        { getRecordId }
      ).map((record) => record.id),
      ['r0', 't0', 'r1'],
      'at index 1'
    );
    assert.deepEqual(
      applyChangeSet(
        rows(),
        set([
          { tempId: 't1', index: 2, values: {} },
          { tempId: 't0', index: 0, values: {} }
        ]),
        { getRecordId }
      ).map((record) => record.id),
      ['t0', 'r0', 't1', 'r1'],
      'ascending index: each index is a position in the result'
    );
    assert.deepEqual(
      applyChangeSet(rows(), set([{ tempId: 't0', index: 99, values: {} }]), {
        getRecordId
      }).map((record) => record.id),
      ['r0', 'r1', 't0'],
      'an index past the end appends'
    );
    const pasted = pasteMatrix(ctx(rows()), { row: 1, col: 0 }, [
      ['x'],
      ['p'],
      ['q']
    ])!;
    assert.deepEqual(
      applyChangeSet(rows(), pasted, { getRecordId }).map((record) => [
        record.id,
        record['a']
      ]),
      [
        ['r0', 'a0'],
        ['r1', 'x'],
        ['new-0', 'p'],
        ['new-1', 'q']
      ],
      'a paste past the end still appends in order'
    );
  });

  test('S2 the anchor wins over the index, on an array larger than the page', function (assert) {
    const getRecordId = (record: Row) => record.id;
    // the sheet saw a page of two records (r5, r6) of a larger array
    const all: Row[] = Array.from({ length: 10 }, (_, i) => ({ id: `r${i}` }));
    const set: ChangeSet = {
      source: 'insert',
      patches: [],
      inserts: [
        {
          tempId: 't0',
          index: 1,
          values: {},
          anchor: { recordId: 'r5', position: 'after' }
        },
        {
          tempId: 't1',
          index: 0,
          values: {},
          anchor: { recordId: 'r5', position: 'before' }
        }
      ],
      ...empty
    };
    assert.deepEqual(
      applyChangeSet(all, set, { getRecordId })
        .slice(3, 9)
        .map((record) => record.id),
      ['r3', 'r4', 't1', 'r5', 't0', 'r6'],
      'before and after the anchor, not at index 0 and 1'
    );
    const missing: ChangeSet = {
      ...set,
      inserts: [
        {
          tempId: 't0',
          index: 1,
          values: {},
          anchor: { recordId: 'gone', position: 'after' }
        }
      ]
    };
    assert.deepEqual(
      applyChangeSet(rows(), missing, { getRecordId }).map(
        (record) => record.id
      ),
      ['r0', 't0', 'r1'],
      'an anchor that is not in the array falls back to the index'
    );
  });

  test('S2b chained inserts with a createRecord that assigns new ids land in order after the anchor', function (assert) {
    let n = 100;
    const created = insertRecords(ctx(rows()), {
      at: 1,
      anchor: { recordId: 'r0', position: 'after' },
      values: [{ a: 'x' }, { a: 'y' }, { a: 'z' }]
    });
    const next = applyChangeSet(rows(), created, {
      getRecordId: (record) => record.id,
      createRecord: (values) => ({ id: `srv-${n++}`, ...values })
    });
    assert.deepEqual(
      next.map((record) => [record.id, record['a']]),
      [
        ['r0', 'a0'],
        ['srv-100', 'x'],
        ['srv-101', 'y'],
        ['srv-102', 'z'],
        ['r1', 'a1']
      ]
    );
  });

  test('S3 restore puts the object back; restoreRecord overrides', function (assert) {
    const getRecordId = (record: Row) => record.id;
    const original: Row = { id: 'r9', a: 'kept', extra: { deep: true } };
    const set: ChangeSet = {
      source: 'undo',
      patches: [],
      inserts: [
        {
          tempId: 'r9',
          index: 1,
          values: { a: 'kept' },
          anchor: { recordId: 'r0', position: 'after' },
          restore: { recordId: 'r9', record: original }
        }
      ],
      ...empty
    };
    const next = applyChangeSet(rows(), set, { getRecordId });
    assert.strictEqual(next[1], original, 'the same object');
    const custom = applyChangeSet(rows(), set, {
      getRecordId,
      restoreRecord: (insert) => ({ id: 'srv-1', ...insert.values })
    });
    assert.deepEqual(custom[1], { id: 'srv-1', a: 'kept' });
    const store = localRecords(rows(), {
      getRecordId,
      restoreRecord: (insert) => ({ id: 'local', ...insert.values })
    });
    store.apply(set);
    assert.strictEqual(store.records[1]!.id, 'local', 'localRecords passes it');
  });

  test('S4 insertRecords', function (assert) {
    assert.deepEqual(insertRecords(ctx(rows()), { at: 1 }), {
      source: 'insert',
      patches: [],
      inserts: [{ tempId: 'new-0', index: 1, values: {} }],
      ...empty
    });
    let n = 0;
    assert.deepEqual(
      insertRecords(ctx(rows()), {
        at: 2,
        anchor: { recordId: 'r1', position: 'after' },
        values: [{ a: 'x' }, { b: 'y' }],
        nextTempId: () => `t${n++}`
      }).inserts,
      [
        {
          tempId: 't0',
          index: 2,
          values: { a: 'x' },
          anchor: { recordId: 'r1', position: 'after' }
        },
        {
          tempId: 't1',
          index: 3,
          values: { b: 'y' },
          anchor: { recordId: 't0', position: 'after' }
        }
      ]
    );
  });

  test('S5 deleteRecords', function (assert) {
    const records: Row[] = [
      { id: 'r0' },
      { id: 'r1' },
      { id: 'r2' },
      { id: 'r3' }
    ];
    const getRecordId = (record: Row) => record.id;
    assert.deepEqual(
      deleteRecords(records, ['r2', 'nope', 'r0'], getRecordId),
      {
        source: 'delete',
        patches: [],
        inserts: [],
        deletes: ['r0', 'r2'],
        removed: [
          { recordId: 'r0', index: 0, record: records[0] },
          { recordId: 'r2', index: 2, after: 'r1', record: records[2] }
        ],
        ...empty
      }
    );
    assert.strictEqual(deleteRecords(records, ['nope'], getRecordId), null);
    assert.strictEqual(deleteRecords(records, [], getRecordId), null);
    assert.deepEqual(
      applyChangeSet(records, deleteRecords(records, ['r1'], getRecordId)!, {
        getRecordId
      }).map((record) => record.id),
      ['r0', 'r2', 'r3']
    );
  });

  test('S6 duplicateRecords copies the writable fields right after each record', function (assert) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'a' },
      { id: 'b', readOnly: true },
      { id: 'c', readOnly: (record) => record['c'] === 'locked' }
    ];
    const records: Row[] = [
      { id: 'r0', a: 'a0', b: 'b0', c: 'c0' },
      { id: 'r1', a: 'a1', b: 'b1', c: 'locked' },
      { id: 'r2', a: 'a2', b: 'b2', c: 'c2' }
    ];
    let n = 0;
    const set = duplicateRecords(ctx(records, fields), [2, 0, 7], {
      nextTempId: () => `t${n++}`
    })!;
    assert.strictEqual(set.source, 'insert');
    assert.deepEqual(set.inserts, [
      {
        tempId: 't0',
        index: 1,
        values: { a: 'a0', c: 'c0' },
        anchor: { recordId: 'r0', position: 'after' }
      },
      {
        tempId: 't1',
        index: 4,
        values: { a: 'a2', c: 'c2' },
        anchor: { recordId: 'r2', position: 'after' }
      }
    ]);
    assert.deepEqual(
      duplicateRecords(ctx(records, fields), [1])!.inserts[0]!.values,
      { a: 'a1' },
      'a field read-only for that record is skipped'
    );
    assert.deepEqual(
      applyChangeSet(records, set, { getRecordId: (record) => record.id }).map(
        (record) => record.id
      ),
      ['r0', 't0', 'r1', 'r2', 't1']
    );
    assert.strictEqual(duplicateRecords(ctx(records, fields), [9]), null);
  });

  test('S7 pasteMatrix anchors its inserts after the last record', function (assert) {
    const result = pasteMatrix(ctx([]), { row: 0, col: 0 }, [['x'], ['y']]);
    assert.deepEqual(
      result?.inserts.map((insert) => insert.anchor),
      [undefined, { recordId: 'new-0', position: 'after' }],
      'no records: the first has no anchor, the next follows it'
    );
    const one = pasteMatrix(ctx(rows()), { row: 2, col: 0 }, [['z']]);
    assert.deepEqual(one?.inserts[0]?.anchor, {
      recordId: 'r1',
      position: 'after'
    });
  });

  test('S8 mergeChangeSets', function (assert) {
    const first: ChangeSet = {
      source: 'paste',
      patches: [
        { recordId: 'r0', fieldId: 'a', from: 'a0', to: 'x' },
        { recordId: 'r1', fieldId: 'a', from: 'a1', to: 'y' }
      ],
      inserts: [{ tempId: 'new-0', index: 2, values: { a: 'p' } }],
      rejected: [{ recordId: 'r0', fieldId: 'b', text: 'q', message: 'm' }],
      newOptions: []
    };
    const second: ChangeSet = {
      source: 'resolve',
      patches: [
        { recordId: 'r0', fieldId: 'a', from: 'x', to: 'X' },
        { recordId: 'r0', fieldId: 'b', from: 'b0', to: 'B' },
        { recordId: 'new-0', fieldId: 'b', from: undefined, to: 'Q' }
      ],
      inserts: [],
      deletes: ['r9'],
      rejected: [],
      newOptions: [{ fieldId: 'a', option: { value: 'X', label: 'X' } }]
    };
    assert.deepEqual(mergeChangeSets(first, second), {
      source: 'paste',
      patches: [
        { recordId: 'r0', fieldId: 'a', from: 'a0', to: 'X' },
        { recordId: 'r1', fieldId: 'a', from: 'a1', to: 'y' },
        { recordId: 'r0', fieldId: 'b', from: 'b0', to: 'B' }
      ],
      inserts: [{ tempId: 'new-0', index: 2, values: { a: 'p', b: 'Q' } }],
      deletes: ['r9'],
      rejected: [{ recordId: 'r0', fieldId: 'b', text: 'q', message: 'm' }],
      newOptions: [{ fieldId: 'a', option: { value: 'X', label: 'X' } }]
    });
    assert.deepEqual(
      first.inserts[0]!.values,
      { a: 'p' },
      'the first change set is not changed'
    );
  });
});
