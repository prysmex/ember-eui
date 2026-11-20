/**
 * Row order (V03-DESIGN.md 4.3, 10.1, RD11): `moveRecords`, the moves of
 * `applyChangeSet`, and their undo and redo.
 */
import { module, test } from 'qunit';

import {
  applyChangeSet,
  invertChangeSet,
  mergeChangeSets,
  moveRecords,
  redoChangeSet,
  undoChangeSet,
  withoutField
} from '#src/core/index.ts';

import type { ChangeSet, RecordId, RecordMove } from '#src/core/index.ts';

interface Row {
  id: string;
  g?: string;
}

const getRecordId = (record: Row) => record.id;

function rows(ids: string): Row[] {
  return ids.split('').map((id) => ({ id }));
}

function order(records: readonly Row[]): string {
  return records.map((record) => record.id).join('');
}

function moveSet(moves: RecordMove[]): ChangeSet {
  return {
    source: 'move',
    patches: [],
    inserts: [],
    rejected: [],
    newOptions: [],
    moves
  };
}

const ctx = (records: Row[]) => ({ records, getRecordId });

/** Moves `ids` next to the target, applies the set, then undoes and redoes it. */
function roundTrip(
  start: string,
  ids: RecordId[],
  target: { recordId: RecordId; position: 'before' | 'after' } | undefined
): { moved: string; undone: string; redone: string; set: ChangeSet } {
  const records = rows(start);
  const set = moveRecords(ctx(records), ids, target)!;
  const moved = applyChangeSet(records, set, { getRecordId });
  const undo = undoChangeSet(set, moved, getRecordId)!;
  const undone = applyChangeSet(moved, undo, { getRecordId });
  const redo = redoChangeSet(set, undone, getRecordId)!;
  const redone = applyChangeSet(undone, redo, { getRecordId });
  return {
    moved: order(moved),
    undone: order(undone),
    redone: order(redone),
    set
  };
}

