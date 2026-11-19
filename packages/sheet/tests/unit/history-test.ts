import { module, test } from 'qunit';

import {
  applyChangeSet,
  invertChangeSet,
  redoChangeSet,
  undoChangeSet,
  withoutConflicts
} from '#src/core/index.ts';
import { localRecords } from '#src/local-records.ts';

import type { ChangeSet } from '#src/core/index.ts';

interface Row {
  id: string | number;
  [key: string]: unknown;
}

const getId = (record: Row) => record.id;

const PASTE: ChangeSet = {
  source: 'paste',
  patches: [
    { recordId: 'r0', fieldId: 'a', from: 'a0', to: 'x' },
    { recordId: 'r1', fieldId: 'b', from: 'b1', to: 'y' }
  ],
  inserts: [{ tempId: 'new-1', index: 2, values: { a: 'n', b: 'm' } }],
  rejected: [{ recordId: 'r0', fieldId: 'c', text: 'abc', message: 'bad' }],
  newOptions: [{ fieldId: 'a', option: { value: 'x', label: 'x' } }]
};

/** The records after PASTE was applied. */
const after = (): Row[] => [
  { id: 'r0', a: 'x', b: 'b0' },
  { id: 'r1', a: 'a1', b: 'y' },
  { id: 'new-1', a: 'n', b: 'm' }
];

module('Unit | Sheet | history', function () {
  test('H1 invertChangeSet swaps patches and turns inserts into deletions', function (assert) {
    assert.deepEqual(invertChangeSet(PASTE), {
      source: 'undo',
      patches: [
        { recordId: 'r0', fieldId: 'a', from: 'x', to: 'a0' },
        { recordId: 'r1', fieldId: 'b', from: 'y', to: 'b1' }
      ],
      inserts: [],
      deletes: ['new-1'],
      rejected: [],
      newOptions: []
    });
  });

  test('H2 undoChangeSet and redoChangeSet with no conflict', function (assert) {
    const undo = undoChangeSet(PASTE, after(), getId)!;
    assert.strictEqual(undo.source, 'undo');
    assert.deepEqual(undo.patches, invertChangeSet(PASTE).patches);
    assert.deepEqual(undo.deletes, ['new-1']);
    assert.deepEqual(undo.newOptions, [], 'new options are not removed');

    const undone = applyChangeSet(after(), undo, { getRecordId: getId });
    assert.deepEqual(undone, [
      { id: 'r0', a: 'a0', b: 'b0' },
      { id: 'r1', a: 'a1', b: 'b1' }
    ]);

    const redo = redoChangeSet(PASTE, undone, getId)!;
    assert.deepEqual(redo, {
      source: 'redo',
      patches: PASTE.patches,
      inserts: [{ tempId: 'new-1', index: 2, values: { a: 'n', b: 'm' } }],
      rejected: [],
      newOptions: []
    });
    assert.deepEqual(
      applyChangeSet(undone, redo, { getRecordId: getId }),
      after(),
      'the same records as after the paste'
    );
  });

  test('H3 a cell changed since is skipped; nothing left is null', function (assert) {
    const records = after();
    records[0] = { ...records[0]!, a: 'owner' };
    const undo = undoChangeSet(PASTE, records, getId)!;
    assert.deepEqual(
      undo.patches,
      [{ recordId: 'r1', fieldId: 'b', from: 'y', to: 'b1' }],
      "r0.a is the owner's now"
    );
    assert.deepEqual(undo.deletes, ['new-1']);

    // the inserted row changed since: it is not deleted
    records[2] = { ...records[2]!, b: 'owner' };
    assert.strictEqual(
      undoChangeSet(PASTE, records, getId)!.deletes,
      undefined,
      'no deletions'
    );

    // every cell changed and the row is gone
    const changed: Row[] = [
      { id: 'r0', a: 'p', b: 'b0' },
      { id: 'r1', a: 'a1', b: 'q' }
    ];
    assert.strictEqual(undoChangeSet(PASTE, changed, getId), null);
  });

  test('H4 withoutConflicts: missing records, existing tempIds, ids as strings', function (assert) {
    const set: ChangeSet = {
      source: 'redo',
      patches: [
        { recordId: 'gone', fieldId: 'a', from: undefined, to: 'x' },
        { recordId: 7, fieldId: 'a', from: 'a7', to: 'x' }
      ],
      inserts: [
        { tempId: 'new-1', index: 0, values: { a: 'n' } },
        { tempId: 'new-2', index: 1, values: { a: 'o' } }
      ],
      deletes: [7, 'nope'],
      rejected: [],
      newOptions: []
    };
    const records: Row[] = [
      { id: 7, a: 'a7' },
      { id: 'new-1', a: 'n' }
    ];
    const kept = withoutConflicts(set, records, getId)!;
    assert.deepEqual(
      kept.patches,
      [{ recordId: 7, fieldId: 'a', from: 'a7', to: 'x' }],
      'a patch on a missing record is dropped, even with from undefined'
    );
    assert.deepEqual(
      kept.inserts,
      [{ tempId: 'new-2', index: 2, values: { a: 'o' } }],
      'an existing tempId is not inserted again; index is at the end'
    );
    assert.deepEqual(kept.deletes, [7], 'an unknown id is skipped');
  });

  test('H5 applyChangeSet and localRecords apply deletes', function (assert) {
    const records: Row[] = [
      { id: 1, a: 'a' },
      { id: 'new-3', a: 'b' },
      { id: 'r2', a: 'c' }
    ];
    const set: ChangeSet = {
      source: 'undo',
      patches: [{ recordId: 'r2', fieldId: 'a', from: 'c', to: 'z' }],
      inserts: [],
      deletes: ['1', 'new-3', 'missing'],
      rejected: [],
      newOptions: []
    };
    assert.deepEqual(applyChangeSet(records, set, { getRecordId: getId }), [
      { id: 'r2', a: 'z' }
    ]);

    const store = localRecords<Row>(records, { getRecordId: getId });
    store.apply(set);
    assert.deepEqual(store.records, [{ id: 'r2', a: 'z' }]);
    store.apply({ ...set, deletes: undefined, patches: [] });
    assert.deepEqual(
      store.records,
      [{ id: 'r2', a: 'z' }],
      'a change set without deletes keeps every record'
    );
  });
});
