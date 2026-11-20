/**
 * Group by outside the component (V03-DESIGN.md 8.7, 8.10, GP1–GP9):
 * `groupRecords`, `applyChangeSetToGroups` and `pageGroups`.
 */
import { module, test } from 'qunit';

import {
  applyChangeSetToGroups,
  builtInFieldTypes,
  defaultMessages,
  groupRecords,
  pageGroups,
  summarize
} from '#src/core/index.ts';

import { localRecords } from '#src/local-records.ts';

import { changeSet } from '../helpers/sheet.ts';

import type { EuiSheetField, SheetGroup } from '#src/core/index.ts';

interface Row {
  id: string;
  status?: string | null;
  owner?: string;
  qty?: number;
  tags?: string[];
}

const ctx = { types: builtInFieldTypes, messages: defaultMessages };

const STATUS: EuiSheetField<Row> = {
  id: 'status',
  type: 'singleSelect',
  // `compare` follows the options as given
  options: [
    { value: 'open', label: 'Open' },
    { value: 'doing', label: 'Doing' },
    { value: 'done', label: 'Done' }
  ]
} as EuiSheetField<Row>;
const OWNER: EuiSheetField<Row> = { id: 'owner' };
const QTY: EuiSheetField<Row> = { id: 'qty', type: 'number' };
const TAGS: EuiSheetField<Row> = {
  id: 'tags',
  type: 'multiSelect',
  options: [
    { value: 'a', label: 'A' },
    { value: 'b', label: 'B' },
    { value: 'c', label: 'C' }
  ]
} as EuiSheetField<Row>;
const FIELDS = [STATUS, OWNER, QTY, TAGS];

const ROWS: Row[] = [
  { id: 'r1', status: 'done', owner: 'Ana', qty: 1 },
  { id: 'r2', status: 'open', owner: 'Beto', qty: 2 },
  { id: 'r3', status: 'doing', owner: 'Ana', qty: 3 },
  { id: 'r4', status: 'open', owner: 'Ana', qty: 4 },
  { id: 'r5', status: 'done', owner: 'Beto', qty: 5 },
  { id: 'r6', status: 'open', owner: 'Ana', qty: 6 }
];

const ids = (rows: readonly Row[]) => rows.map((row) => row.id);
const keys = (groups: readonly SheetGroup[]) => groups.map((g) => g.key);
const getId = (row: { id: string }) => row.id;

