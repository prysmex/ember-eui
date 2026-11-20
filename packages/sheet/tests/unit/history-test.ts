import { module, test } from 'qunit';

import {
  applyChangeSet,
  deleteRecords,
  invertChangeSet,
  redoChangeSet,
  undoChangeSet,
  withoutConflicts,
  withoutField
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
      [{ tempId: 'new-2', index: 1, values: { a: 'o' } }],
      'an existing tempId is not inserted again; without an anchor the index is kept, clamped to the end (v0.2, C3)'
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

  test('H6 the inverse of a delete gives positioned restores', function (assert) {
    const records: Row[] = [
      { id: 'r0', a: 'a0' },
      { id: 'r1', a: 'a1', b: 'b1' },
      { id: 'r2', a: 'a2' },
      { id: 'r3', a: 'a3' }
    ];
    const deleted = deleteRecords(records, ['r2', 'r1'], getId)!;
    assert.deepEqual(invertChangeSet(deleted, ['a', 'b']), {
      source: 'undo',
      patches: [],
      inserts: [
        {
          tempId: 'r1',
          index: 1,
          values: { a: 'a1', b: 'b1' },
          anchor: { recordId: 'r0', position: 'after' },
          restore: { recordId: 'r1', record: records[1] }
        },
        {
          tempId: 'r2',
          index: 2,
          values: { a: 'a2' },
          anchor: { recordId: 'r1', position: 'after' },
          restore: { recordId: 'r2', record: records[2] }
        }
      ],
      deletes: [],
      rejected: [],
      newOptions: []
    });
    const first = deleteRecords(records, ['r0'], getId)!;
    const [restore] = invertChangeSet(first).inserts;
    assert.strictEqual(
      restore!.anchor,
      undefined,
      'the first record has no neighbour'
    );
    assert.deepEqual(restore!.values, {}, 'no field ids: no values');
  });

  test('H7 undo then redo of a delete round-trips through applyChangeSet', function (assert) {
    const records: Row[] = [
      { id: 'r0', a: 'a0' },
      { id: 'r1', a: 'a1' },
      { id: 'r2', a: 'a2' },
      { id: 'r3', a: 'a3' }
    ];
    const deleted = deleteRecords(records, ['r1', 'r3'], getId)!;
    const after = applyChangeSet(records, deleted, { getRecordId: getId });
    assert.deepEqual(
      after.map((record) => record.id),
      ['r0', 'r2']
    );
    const undo = undoChangeSet(deleted, after, getId, { fieldIds: ['a'] })!;
    assert.strictEqual(undo.source, 'undo');
    const undone = applyChangeSet(after, undo, { getRecordId: getId });
    assert.deepEqual(undone, records, 'the same records, in the same places');
    assert.strictEqual(undone[1], records[1], 'the same objects');

    const redo = redoChangeSet(deleted, undone, getId)!;
    assert.strictEqual(redo.source, 'redo');
    assert.deepEqual(redo.deletes, ['r1', 'r3']);
    assert.deepEqual(redo.removed, deleted.removed, 'the entry’s own removed');
    assert.deepEqual(
      applyChangeSet(undone, redo, { getRecordId: getId }),
      after
    );
    assert.strictEqual(
      undoChangeSet(deleted, undone, getId),
      null,
      'nothing to restore while the records exist'
    );
  });

  test('H8 a re-insert follows its anchor when the anchor moved', function (assert) {
    const records: Row[] = [{ id: 'r0' }, { id: 'r1' }, { id: 'r2' }];
    const deleted = deleteRecords(records, ['r2'], getId)!;
    // the owner re-sorted: r1 (r2's old neighbour) is first now
    const moved: Row[] = [{ id: 'r1' }, { id: 'r0' }];
    const undo = undoChangeSet(deleted, moved, getId)!;
    assert.strictEqual(undo.inserts[0]!.index, 1, 'right after r1, not at 2');
    assert.deepEqual(
      applyChangeSet(moved, undo, { getRecordId: getId }).map(
        (record) => record.id
      ),
      ['r1', 'r2', 'r0']
    );
    // anchor gone: the old index, clamped
    const gone = undoChangeSet(deleted, [{ id: 'x' }], getId)!;
    assert.strictEqual(gone.inserts[0]!.index, 1);
    // a redone paste: chained inserts get consecutive indexes after the anchor
    const paste: ChangeSet = {
      source: 'paste',
      patches: [],
      inserts: [
        {
          tempId: 'n0',
          index: 3,
          values: {},
          anchor: { recordId: 'r2', position: 'after' }
        },
        {
          tempId: 'n1',
          index: 4,
          values: {},
          anchor: { recordId: 'n0', position: 'after' }
        }
      ],
      rejected: [],
      newOptions: []
    };
    const grown: Row[] = [
      { id: 'r0' },
      { id: 'r1' },
      { id: 'r2' },
      { id: 'owner' }
    ];
    assert.deepEqual(
      redoChangeSet(paste, grown, getId)!.inserts.map((insert) => [
        insert.tempId,
        insert.index
      ]),
      [
        ['n0', 3],
        ['n1', 4]
      ],
      'after the anchor, before the row the owner added at the end'
    );
  });

  test('H9 the equals option compares cells', function (assert) {
    const entry: ChangeSet = {
      source: 'edit',
      patches: [
        { recordId: 'r0', fieldId: 'tags', from: ['a'], to: ['a', 'b'] }
      ],
      inserts: [],
      rejected: [],
      newOptions: []
    };
    // the owner stored a copy of the array
    const records: Row[] = [{ id: 'r0', tags: ['a', 'b'] }];
    assert.strictEqual(
      undoChangeSet(entry, records, getId),
      null,
      'Object.is: another array is a change made since'
    );
    const equals = (_fieldId: string, a: unknown, b: unknown) =>
      JSON.stringify(a) === JSON.stringify(b);
    assert.deepEqual(
      undoChangeSet(entry, records, getId, { equals })!.patches,
      [{ recordId: 'r0', fieldId: 'tags', from: ['a', 'b'], to: ['a'] }]
    );
    assert.deepEqual(
      redoChangeSet(entry, [{ id: 'r0', tags: ['a'] }], getId, { equals })!
        .patches,
      entry.patches,
      'redo too'
    );
  });

  test('H10 an entry whose records are not in the records is skipped', function (assert) {
    // the owner moved to another page: none of the entry's records are shown
    const otherPage: Row[] = [{ id: 'p9', a: 'z' }];
    assert.strictEqual(undoChangeSet(PASTE, otherPage, getId), null);
    const edit: ChangeSet = { ...PASTE, source: 'edit', inserts: [] };
    assert.strictEqual(redoChangeSet(edit, otherPage, getId), null);
    const deleted = deleteRecords([{ id: 'p1' }], ['p1'], getId)!;
    assert.strictEqual(
      redoChangeSet(deleted, otherPage, getId),
      null,
      'a delete of a record that is not shown'
    );
  });
  test('H13 keepUnseen: patches of records not in the records are kept, unchecked (V03 8.5, GR16)', function (assert) {
    // grouped: r1 is in a collapsed group, so it is not among the records
    const shown: Row[] = [{ id: 'r0', a: 'x', b: 'b0' }];
    const edit: ChangeSet = { ...PASTE, source: 'edit', inserts: [] };
    const undo = undoChangeSet(edit, shown, getId, { keepUnseen: true })!;
    assert.deepEqual(
      undo.patches.map((patch) => [patch.recordId, patch.to]),
      [
        ['r0', 'a0'],
        ['r1', 'b1']
      ],
      'r1 is kept without its check'
    );
    const changed: Row[] = [{ id: 'r0', a: 'other', b: 'b0' }];
    assert.deepEqual(
      undoChangeSet(edit, changed, getId, { keepUnseen: true })!.patches.map(
        (patch) => patch.recordId
      ),
      ['r1'],
      'a shown record changed since is still dropped'
    );
    const redo = redoChangeSet(edit, [], getId, { keepUnseen: true })!;
    assert.deepEqual(
      redo.patches.map((patch) => [patch.recordId, patch.to]),
      [
        ['r0', 'x'],
        ['r1', 'y']
      ],
      'redo too'
    );
    assert.deepEqual(
      undoChangeSet(edit, shown, getId)!.patches.map((patch) => patch.recordId),
      ['r0'],
      'without it: dropped, as before'
    );
  });

  test('H11 withoutField drops the field from patches, inserts, rejections and new options (V03 6.6)', function (assert) {
    assert.strictEqual(
      withoutField(PASTE, 'z'),
      PASTE,
      'untouched: the same entry'
    );
    const result = withoutField(PASTE, 'a')!;
    assert.deepEqual(result.patches, [PASTE.patches[1]]);
    assert.deepEqual(result.inserts, [
      { tempId: 'new-1', index: 2, values: { b: 'm' } }
    ]);
    assert.deepEqual(result.newOptions, []);
    assert.deepEqual(result.rejected, PASTE.rejected);
    assert.deepEqual(
      withoutField(PASTE, 'c')!.rejected,
      [],
      'a rejection of the field'
    );
    assert.deepEqual(
      undoChangeSet(result, after(), getId)!.deletes,
      ['new-1'],
      'the insert is still undone (its other values match)'
    );
  });

  test('H12 withoutField: an entry left empty is null; deletes keep it', function (assert) {
    const edit: ChangeSet = {
      source: 'edit',
      patches: [{ recordId: 'r0', fieldId: 'a', from: 'a0', to: 'x' }],
      inserts: [],
      rejected: [],
      newOptions: []
    };
    assert.strictEqual(withoutField(edit, 'a'), null);
    const removal = deleteRecords([{ id: 'r0', a: 'a0' }], ['r0'], getId);
    if (!removal) throw new Error('no delete');
    const withPatch = { ...removal, patches: edit.patches };
    assert.deepEqual(withoutField(withPatch, 'a')!.deletes, ['r0']);
  });
});
