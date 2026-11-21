import { module, test } from 'qunit';

import { undoChangeSet, withoutConflicts } from '#src/core/index.ts';
import { findRecords } from '#src/core/record-lookup.ts';

import type { ChangeSet } from '#src/core/index.ts';

interface Row {
  id: string | number;
  a?: unknown;
}

module(
  'Unit | Sheet | record lookup (readiness, performance at scale)',
  function () {
    test('LK1 findRecords: the named records and their rows, ids as strings', function (assert) {
      const records: Row[] = [{ id: 1 }, { id: 'b' }, { id: 3 }, { id: 'd' }];
      const found = findRecords(records, (r) => r.id, new Set(['3', 'b', 'x']));
      assert.deepEqual(
        [...found].map(([id, hit]) => [id, hit.row, hit.record]),
        [
          ['b', 1, records[1]],
          ['3', 2, records[2]]
        ]
      );
    });

    test('LK6 findRecords: an id is found as its String(), whatever the record gives (number, string, other)', function (assert) {
      const records = [
        { id: 1 },
        { id: '2' },
        { id: -0 },
        { id: 1e21 },
        { id: 7 },
        { id: '08' },
        { id: BigInt(9) },
        { id: NaN }
      ] as unknown as Row[];
      const ids = new Set(['1', '2', '0', '1e+21', '07', '08', '9', 'NaN']);
      const found = findRecords(records, (r) => r.id, ids);
      // the same as a map of every record by String(id)
      const all = new Map(records.map((r, i) => [String(r.id), i]));
      const expected = [...ids]
        .filter((id) => all.has(id))
        .map((id) => [id, all.get(id)]);
      assert.deepEqual(
        [...found].map(([id, hit]) => [id, hit.row]).sort(),
        expected.sort()
      );
      assert.false(found.has('07'), '7 is not "07"');
      assert.strictEqual(found.get('08')?.row, 5);
    });

    test('LK2 findRecords: of two records with one id the last is found, as a map of all records', function (assert) {
      const records: Row[] = [
        { id: 'a', a: 1 },
        { id: 'a', a: 2 }
      ];
      const all = new Map(records.map((r, i) => [String(r.id), i]));
      const found = findRecords(records, (r) => r.id, new Set(['a']));
      assert.strictEqual(found.get('a')?.row, all.get('a'));
      assert.strictEqual(found.get('a')?.record, records[1]);
    });

    test('LK3 findRecords: no ids, no pass over the records', function (assert) {
      let calls = 0;
      const found = findRecords(
        [{ id: 1 }, { id: 2 }],
        (r: Row) => {
          calls++;
          return r.id;
        },
        new Set()
      );
      assert.strictEqual(found.size, 0);
      assert.strictEqual(calls, 0);
    });

    test('LK4 withoutConflicts reads each record id once, with no inserts to place', function (assert) {
      const records: Row[] = Array.from({ length: 1000 }, (_, i) => ({
        id: i,
        a: `v${i}`
      }));
      let calls = 0;
      const getId = (r: Row) => {
        calls++;
        return r.id;
      };
      const set: ChangeSet = {
        source: 'paste',
        patches: [
          { recordId: 5, fieldId: 'a', from: 'v5', to: 'x' },
          { recordId: 7, fieldId: 'a', from: 'old', to: 'y' },
          { recordId: 5000, fieldId: 'a', from: 'v', to: 'z' }
        ],
        inserts: [],
        rejected: [],
        newOptions: []
      };
      const kept = withoutConflicts(set, records, getId)!;
      // record 7 no longer holds `from`, 5000 is not there
      assert.deepEqual(kept.patches, [set.patches[0]]);
      assert.strictEqual(calls, records.length);
    });

    test('LK5 undoChangeSet over many records: the same result as before, inserts placed among them', function (assert) {
      const records: Row[] = Array.from({ length: 50 }, (_, i) => ({
        id: `r${i}`,
        a: i
      }));
      // a delete of r10 and r11 (with its removal), undone: both come back at their places
      const set: ChangeSet = {
        source: 'delete',
        patches: [{ recordId: 'r3', fieldId: 'a', from: 3, to: 30 }],
        inserts: [],
        deletes: ['r10', 'r11'],
        removed: [
          {
            recordId: 'r10',
            index: 10,
            after: 'r9',
            record: { id: 'r10', a: 10 }
          },
          {
            recordId: 'r11',
            index: 11,
            after: 'r10',
            record: { id: 'r11', a: 11 }
          }
        ],
        rejected: [],
        newOptions: []
      };
      const after = records
        .filter((r) => r.id !== 'r10' && r.id !== 'r11')
        .map((r) => (r.id === 'r3' ? { ...r, a: 30 } : r));
      const undo = undoChangeSet(set, after, (r) => r.id)!;
      assert.deepEqual(undo.patches, [
        { recordId: 'r3', fieldId: 'a', from: 30, to: 3 }
      ]);
      assert.deepEqual(
        undo.inserts.map((insert) => [insert.restore?.recordId, insert.index]),
        [
          ['r10', 10],
          ['r11', 11]
        ]
      );
    });
  }
);
