import { module, test } from 'qunit';

import { buildRowModel } from '#src/core/index.ts';

import type { RowModel, SheetRow } from '#src/core/index.ts';

/** Every row of a model, short: `r0` a record, `a1` an add row, `g2` a header. */
function rows(model: RowModel): string[] {
  return Array.from({ length: model.length }, (_, g) => {
    const row = model.at(g) as SheetRow;
    if (row.kind === 'record') return `r${row.record}`;
    if (row.kind === 'add') return `a${row.group}`;
    return `g${row.group}`;
  });
}

const range = (top: number, bottom: number) => ({
  top,
  bottom,
  left: 0,
  right: 2
});

module('Unit | Sheet | row model', function () {
  test('RM1 identity: 5 records and the add row', function (assert) {
    const model = buildRowModel({ recordCount: 5, addRow: true });
    assert.strictEqual(model.length, 6);
    assert.deepEqual(model.at(5), { kind: 'add', group: -1 });
    assert.deepEqual(model.at(2), { kind: 'record', record: 2 });
    assert.strictEqual(model.at(6), undefined);
    assert.strictEqual(model.at(-1), undefined);
    assert.strictEqual(model.recordRowAt(5), -1);
    assert.strictEqual(model.recordRowAt(3), 3);
    assert.strictEqual(model.gridRowOf(4), 4);
    assert.strictEqual(model.gridRowOf(5), -1);
    assert.strictEqual(model.firstRecordRow, 0);
    assert.strictEqual(model.lastRecordRow, 4);
    assert.strictEqual(model.addRowOf(-1), 5);
    assert.strictEqual(model.addRowOf(0), -1);
    assert.strictEqual(model.groupAt(2), -1);
  });

  test('RM2 identity without an add row, and 0 records with one', function (assert) {
    const plain = buildRowModel({ recordCount: 3, addRow: false });
    assert.strictEqual(plain.length, 3);
    assert.strictEqual(plain.at(3), undefined);
    assert.strictEqual(plain.addRowOf(-1), -1);
    assert.strictEqual(plain.lastRecordRow, 2);

    const empty = buildRowModel({ recordCount: 0, addRow: true });
    assert.strictEqual(empty.length, 1);
    assert.deepEqual(empty.at(0), { kind: 'add', group: -1 });
    assert.strictEqual(empty.firstRecordRow, -1);
    assert.strictEqual(empty.lastRecordRow, -1);
    assert.strictEqual(empty.recordRowAt(0), -1);
    assert.strictEqual(empty.recordRange(range(0, 0)), null);
    assert.strictEqual(empty.nearestRecordRow(0, 1), -1);
    assert.strictEqual(empty.nearestRecordRow(0, -1), -1);
    assert.strictEqual(empty.addRowOf(-1), 0);
  });

  test('RM3 identity: a range on the add row', function (assert) {
    const model = buildRowModel({ recordCount: 5, addRow: true });
    assert.deepEqual(model.recordRange(range(3, 5)), range(3, 4), 'clamped');
    assert.strictEqual(model.recordRange(range(5, 5)), null, 'add row alone');
    assert.deepEqual(model.recordRange(range(1, 2)), range(1, 2));
    assert.strictEqual(model.nearestRecordRow(5, -1), 4);
    assert.strictEqual(model.nearestRecordRow(5, 1), -1);
    assert.strictEqual(model.nearestRecordRow(2, 1), 2);
  });

  test('RM4 one level, three groups', function (assert) {
    const model = buildRowModel({
      recordCount: 5,
      addRow: true,
      groups: [
        { depth: 0, loaded: 2 },
        { depth: 0, loaded: 0, collapsed: true },
        { depth: 0, loaded: 3 }
      ]
    });
    assert.deepEqual(rows(model), [
      'g0',
      'r0',
      'r1',
      'a0',
      'g1',
      'g2',
      'r2',
      'r3',
      'r4',
      'a2'
    ]);
    assert.strictEqual(model.firstRecordRow, 1);
    assert.strictEqual(model.lastRecordRow, 8);
    assert.strictEqual(model.gridRowOf(2), 6);
    assert.strictEqual(model.recordRowAt(7), 3);
    assert.strictEqual(model.recordRowAt(0), -1);
    assert.strictEqual(model.recordRowAt(3), -1);
    assert.strictEqual(model.addRowOf(0), 3);
    assert.strictEqual(model.addRowOf(1), -1, 'collapsed');
    assert.strictEqual(model.addRowOf(2), 9);
    assert.strictEqual(model.addRowOf(-1), -1, 'no add row at the end');
    assert.strictEqual(model.groupAt(2), 0);
    assert.strictEqual(model.groupAt(3), 0, 'the add row');
    assert.strictEqual(model.groupAt(4), 1, 'a header');
    assert.strictEqual(model.groupAt(8), 2);
  });

  test('RM5 recordRange across a header and an add row', function (assert) {
    const model = buildRowModel({
      recordCount: 5,
      addRow: true,
      groups: [
        { depth: 0, loaded: 2 },
        { depth: 0, loaded: 0, collapsed: true },
        { depth: 0, loaded: 3 }
      ]
    });
    // r1, a0, g1, g2, r2, r3
    assert.deepEqual(model.recordRange(range(2, 7)), range(1, 3));
    // a0, g1, g2: no record
    assert.strictEqual(model.recordRange(range(3, 5)), null);
    // the whole grid
    assert.deepEqual(model.recordRange(range(0, 9)), range(0, 4));
    // a header and the records after it
    assert.deepEqual(model.recordRange(range(5, 6)), range(2, 2));
  });

  test('RM6 nearestRecordRow from a header and from the last add row', function (assert) {
    const model = buildRowModel({
      recordCount: 5,
      addRow: true,
      groups: [
        { depth: 0, loaded: 2 },
        { depth: 0, loaded: 0, collapsed: true },
        { depth: 0, loaded: 3 }
      ]
    });
    assert.strictEqual(model.nearestRecordRow(0, 1), 1, 'first header, down');
    assert.strictEqual(model.nearestRecordRow(0, -1), -1, 'first header, up');
    assert.strictEqual(model.nearestRecordRow(4, 1), 6, 'collapsed, down');
    assert.strictEqual(model.nearestRecordRow(4, -1), 2, 'collapsed, up');
    assert.strictEqual(model.nearestRecordRow(9, 1), -1, 'last add row, down');
    assert.strictEqual(model.nearestRecordRow(9, -1), 8, 'last add row, up');
    assert.strictEqual(model.nearestRecordRow(7, 1), 7, 'a record');
    assert.strictEqual(model.nearestRecordRow(7, -1), 7, 'a record');
  });

  test('RM7 two levels: groupAt of a record is its child group', function (assert) {
    const model = buildRowModel({
      recordCount: 3,
      addRow: true,
      groups: [{ depth: 0 }, { depth: 1, loaded: 2 }, { depth: 1, loaded: 1 }]
    });
    assert.deepEqual(rows(model), [
      'g0',
      'g1',
      'r0',
      'r1',
      'a1',
      'g2',
      'r2',
      'a2'
    ]);
    assert.strictEqual(model.addRowOf(0), -1, 'a parent has no add row');
    assert.strictEqual(model.groupAt(0), 0);
    assert.strictEqual(model.groupAt(3), 1);
    assert.strictEqual(model.groupAt(6), 2);
    assert.strictEqual(model.groupAt(7), 2);
  });

  test('RM8 a collapsed group and an empty expanded group', function (assert) {
    const model = buildRowModel({
      recordCount: 1,
      addRow: true,
      groups: [
        { depth: 0, collapsed: true },
        { depth: 0, loaded: 0 },
        { depth: 0, loaded: 1 }
      ]
    });
    assert.deepEqual(rows(model), ['g0', 'g1', 'a1', 'g2', 'r0', 'a2']);
    assert.strictEqual(model.addRowOf(0), -1);
    assert.strictEqual(model.addRowOf(1), 2);
  });

  test('RM9 fewer loaded than records: the rest follow the last group', function (assert) {
    const model = buildRowModel({
      recordCount: 5,
      addRow: true,
      groups: [
        { depth: 0, loaded: 1 },
        { depth: 0, loaded: 2 }
      ]
    });
    assert.deepEqual(rows(model), [
      'g0',
      'r0',
      'a0',
      'g1',
      'r1',
      'r2',
      'r3',
      'r4',
      'a1'
    ]);
    assert.strictEqual(model.groupAt(7), 1);
    assert.strictEqual(model.lastRecordRow, 7);
  });

  test('RM10 more loaded than records: clamped', function (assert) {
    const model = buildRowModel({
      recordCount: 3,
      addRow: true,
      groups: [
        { depth: 0, loaded: 2 },
        { depth: 0, loaded: 4 },
        { depth: 0, loaded: 2 }
      ]
    });
    assert.deepEqual(rows(model), [
      'g0',
      'r0',
      'r1',
      'a0',
      'g1',
      'r2',
      'a1',
      'g2',
      'a2'
    ]);
    assert.strictEqual(model.gridRowOf(3), -1);
    assert.strictEqual(model.recordRowAt(model.length), -1);
  });

  test('RM11 addRow false: no add rows at all', function (assert) {
    const model = buildRowModel({
      recordCount: 3,
      addRow: false,
      groups: [
        { depth: 0, loaded: 1 },
        { depth: 0, loaded: 0 },
        { depth: 0, loaded: 2 }
      ]
    });
    assert.deepEqual(rows(model), ['g0', 'r0', 'g1', 'g2', 'r1', 'r2']);
    assert.strictEqual(model.addRowOf(0), -1);
    assert.strictEqual(model.addRowOf(1), -1);
    assert.strictEqual(model.addRowOf(-1), -1);
  });

  test('RM12 100,000 records, identity: no array', function (assert) {
    buildRowModel({ recordCount: 10, addRow: true }); // warm up
    const start = performance.now();
    const model = buildRowModel({ recordCount: 100_000, addRow: true });
    const ms = performance.now() - start;
    console.log(`RM12 buildRowModel(100,000): ${ms.toFixed(3)} ms`);
    assert.true(ms < 1, `${ms.toFixed(3)} ms`);
    const arrays = Object.values(model).filter(
      (value) => Array.isArray(value) || ArrayBuffer.isView(value)
    );
    assert.deepEqual(arrays, [], 'no array on the model');
    assert.strictEqual(model.length, 100_001);
    assert.strictEqual(model.recordRowAt(99_999), 99_999);
    assert.strictEqual(model.gridRowOf(99_999), 99_999);
  });
});
