/**
 * `pasteMatrix` and `planPaste` with `insert` (V03-DESIGN.md 8.5, batch
 * 3b stage 3.2a): where the lines past the records go in a grouped sheet,
 * with the group's values and `groupKey`. Without the option, v0.2.
 */
import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  pasteMatrix,
  planPaste
} from '#src/core/index.ts';

import type { EuiSheetField, SheetContext } from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const FIELDS: EuiSheetField<Row>[] = [{ id: 'a' }, { id: 'group' }];

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
  { id: 'r0', a: 'a0', group: 'x' },
  { id: 'r1', a: 'a1', group: 'y' }
];

let ids = 0;
const nextTempId = () => `t${ids++}`;

module('Unit | core | paste with insert', function (hooks) {
  hooks.beforeEach(function () {
    ids = 0;
  });

  test('PI1 without insert: the v0.2 inserts, after the last record', function (assert) {
    const set = pasteMatrix(ctx(rows()), { row: 1, col: 0 }, [['A'], ['B']], {
      nextTempId
    });
    assert.deepEqual(set?.inserts, [
      {
        tempId: 't0',
        index: 2,
        values: { a: 'B' },
        anchor: { recordId: 'r1', position: 'after' }
      }
    ]);
  });

  test('PI2 insert at a group’s place: its index, its anchor, its values win, its groupKey; the next follow the previous', function (assert) {
    const set = pasteMatrix(
      ctx(rows()),
      { row: 2, col: 0 },
      [['A', 'z'], ['B']],
      {
        nextTempId,
        insert: {
          index: 1,
          anchor: { recordId: 'r0', position: 'after' },
          values: { group: 'x' },
          groupKey: 'group:x'
        }
      }
    );
    assert.deepEqual(set?.patches, [], 'no record written');
    assert.deepEqual(set?.inserts, [
      {
        tempId: 't0',
        index: 1,
        values: { a: 'A', group: 'x' },
        anchor: { recordId: 'r0', position: 'after' },
        groupKey: 'group:x'
      },
      {
        tempId: 't1',
        index: 2,
        values: { a: 'B', group: 'x' },
        anchor: { recordId: 't0', position: 'after' },
        groupKey: 'group:x'
      }
    ]);
  });

  test('PI3 insert with anchor null (an empty group): no anchor; without index: after the records', function (assert) {
    const set = pasteMatrix(ctx(rows()), { row: 2, col: 0 }, [['A']], {
      nextTempId,
      insert: { anchor: null, values: { group: 'w' }, groupKey: 'group:w' }
    });
    assert.deepEqual(set?.inserts, [
      {
        tempId: 't0',
        index: 2,
        values: { a: 'A', group: 'w' },
        groupKey: 'group:w'
      }
    ]);
    // anchor left out: after the last record, as v0.2
    const after = pasteMatrix(ctx(rows()), { row: 1, col: 0 }, [['A'], ['B']], {
      nextTempId,
      insert: { values: { group: 'y' }, groupKey: 'group:y' }
    });
    assert.deepEqual(
      after?.patches.map((p) => [p.recordId, p.to]),
      [['r1', 'A']]
    );
    assert.deepEqual(after?.inserts[0]?.anchor, {
      recordId: 'r1',
      position: 'after'
    });
    assert.deepEqual(after?.inserts[0]?.values, { a: 'B', group: 'y' });
  });

  test('PI5 a pasted text for a field of insert.values is not read: no rejection, the value wins, the line still inserts', function (assert) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'a' },
      { id: 'n', type: 'number' }
    ];
    const insert = { values: { n: 7 }, groupKey: 'n:7' };
    const set = pasteMatrix(
      { ...ctx(rows()), fields },
      { row: 2, col: 0 },
      [['A', 'not a number']],
      { nextTempId, insert }
    );
    assert.deepEqual(set?.rejected, [], 'no rejection');
    assert.deepEqual(
      set?.inserts[0]?.values,
      { a: 'A', n: 7 },
      'the value wins'
    );
    const only = pasteMatrix(
      { ...ctx(rows()), fields },
      { row: 2, col: 1 },
      [['nor this']],
      { nextTempId, insert }
    );
    assert.deepEqual(only?.rejected, []);
    assert.deepEqual(
      only?.inserts.map((one) => one.values),
      [{ n: 7 }],
      'a line of only that field still inserts'
    );
    // without insert, the same text is a rejection (v0.2)
    const plain = pasteMatrix(
      { ...ctx(rows()), fields },
      { row: 2, col: 1 },
      [['nor this']],
      { nextTempId }
    );
    assert.strictEqual(plain?.rejected.length, 1);
  });

  test('PI4 planPaste takes insert too', function (assert) {
    const plan = planPaste(ctx(rows()), { row: 2, col: 0 }, [['A']], {
      nextTempId,
      insert: {
        index: 1,
        anchor: null,
        values: { group: 'x' },
        groupKey: 'group:x'
      }
    });
    assert.deepEqual(plan.changeSet?.inserts, [
      {
        tempId: 't0',
        index: 1,
        values: { a: 'A', group: 'x' },
        groupKey: 'group:x'
      }
    ]);
  });
});