module('Unit | Sheet | groups', function () {
  test('GP1 one level: order by compare, desc reversed, input order kept inside a group', function (assert) {
    const asc = groupRecords(ctx, ROWS, {
      groupBy: [{ field: 'status', direction: 'asc' }],
      fields: FIELDS
    });
    assert.deepEqual(keys(asc.groups), [
      'status:Open',
      'status:Doing',
      'status:Done'
    ]);
    assert.deepEqual(
      asc.groups.map((g) => [g.depth, g.value, g.count, g.loaded]),
      [
        [0, 'open', 3, 3],
        [0, 'doing', 1, 1],
        [0, 'done', 2, 2]
      ]
    );
    assert.deepEqual(ids(asc.records), ['r2', 'r4', 'r6', 'r3', 'r1', 'r5']);

    const desc = groupRecords(ctx, ROWS, {
      groupBy: [{ field: 'status', direction: 'desc' }],
      fields: FIELDS
    });
    assert.deepEqual(keys(desc.groups), [
      'status:Done',
      'status:Doing',
      'status:Open'
    ]);
    assert.deepEqual(ids(desc.records), ['r1', 'r5', 'r3', 'r2', 'r4', 'r6']);

    // a type without `compare`: by text
    const byOwner = groupRecords(ctx, ROWS, {
      groupBy: [{ field: 'owner', direction: 'asc' }],
      fields: FIELDS
    });
    assert.deepEqual(keys(byOwner.groups), ['owner:Ana', 'owner:Beto']);
    assert.notStrictEqual(byOwner.records, ROWS, 'a new array');
  });

  test('GP2 empty values form one group with value null', function (assert) {
    const rows: Row[] = [
      { id: 'a', owner: 'Ana' },
      { id: 'b', owner: '' },
      { id: 'c' },
      { id: 'd', owner: 'Ana' }
    ];
    const { groups, records } = groupRecords(ctx, rows, {
      groupBy: [{ field: 'owner', direction: 'asc' }],
      fields: FIELDS
    });
    assert.strictEqual(groups.length, 2);
    const empty = groups.find((group) => group.value === null)!;
    assert.strictEqual(empty.count, 2);
    assert.strictEqual(empty.key, 'owner:');
    assert.strictEqual(
      empty.label,
      undefined,
      "the label is the sheet's default"
    );
    assert.deepEqual(
      ids(records.slice(0, 2)),
      ['b', 'c'],
      'first in asc: its text is ""'
    );
  });

  test('GP3 collapsed keys: records left out, count kept, loaded 0', function (assert) {
    const { groups, records } = groupRecords(ctx, ROWS, {
      groupBy: [{ field: 'status', direction: 'asc' }],
      fields: FIELDS,
      collapsed: new Set(['status:Open'])
    });
    assert.deepEqual(ids(records), ['r3', 'r1', 'r5']);
    const open = groups[0]!;
    assert.deepEqual(
      [open.key, open.collapsed, open.count, open.loaded],
      ['status:Open', true, 3, 0]
    );
    assert.deepEqual(
      groups.slice(1).map((g) => [g.collapsed, g.loaded]),
      [
        [undefined, 1],
        [undefined, 2]
      ]
    );
  });

  test('GP4 two levels: depth-first, parents without loaded, a collapsed parent hides its children', function (assert) {
    const groupBy = [
      { field: 'status', direction: 'asc' as const },
      { field: 'owner', direction: 'desc' as const }
    ];
    const open = groupRecords(ctx, ROWS, { groupBy, fields: FIELDS });
    assert.deepEqual(keys(open.groups), [
      'status:Open',
      'status:Open/owner:Beto',
      'status:Open/owner:Ana',
      'status:Doing',
      'status:Doing/owner:Ana',
      'status:Done',
      'status:Done/owner:Beto',
      'status:Done/owner:Ana'
    ]);
    assert.deepEqual(
      open.groups.map((g) => [g.depth, g.count, g.loaded]),
      [
        [0, 3, undefined],
        [1, 1, 1],
        [1, 2, 2],
        [0, 1, undefined],
        [1, 1, 1],
        [0, 2, undefined],
        [1, 1, 1],
        [1, 1, 1]
      ]
    );
    assert.deepEqual(ids(open.records), ['r2', 'r4', 'r6', 'r3', 'r5', 'r1']);

    const closed = groupRecords(ctx, ROWS, {
      groupBy,
      fields: FIELDS,
      collapsed: new Set(['status:Open'])
    });
    assert.deepEqual(keys(closed.groups).slice(0, 2), [
      'status:Open',
      'status:Doing'
    ]);
    assert.strictEqual(
      closed.groups[0]!.loaded,
      undefined,
      'a collapsed parent has no loaded'
    );
    assert.strictEqual(closed.groups[0]!.count, 3);
    assert.deepEqual(ids(closed.records), ['r3', 'r5', 'r1']);

    const child = groupRecords(ctx, ROWS, {
      groupBy,
      fields: FIELDS,
      collapsed: new Set(['status:Open/owner:Ana'])
    });
    const ana = child.groups.find((g) => g.key === 'status:Open/owner:Ana')!;
    assert.deepEqual([ana.collapsed, ana.count, ana.loaded], [true, 2, 0]);
  });

  test('GP5 rowNumberStart counts the records of collapsed groups', function (assert) {
    const { groups } = groupRecords(ctx, ROWS, {
      groupBy: [{ field: 'status', direction: 'asc' }],
      fields: FIELDS,
      collapsed: new Set(['status:Open'])
    });
    // Open (3 records, hidden): 1–3; Doing starts at 4, Done at 5
    assert.deepEqual(
      groups.map((g) => g.rowNumberStart),
      [1, 4, 5]
    );
    const paged = groupRecords(ctx, ROWS, {
      groupBy: [{ field: 'status', direction: 'asc' }],
      fields: FIELDS,
      rowNumberOffset: 50
    });
    assert.deepEqual(
      paged.groups.map((g) => g.rowNumberStart),
      [51, 54, 55]
    );
  });

  test('GP6 summaries: each group text equals summarize over its records', function (assert) {
    const { groups, records } = groupRecords(ctx, ROWS, {
      groupBy: [
        { field: 'status', direction: 'asc' },
        { field: 'owner', direction: 'asc' }
      ],
      fields: FIELDS,
      collapsed: new Set(['status:Done']),
      summaries: { qty: 'sum', owner: 'unique', gone: 'count' }
    });
    assert.strictEqual(records.length, 4);
    const label: Record<string, string> = {
      open: 'Open',
      doing: 'Doing',
      done: 'Done'
    };
    const rowsOf = (key: string) => {
      const [level0, level1] = key.split('/');
      const status = level0!.slice('status:'.length);
      const owner = level1?.slice('owner:'.length);
      return ROWS.filter(
        (row) =>
          label[row.status!] === status &&
          (owner === undefined || row.owner === owner)
      );
    };
    for (const group of groups) {
      const mine = rowsOf(group.key);
      assert.strictEqual(mine.length, group.count, group.key);
      assert.deepEqual(
        group.summary,
        {
          qty: summarize(ctx, mine, QTY, 'sum'),
          owner: summarize(ctx, mine, OWNER, 'unique')
        },
        `${group.key} (collapsed groups too; unknown field ids ignored)`
      );
    }
    assert.strictEqual(
      groups[0]!.summary!['qty'],
      '12',
      'Open parent: 2 + 4 + 6'
    );
    assert.strictEqual(
      groupRecords(ctx, ROWS, {
        groupBy: [{ field: 'owner', direction: 'asc' }],
        fields: FIELDS
      }).groups[0]!.summary,
      undefined,
      'no summaries: no summary'
    );
  });

  test('GP7 a multi-select field groups by the whole set (copyText)', function (assert) {
    const rows: Row[] = [
      { id: 'a', tags: ['a', 'b'] },
      { id: 'b', tags: ['a'] },
      { id: 'c', tags: ['a', 'b'] },
      { id: 'd', tags: [] },
      { id: 'e', tags: ['c'] },
      { id: 'f' }
    ];
    const { groups } = groupRecords(ctx, rows, {
      groupBy: [{ field: 'tags', direction: 'asc' }],
      fields: FIELDS
    });
    const byKey = Object.fromEntries(groups.map((g) => [g.key, g]));
    assert.strictEqual(groups.length, 4, 'empty, A, A + B, C');
    assert.strictEqual(byKey['tags:A, B']?.count, 2);
    assert.deepEqual(byKey['tags:A, B']?.value, ['a', 'b']);
    assert.strictEqual(
      byKey['tags:']?.count,
      2,
      'the empty set and no value together'
    );
    assert.strictEqual(byKey['tags:']?.value, null);
    assert.deepEqual(
      keys(groups),
      ['tags:', 'tags:A', 'tags:A, B', 'tags:C'],
      'by compare: fewer first inside a common prefix'
    );
  });

  module('applyChangeSetToGroups', function () {
    const records = [{ id: 'a1' }, { id: 'a2' }, { id: 'b1' }, { id: 'c1' }];
    const GROUPS: SheetGroup[] = [
      { key: 'p', depth: 0, value: 'p', count: 5 },
      { key: 'p/A', depth: 1, value: 'A', count: 3, loaded: 2 },
      { key: 'p/B', depth: 1, value: 'B', count: 2, loaded: 1 },
      { key: 'q', depth: 0, value: 'q', count: 1, loaded: 1 }
    ];
    const brief = (groups: readonly SheetGroup[]) =>
      groups.map((g) => [g.key, g.count, g.loaded]);

    test('GP8 insert by groupKey, by anchor', function (assert) {
      const byKey = applyChangeSetToGroups(
        GROUPS,
        records,
        changeSet({
          source: 'insert',
          inserts: [{ tempId: 'n1', index: 0, values: {}, groupKey: 'p/B' }]
        }),
        getId
      );
      assert.deepEqual(brief(byKey), [
        ['p', 6, undefined],
        ['p/A', 3, 2],
        ['p/B', 3, 2],
        ['q', 1, 1]
      ]);
      assert.strictEqual(
        byKey[1],
        GROUPS[1],
        'untouched groups keep their identity'
      );
      assert.strictEqual(GROUPS[2]!.count, 2, 'the input is not changed');

      const byAnchor = applyChangeSetToGroups(
        GROUPS,
        records,
        changeSet({
          source: 'insert',
          inserts: [
            {
              tempId: 'n1',
              index: 2,
              values: {},
              anchor: { recordId: 'a2', position: 'after' }
            },
            {
              tempId: 'n2',
              index: 3,
              values: {},
              anchor: { recordId: 'n1', position: 'after' }
            }
          ]
        }),
        getId
      );
      assert.deepEqual(brief(byAnchor), [
        ['p', 7, undefined],
        ['p/A', 5, 4],
        ['p/B', 2, 1],
        ['q', 1, 1]
      ]);
    });

    test('GP8 delete, move across groups, collapsed target, no change', function (assert) {
      const del = applyChangeSetToGroups(
        GROUPS,
        records,
        changeSet({ source: 'delete', deletes: ['b1', 'c1', 'unknown'] }),
        getId
      );
      assert.deepEqual(brief(del), [
        ['p', 4, undefined],
        ['p/A', 3, 2],
        ['p/B', 1, 0],
        ['q', 0, 0]
      ]);

      const move = applyChangeSetToGroups(
        GROUPS,
        records,
        changeSet({
          source: 'move',
          moves: [
            {
              recordId: 'a1',
              anchor: { recordId: 'c1', position: 'after' },
              groupKey: 'q',
              from: { groupKey: 'p/A' }
            }
          ]
        }),
        getId
      );
      assert.deepEqual(brief(move), [
        ['p', 4, undefined],
        ['p/A', 2, 1],
        ['p/B', 2, 1],
        ['q', 2, 2]
      ]);
      const within = applyChangeSetToGroups(
        GROUPS,
        records,
        changeSet({
          source: 'move',
          moves: [
            {
              recordId: 'a1',
              anchor: { recordId: 'a2', position: 'after' },
              from: {}
            }
          ]
        }),
        getId
      );
      assert.strictEqual(
        within,
        GROUPS,
        'a move inside a group changes nothing'
      );

      const collapsed = applyChangeSetToGroups(
        [{ key: 'x', depth: 0, value: 'x', count: 4, collapsed: true }],
        [],
        changeSet({
          source: 'insert',
          inserts: [{ tempId: 'n', index: 0, values: {}, groupKey: 'x' }]
        }),
        getId
      );
      assert.deepEqual(
        collapsed.map((g) => [g.count, g.loaded]),
        [[5, undefined]],
        'a collapsed group: count only'
      );

      assert.strictEqual(
        applyChangeSetToGroups(
          GROUPS,
          records,
          changeSet({
            source: 'edit',
            patches: [{ recordId: 'a1', fieldId: 'f', from: 1, to: 2 }]
          }),
          getId
        ),
        GROUPS,
        'patches change nothing'
      );
    });
  });

  test('GP9 pageGroups: a page that starts inside a group marks it continued', function (assert) {
    // the backend's headers for the whole result: A 5, B 3 (collapsed C 4, hidden)
    const backend: SheetGroup[] = [
      { key: 'A', depth: 0, value: 'A', count: 5 },
      { key: 'B', depth: 0, value: 'B', count: 3 },
      { key: 'C', depth: 0, value: 'C', count: 4, collapsed: true }
    ];
    const recs = (...keysOf: string[]) =>
      keysOf.map((group, i) => ({ id: `${group}${i}`, group }));
    const of = (r: { group: string }) => r.group;
    const brief = (groups: readonly SheetGroup[]) =>
      groups.map((g) => [g.key, g.loaded, g.continued]);

    assert.deepEqual(
      brief(pageGroups(recs('A', 'A', 'A'), backend, of, { offset: 0 })),
      [['A', 3, undefined]],
      'page 1: A starts here and goes on; B and C are not on the page'
    );
    assert.deepEqual(
      brief(pageGroups(recs('A', 'A', 'B', 'B'), backend, of, { offset: 3 })),
      [
        ['A', 2, true],
        ['B', 2, undefined]
      ],
      'page 2 starts inside A'
    );
    assert.deepEqual(
      brief(pageGroups(recs('B'), backend, of, { offset: 7 })),
      [
        ['B', 1, true],
        ['C', undefined, undefined]
      ],
      'the last page keeps the collapsed group after it'
    );
    assert.strictEqual(
      pageGroups(recs('A'), backend, of, { offset: 0 })[0]!.count,
      5,
      "count is the backend's"
    );

    // two levels: a leaf's parent stays with it, the other parent is left out
    const nested: SheetGroup[] = [
      { key: 'P', depth: 0, value: 'P', count: 6 },
      { key: 'P/A', depth: 1, value: 'A', count: 4 },
      { key: 'P/B', depth: 1, value: 'B', count: 2 },
      { key: 'Q', depth: 0, value: 'Q', count: 2 },
      { key: 'Q/A', depth: 1, value: 'A', count: 2 }
    ];
    assert.deepEqual(
      brief(pageGroups(recs('P/B', 'P/B', 'Q/A'), nested, of, { offset: 4 })),
      [
        ['P', undefined, undefined],
        ['P/B', 2, undefined],
        ['Q', undefined, undefined],
        ['Q/A', 1, undefined]
      ]
    );
    assert.deepEqual(
      brief(pageGroups(recs('P/A', 'P/B', 'P/B'), nested, of, { offset: 3 })),
      [
        ['P', undefined, undefined],
        ['P/A', 1, true],
        ['P/B', 2, undefined]
      ],
      'Q is not on the page'
    );
  });

  module('localRecords', function () {
    const make = () =>
      localRecords<Row>(
        ROWS.map((row) => ({ ...row })),
        { getRecordId: getId, fields: FIELDS }
      );

    test('LG1 without a group-by: the records and no groups, nothing else changes', function (assert) {
      const store = make();
      assert.strictEqual(store.view.records, store.records);
      assert.deepEqual(store.view.groups, []);
      assert.deepEqual(store.groupBy, []);
      assert.strictEqual(store.view, store.view, 'cached');
      store.apply(
        changeSet({
          source: 'edit',
          patches: [{ recordId: 'r1', fieldId: 'qty', from: 1, to: 9 }]
        })
      );
      assert.strictEqual(store.view.records, store.records);
      assert.strictEqual(store.log.length, 1);
    });

    test('LG2 setGroupBy, toggleGroup and summaries make the view', function (assert) {
      const store = make();
      store.summaries = { qty: 'sum' };
      store.setGroupBy([{ field: 'status', direction: 'asc' }]);
      assert.deepEqual(keys(store.view.groups), [
        'status:Open',
        'status:Doing',
        'status:Done'
      ]);
      assert.strictEqual(store.view.groups[0]!.summary!['qty'], '12');
      assert.strictEqual(store.view.records.length, 6);

      store.toggleGroup('status:Open', true);
      assert.deepEqual(ids(store.view.records), ['r3', 'r1', 'r5']);
      assert.true(store.view.groups[0]!.collapsed);
      store.toggleGroup('status:Open', false);
      assert.strictEqual(store.view.records.length, 6);

      store.setGroupBy([]);
      assert.deepEqual(store.view.groups, []);
      assert.strictEqual(store.view.records, store.records);
    });

    test('LG3 an edit of the group field moves the record on the next view; an insert in an empty group lands in it', function (assert) {
      const store = make();
      store.setGroupBy([{ field: 'status', direction: 'asc' }]);
      store.apply(
        changeSet({
          source: 'edit',
          patches: [
            { recordId: 'r2', fieldId: 'status', from: 'open', to: 'done' }
          ]
        })
      );
      assert.deepEqual(
        store.view.groups.map((g) => [g.key, g.count]),
        [
          ['status:Open', 2],
          ['status:Doing', 1],
          ['status:Done', 3]
        ]
      );
      assert.deepEqual(ids(store.view.records), [
        'r4',
        'r6',
        'r3',
        'r1',
        'r2',
        'r5'
      ]);

      // the group's values come with the insert; it has no neighbour to anchor to
      store.apply(
        changeSet({
          source: 'insert',
          inserts: [
            {
              tempId: 'n1',
              index: 0,
              values: { status: 'doing' },
              groupKey: 'status:Doing'
            }
          ]
        })
      );
      const doing = store.view.groups.find((g) => g.key === 'status:Doing')!;
      assert.deepEqual([doing.count, doing.loaded], [2, 2]);
      assert.deepEqual(ids(store.view.records), [
        'r4',
        'r6',
        'n1',
        'r3',
        'r1',
        'r2',
        'r5'
      ]);
    });
  });
});