module('Unit | Sheet | moves (V03 10.1)', function () {
  test('RD11a applyChangeSet: before, after, a missing anchor, no anchor, chained', function (assert) {
    const apply = (start: string, moves: RecordMove[]) =>
      order(applyChangeSet(rows(start), moveSet(moves), { getRecordId }));
    assert.strictEqual(
      apply('ABCDE', [
        {
          recordId: 'B',
          anchor: { recordId: 'E', position: 'after' },
          from: { after: 'A' }
        }
      ]),
      'ACDEB',
      'after'
    );
    assert.strictEqual(
      apply('ABCDE', [
        {
          recordId: 'E',
          anchor: { recordId: 'A', position: 'before' },
          from: { after: 'D' }
        }
      ]),
      'EABCD',
      'before'
    );
    assert.strictEqual(
      apply('ABC', [
        {
          recordId: 'A',
          anchor: { recordId: 'Z', position: 'after' },
          from: {}
        }
      ]),
      'ABC',
      'a missing anchor: skipped'
    );
    assert.strictEqual(
      apply('ABC', [{ recordId: 'A', groupKey: 'g', from: {} }]),
      'ABC',
      'no anchor (groupKey only): skipped'
    );
    assert.strictEqual(
      apply('ABCDE', [
        {
          recordId: 'B',
          anchor: { recordId: 'E', position: 'after' },
          from: { after: 'A' }
        },
        {
          recordId: 'C',
          anchor: { recordId: 'B', position: 'after' },
          from: { after: 'B' }
        }
      ]),
      'ADEBC',
      'chained: each next one after the previous'
    );
    // patches, then the moves
    const patched = applyChangeSet(
      rows('AB'),
      {
        ...moveSet([
          {
            recordId: 'A',
            anchor: { recordId: 'B', position: 'after' },
            from: {}
          }
        ]),
        patches: [{ recordId: 'A', fieldId: 'g', from: undefined, to: 'x' }]
      },
      { getRecordId }
    );
    assert.deepEqual(patched, [{ id: 'B' }, { id: 'A', g: 'x' }]);
  });

  test('RD11b moveRecords: anchors, from, no-ops, a target among the moved', function (assert) {
    const set = moveRecords(ctx(rows('ABCDE')), ['B'], {
      recordId: 'E',
      position: 'after'
    })!;
    assert.strictEqual(set.source, 'move');
    assert.deepEqual(set.patches, []);
    assert.deepEqual(set.moves, [
      {
        recordId: 'B',
        anchor: { recordId: 'E', position: 'after' },
        from: { after: 'A' }
      }
    ]);
    // three, not adjacent, keep their order; the first one was first
    const three = moveRecords(ctx(rows('ABCDE')), ['D', 'A', 'B'], {
      recordId: 'E',
      position: 'after'
    })!;
    assert.deepEqual(three.moves, [
      {
        recordId: 'A',
        anchor: { recordId: 'E', position: 'after' },
        from: {}
      },
      {
        recordId: 'B',
        anchor: { recordId: 'A', position: 'after' },
        from: { after: 'A' }
      },
      {
        recordId: 'D',
        anchor: { recordId: 'B', position: 'after' },
        from: { after: 'C' }
      }
    ]);
    assert.strictEqual(
      moveRecords(ctx(rows('ABC')), ['B'], {
        recordId: 'A',
        position: 'after'
      }),
      null,
      'a drop on its own place'
    );
    assert.strictEqual(
      moveRecords(ctx(rows('ABC')), ['B'], {
        recordId: 'B',
        position: 'before'
      }),
      null,
      'a target that is the moved record'
    );
    // a target among the moved: the nearest record that stays
    const among = moveRecords(ctx(rows('ABCD')), ['B', 'C'], {
      recordId: 'C',
      position: 'after'
    });
    assert.strictEqual(among, null, 'B and C after C: where they are');
    const down = moveRecords(ctx(rows('ABCD')), ['A', 'B'], {
      recordId: 'C',
      position: 'after'
    })!;
    assert.strictEqual(
      order(applyChangeSet(rows('ABCD'), down, { getRecordId })),
      'CABD'
    );
    assert.strictEqual(
      moveRecords(ctx(rows('AB')), ['Z'], undefined),
      null,
      'unknown ids'
    );
    assert.strictEqual(
      moveRecords(ctx(rows('AB')), ['A', 'B'], undefined),
      null,
      'every record moves, no group: nothing to place them by'
    );
  });

  test('RD11c invertChangeSet round-trips: adjacent, not adjacent, the first record, upwards', function (assert) {
    const adjacent = roundTrip('ABCDE', ['B', 'C', 'D'], {
      recordId: 'E',
      position: 'after'
    });
    assert.deepEqual(
      [adjacent.moved, adjacent.undone, adjacent.redone],
      ['AEBCD', 'ABCDE', 'AEBCD']
    );
    const apart = roundTrip('ABCDE', ['B', 'D'], {
      recordId: 'E',
      position: 'after'
    });
    assert.deepEqual(
      [apart.moved, apart.undone, apart.redone],
      ['ACEBD', 'ABCDE', 'ACEBD']
    );
    const first = roundTrip('ABCDE', ['A', 'C', 'D'], {
      recordId: 'E',
      position: 'after'
    });
    assert.deepEqual(
      [first.moved, first.undone, first.redone],
      ['BEACD', 'ABCDE', 'BEACD'],
      'one of them was the first record'
    );
    const up = roundTrip('ABCDE', ['D', 'E'], {
      recordId: 'A',
      position: 'before'
    });
    assert.deepEqual(
      [up.moved, up.undone, up.redone],
      ['DEABC', 'ABCDE', 'DEABC']
    );

    // the inverse's own `from` is where each record is now
    const records = rows('ABCDE');
    const set = moveRecords(ctx(records), ['B'], {
      recordId: 'E',
      position: 'after'
    })!;
    const moved = applyChangeSet(records, set, { getRecordId });
    const inverse = invertChangeSet(set, [], moved.map(getRecordId));
    assert.deepEqual(inverse.moves, [
      {
        recordId: 'B',
        anchor: { recordId: 'A', position: 'after' },
        from: { after: 'E' }
      }
    ]);
    assert.strictEqual(inverse.source, 'undo');
    // without the order, a record that was first has no anchor back
    const head = moveRecords(ctx(rows('AB')), ['A'], {
      recordId: 'B',
      position: 'after'
    })!;
    assert.strictEqual(invertChangeSet(head).moves![0]!.anchor, undefined);
  });

  test('RD11d groups: the group patches and keys, a collapsed group, undo restores both', function (assert) {
    const records: Row[] = [
      { id: 'A', g: 'x' },
      { id: 'B', g: 'x' },
      { id: 'C', g: 'y' },
      { id: 'D', g: 'y' }
    ];
    const keyOf = (index: number) => `g:${records[index]!.g}`;
    const set = moveRecords(
      ctx(records),
      ['A'],
      { recordId: 'C', position: 'after' },
      {
        group: { key: 'g:y', start: 2, end: 4, values: { g: 'y' } },
        groupKeyOf: keyOf
      }
    )!;
    assert.deepEqual(set.patches, [
      { recordId: 'A', fieldId: 'g', from: 'x', to: 'y' }
    ]);
    assert.deepEqual(set.moves, [
      {
        recordId: 'A',
        anchor: { recordId: 'C', position: 'after' },
        groupKey: 'g:y',
        from: { groupKey: 'g:x' }
      }
    ]);
    const moved = applyChangeSet(records, set, { getRecordId });
    assert.deepEqual(moved, [
      { id: 'B', g: 'x' },
      { id: 'C', g: 'y' },
      { id: 'A', g: 'y' },
      { id: 'D', g: 'y' }
    ]);
    const undo = undoChangeSet(set, moved, getRecordId)!;
    assert.deepEqual(undo.moves![0]!.groupKey, 'g:x');
    assert.deepEqual(applyChangeSet(moved, undo, { getRecordId }), records);

    // a collapsed (or empty) group: no anchor, only the key
    const collapsed = moveRecords(ctx(records), ['A', 'B'], undefined, {
      group: { key: 'g:z', start: 4, end: 4, values: { g: 'z' } },
      groupKeyOf: keyOf
    })!;
    assert.deepEqual(
      collapsed.moves!.map((move) => [
        move.recordId,
        move.anchor,
        move.groupKey
      ]),
      [
        ['A', undefined, 'g:z'],
        ['B', { recordId: 'A', position: 'after' }, 'g:z']
      ]
    );
    assert.strictEqual(collapsed.patches.length, 2);
    // the same group and place: nothing
    assert.strictEqual(
      moveRecords(
        ctx(records),
        ['B'],
        { recordId: 'A', position: 'after' },
        {
          group: { key: 'g:x', start: 0, end: 2, values: { g: 'x' } },
          groupKeyOf: keyOf
        }
      ),
      null
    );
    // the end of the previous group is not the start of the next one
    const across = moveRecords(
      ctx(records),
      ['B'],
      { recordId: 'C', position: 'before' },
      {
        group: { key: 'g:y', start: 2, end: 4, values: { g: 'y' } },
        groupKeyOf: keyOf
      }
    )!;
    assert.deepEqual(across.moves![0]!.anchor, {
      recordId: 'C',
      position: 'before'
    });
    assert.strictEqual(across.patches.length, 1, 'same order, another group');
  });

  test('RD11e mergeChangeSets and withoutField keep the moves', function (assert) {
    const set = moveRecords(ctx(rows('ABC')), ['A'], {
      recordId: 'C',
      position: 'after'
    })!;
    const resolve: ChangeSet = {
      source: 'resolve',
      patches: [],
      inserts: [],
      rejected: [],
      newOptions: []
    };
    const merged = mergeChangeSets(set, resolve);
    assert.deepEqual(merged.moves, set.moves);
    assert.strictEqual(withoutField(set, 'g'), set, 'no field touched');
    const withPatch: ChangeSet = {
      ...set,
      patches: [{ recordId: 'A', fieldId: 'g', from: 1, to: 2 }]
    };
    assert.deepEqual(withoutField(withPatch, 'g')?.moves, set.moves);
  });
});
