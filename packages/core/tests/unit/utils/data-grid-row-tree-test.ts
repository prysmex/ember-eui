import { module, test } from 'qunit';

import {
  buildFlatRows,
  buildRowTree,
  collectExpandableIds,
  compareGroupValues,
  findAncestors,
  flattenRowTree,
  groupId,
  groupRowTree,
  isNestedRowSource,
  sortRowTree
} from '#src/utils/data-grid/row-tree.ts';

import type { RowTreeNode } from '#src/utils/data-grid/row-tree.ts';

const nested = [
  {
    id: 'a',
    name: 'A',
    children: [
      { id: 'a1', name: 'A1', children: [{ id: 'a1x', name: 'A1x' }] },
      { id: 'a2', name: 'A2' }
    ]
  },
  { id: 'b', name: 'B' }
];

const all = () => true;
const none = () => false;
const ids = (rows: { id: string }[]) => rows.map((row) => row.id);

module('Unit | utils | data-grid row-tree', function () {
  test('nested rows: pre-order row indexes, ids from `id`', function (assert) {
    const { roots, rows } = buildRowTree({ rows: nested });
    assert.deepEqual(
      (rows as { id: string }[]).map((row) => row.id),
      ['a', 'a1', 'a1x', 'a2', 'b']
    );
    assert.deepEqual(ids(roots), ['a', 'b']);
    assert.deepEqual(
      roots[0]!.children.map((node) => [node.id, node.rowIndex]),
      [
        ['a1', 1],
        ['a2', 3]
      ]
    );
    assert.true(isNestedRowSource({ rows: nested }));
  });

  test('flattens only expanded rows with depth, set size and position', function (assert) {
    const { roots } = buildRowTree({ rows: nested });
    assert.deepEqual(ids(flattenRowTree(roots, none)), ['a', 'b']);

    const visible = flattenRowTree(roots, (node) => node.id === 'a');
    assert.deepEqual(ids(visible), ['a', 'a1', 'a2', 'b']);
    assert.deepEqual(
      visible.map(({ depth, posInSet, setSize, hasChildren, isExpanded, parentId }) => [
        depth,
        posInSet,
        setSize,
        hasChildren,
        isExpanded,
        parentId
      ]),
      [
        [0, 1, 2, true, true, null],
        [1, 1, 2, true, false, 'a'],
        [1, 2, 2, false, false, 'a'],
        [0, 2, 2, false, false, null]
      ]
    );
    assert.deepEqual(ids(flattenRowTree(roots, all)), ['a', 'a1', 'a1x', 'a2', 'b']);
  });

  test('a collapsed ancestor hides expanded descendants', function (assert) {
    const { roots } = buildRowTree({ rows: nested });
    const visible = flattenRowTree(roots, (node) => node.id === 'a1');
    assert.deepEqual(ids(visible), ['a', 'b']);
  });

  test('flat rows with parentId keep their array index', function (assert) {
    const flat = [
      { id: 1, name: 'child', parentId: 2 },
      { id: 2, name: 'root' },
      { id: 3, name: 'grandchild', parent: 1 },
      { id: 4, name: 'orphan', parentId: 99 }
    ];
    assert.false(isNestedRowSource({ rows: flat }));
    const { roots, rows } = buildRowTree({ rows: flat });
    assert.strictEqual(rows, flat);
    assert.deepEqual(ids(roots), ['2', '4'], 'orphans are roots');
    const visible = flattenRowTree(roots, all);
    assert.deepEqual(
      visible.map((row) => [row.id, row.rowIndex, row.depth]),
      [
        ['2', 1, 0],
        ['1', 0, 1],
        ['3', 2, 2],
        ['4', 3, 0]
      ]
    );
  });

  test('custom accessors and missing ids', function (assert) {
    const data = [{ key: 'x', kids: [{ key: 'y' }] }, { kids: [] }];
    const { roots } = buildRowTree({
      rows: data,
      getChildren: (row: { kids?: unknown[] }) => row.kids as never,
      getRowId: (row: { key?: string }) => row.key
    });
    assert.deepEqual(ids(flattenRowTree(roots, all)), ['x', 'y', '2']);

    const flat = buildRowTree({
      rows: [{ ref: 'p' }, { ref: 'c', up: 'p' }],
      getRowId: (row: { ref: string }) => row.ref,
      getParentId: (row: { up?: string }) => row.up
    });
    assert.deepEqual(ids(flattenRowTree(flat.roots, all)), ['p', 'c']);
    assert.deepEqual(ids(flattenRowTree(buildRowTree({ rows: [{}, {}] }).roots, all)), ['0', '1']);
  });

  test('cycles do not loop', function (assert) {
    const a: Record<string, unknown> = { id: 'a' };
    a['children'] = [a, { id: 'b' }];
    const nestedCycle = buildRowTree({ rows: [a] });
    assert.deepEqual(ids(flattenRowTree(nestedCycle.roots, all)), ['a', 'b']);

    const flatCycle = buildRowTree({
      rows: [
        { id: 1, parentId: 2 },
        { id: 2, parentId: 1 },
        { id: 3, parentId: 3 }
      ]
    });
    assert.strictEqual(flattenRowTree(flatCycle.roots, all).length, 3);
  });

  test('groups flat rows by column values', function (assert) {
    const data = [
      { country: 'FR', city: 'Paris' },
      { country: 'US', city: 'NYC' },
      { country: 'FR', city: 'Lyon' },
      { country: 'FR', city: 'Paris' }
    ];
    const getValue = (rowIndex: number, columnId: string) =>
      (data[rowIndex] as Record<string, string>)[columnId];
    const roots = groupRowTree(buildFlatRows(data.length), ['country', 'city'], getValue);

    assert.deepEqual(ids(roots), [groupId(['FR']), groupId(['US'])]);
    const fr = roots[0]!;
    assert.strictEqual(fr.kind, 'group');
    assert.deepEqual(fr.group, {
      columnId: 'country',
      value: 'FR',
      count: 3,
      rowIndices: [0, 2, 3]
    });
    assert.deepEqual(
      fr.children.map((node) => [node.id, node.group!.count]),
      [
        [groupId(['FR', 'Paris']), 2],
        [groupId(['FR', 'Lyon']), 1]
      ]
    );
    assert.deepEqual(
      fr.children[0]!.children.map((node) => node.rowIndex),
      [0, 3]
    );

    const visible = flattenRowTree(roots, all);
    assert.deepEqual(
      visible.map((row) => [row.kind, row.depth, row.rowIndex]),
      [
        ['group', 0, -1],
        ['group', 1, -2],
        ['row', 2, 0],
        ['row', 2, 3],
        ['group', 1, -3],
        ['row', 2, 2],
        ['group', 0, -4],
        ['group', 1, -5],
        ['row', 2, 1]
      ],
      'group rows get stable negative row indexes'
    );
    assert.deepEqual(collectExpandableIds(roots).group.length, 5);
    assert.deepEqual(collectExpandableIds(roots).row, []);
  });

  test('group ids distinguish value types; dates group by time', function (assert) {
    assert.notStrictEqual(groupId([1]), groupId(['1']));
    const values = [new Date(0), new Date(0), null, undefined];
    const roots = groupRowTree(buildFlatRows(4), ['d'], (i) => values[i]);
    assert.deepEqual(
      roots.map((node) => node.group!.count),
      [2, 2]
    );
    assert.strictEqual(groupId([undefined]), groupId([null]));
  });

  test('grouping keeps the subtrees of grouped rows', function (assert) {
    const { roots, rows } = buildRowTree({
      rows: [
        { id: 'p', team: 'x', children: [{ id: 'c', team: 'y' }] },
        { id: 'q', team: 'y' }
      ]
    });
    const grouped = groupRowTree(roots, ['team'], (i, col) =>
      (rows[i] as Record<string, string>)[col]
    );
    assert.deepEqual(
      grouped.map((node) => node.group!.value),
      ['x', 'y'],
      'only the root rows are grouped'
    );
    assert.deepEqual(ids(flattenRowTree(grouped, all)), [groupId(['x']), 'p', 'c', groupId(['y']), 'q']);
  });

  test('sorts siblings at every level, stable', function (assert) {
    const { roots } = buildRowTree({ rows: nested });
    const rank: Record<string, number> = { a: 2, b: 1, a1: 5, a2: 4 };
    const sorted = sortRowTree(roots, (x: RowTreeNode, y: RowTreeNode) => (rank[x.id] ?? 0) - (rank[y.id] ?? 0));
    assert.deepEqual(ids(flattenRowTree(sorted, all)), ['b', 'a', 'a2', 'a1', 'a1x']);
    assert.deepEqual(ids(roots), ['a', 'b'], 'does not mutate');
    const stable = sortRowTree(roots, () => 0);
    assert.deepEqual(ids(flattenRowTree(stable, all)), ['a', 'a1', 'a1x', 'a2', 'b']);
  });

  test('compareGroupValues', function (assert) {
    assert.true(compareGroupValues(2, 10) < 0, 'numbers numerically');
    assert.true(compareGroupValues('item 2', 'item 10') < 0, 'text naturally');
    assert.true(compareGroupValues('b', 'A') > 0, 'case insensitive');
    assert.true(compareGroupValues(null, 'a') > 0, 'empty last');
    assert.true(compareGroupValues('', 'a') > 0, 'empty string last');
    assert.strictEqual(compareGroupValues(undefined, null), 0);
    assert.true(compareGroupValues(new Date(1), new Date(2)) < 0, 'dates by time');
    assert.true(compareGroupValues(false, true) < 0);
  });

  test('findAncestors', function (assert) {
    const { roots } = buildRowTree({ rows: nested });
    assert.deepEqual(ids(findAncestors(roots, 2)!), ['a', 'a1']);
    assert.deepEqual(findAncestors(roots, 0), []);
    assert.strictEqual(findAncestors(roots, 42), null);
    assert.deepEqual(collectExpandableIds(roots).row, ['a', 'a1']);
  });
});
