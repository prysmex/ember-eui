import { module, test } from 'qunit';

import {
  applyChangeSet,
  applyNewOptions,
  builtInFieldTypes,
  clearRange,
  commitText,
  commitValue,
  defaultMessages,
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
          { tempId: 'new-0', index: 2, values: { b: 'p' } },
          { tempId: 'new-1', index: 3, values: { b: 'q', c: 'r' } }
        ],
        ...empty
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
      { tempId: 'new-0', index: 1, values: { name: 'b' } }
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
      [{ tempId: 'new-0', index: 1, values: {} }],
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
});
