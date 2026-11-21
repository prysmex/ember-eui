/**
 * `api.appendRows` (v0.4 07), APR1-APR8: an import's rows as new records,
 * through a paste's path on the add row; with batch E's `fields` option
 * (APR6). The prefix is APR: AR1-AR9 are the add row's (rows-test).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { applyChangeSet, defaultMessages } from '#src/core/index.ts';
import {
  cell,
  focusCell,
  isInvalid,
  pressed,
  selected,
  text
} from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  ResolveRequest,
  ResolveResult,
  SheetGroup,
  SheetGroupBy,
  SheetUser
} from '#src/core/index.ts';
import type { SheetApi } from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  qty: number | null;
  [key: string]: unknown;
}

const getId = (row: Row) => row.id;

const DUE: EuiSheetField<Row> = { id: 'due', label: 'Due', type: 'date' };

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'qty', label: 'Qty', type: 'number' },
  DUE
];

const HIDDEN: EuiSheetField<Row>[] = [{ id: 'code', label: 'Code' }];

const BO: SheetUser = { id: 'u2', label: 'Bo Vela' };

interface Call {
  requests: ResolveRequest<Row>[];
  resolve: (result: ResolveResult) => void;
}

/** An owner: tracked records, `applyChangeSet` in `@onChange` (so a change set is applied at once). */
class Owner {
  @tracked fields: EuiSheetField<Row>[] = FIELDS;
  @tracked hidden: EuiSheetField<Row>[] = HIDDEN;
  @tracked records: Row[] = [
    { id: 'r0', name: 'Ana', qty: 1, due: null },
    { id: 'r1', name: 'Bo', qty: 2, due: null }
  ];
  @tracked canInsert: boolean | undefined = undefined;
  @tracked groupBy: SheetGroupBy[] | undefined = undefined;
  @tracked groups: SheetGroup[] | undefined = undefined;
  log: ChangeSet[] = [];
  calls: Call[] = [];
  api: SheetApi | null = null;
  newRecordValues:
    | ((context: {
        above: Row | undefined;
        below: Row | undefined;
      }) => Record<string, unknown>)
    | undefined = undefined;
  onResolve:
    ((requests: ResolveRequest<Row>[]) => Promise<ResolveResult>) | undefined =
    undefined;

  register = (api: SheetApi) => (this.api = api);

  onChange = (changeSet: ChangeSet): void => {
    this.log.push(changeSet);
    this.records = applyChangeSet(this.records, changeSet, {
      getRecordId: getId,
      // no defaults: a rejection shows while the cell's value is the one
      // the sheet saw (none, for a new row)
      createRecord: (values, tempId) => ({ id: tempId, ...values }) as Row
    });
  };

  /** A controllable `@onResolve`. */
  resolving(): this {
    this.onResolve = (requests) =>
      new Promise((resolve) => {
        this.calls.push({ requests, resolve });
      });
    return this;
  }

  get ids(): string[] {
    return this.records.map((row) => row.id);
  }
}

async function renderSheet(owner: Owner): Promise<void> {
  await render(
    <template>
      <EuiSheet
        @fields={{owner.fields}}
        @hiddenFields={{owner.hidden}}
        @records={{owner.records}}
        @getRecordId={{getId}}
        @onChange={{owner.onChange}}
        @onResolve={{owner.onResolve}}
        @canInsert={{owner.canInsert}}
        @newRecordValues={{owner.newRecordValues}}
        @groupBy={{owner.groupBy}}
        @groups={{owner.groups}}
        @registerApi={{owner.register}}
        @height={{300}}
      />
    </template>
  );
}

module('Integration | Component | EuiSheet appendRows', function (hooks) {
  setupRenderingTest(hooks);

  test('APR1 one change set with one insert per row; Ctrl/Cmd+Z removes them all', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    await focusCell(0, 0);
    const appended = owner.api!.appendRows(
      [
        ['Caro', '3'],
        ['Dani', '4'],
        ['Eve', '5']
      ],
      ['name', 'qty']
    );
    await settled();
    assert.true(appended, 'returns true');
    assert.strictEqual(owner.log.length, 1, 'one change set');
    const [set] = owner.log;
    assert.strictEqual(set!.source, 'paste');
    assert.deepEqual(set!.patches, []);
    assert.deepEqual(set!.rejected, []);
    const inserts = set!.inserts;
    assert.deepEqual(
      inserts.map((insert) => [insert.index, insert.values]),
      [
        [2, { name: 'Caro', qty: 3 }],
        [3, { name: 'Dani', qty: 4 }],
        [4, { name: 'Eve', qty: 5 }]
      ]
    );
    assert.deepEqual(
      inserts.map((insert) => insert.anchor),
      [
        { recordId: 'r1', position: 'after' },
        { recordId: inserts[0]!.tempId, position: 'after' },
        { recordId: inserts[1]!.tempId, position: 'after' }
      ],
      'after the last record, then each after the previous'
    );
    assert.deepEqual(
      [text(2, 0), text(3, 0), text(4, 0), text(4, 1)],
      ['Caro', 'Dani', 'Eve', '5'],
      'the new rows are shown'
    );
    assert.strictEqual(
      document.activeElement,
      cell(0, 0),
      'focus did not move'
    );
    assert.deepEqual(selected(), ['0:0'], 'nor did the selection');
    await pressed('z', { ctrlKey: true });
    assert.deepEqual(owner.ids, ['r0', 'r1'], 'one undo removes every row');
    assert.strictEqual(owner.log.length, 2);
    assert.strictEqual(owner.log[1]!.source, 'undo');
  });

  test('APR2 a bad number is a rejection in the new row, shown as in a paste', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    owner.api!.appendRows([['Caro', 'abc']], ['name', 'qty']);
    await settled();
    const [set] = owner.log;
    const tempId = set!.inserts[0]!.tempId;
    assert.deepEqual(set!.inserts[0]!.values, { name: 'Caro' });
    assert.deepEqual(set!.rejected, [
      {
        tempId,
        fieldId: 'qty',
        text: 'abc',
        message: defaultMessages.notANumber('abc')
      }
    ]);
    assert.true(isInvalid(2, 1), 'the cell is invalid');
    assert.strictEqual(text(2, 1), 'abc', 'and shows the text');
    assert.strictEqual(text(2, 0), 'Caro');
    await focusCell(0, 0);
    await pressed('z', { ctrlKey: true });
    assert.deepEqual(owner.ids, ['r0', 'r1']);
  });

  test('APR3 a user column goes through @onResolve; one undo step', async function (assert) {
    const owner = new Owner().resolving();
    owner.fields = [...FIELDS, { id: 'owner', label: 'Owner', type: 'user' }];
    await renderSheet(owner);
    owner.api!.appendRows(
      [
        ['Caro', 'Bo Vela'],
        ['Dani', 'Nobody']
      ],
      ['name', 'owner']
    );
    assert.strictEqual(owner.calls.length, 1, 'one call');
    const [call] = owner.calls;
    const [paste] = owner.log;
    const [first, second] = paste!.inserts;
    assert.deepEqual(
      paste!.inserts.map((insert) => insert.values),
      [{ name: 'Caro' }, { name: 'Dani' }],
      'the inserts at once, without the pending cells'
    );
    assert.deepEqual(call!.requests.length, 1);
    assert.strictEqual(call!.requests[0]!.fieldId, 'owner');
    assert.deepEqual(call!.requests[0]!.texts, ['Bo Vela', 'Nobody']);
    assert.deepEqual(
      call!.requests[0]!.cells.map((c) => [c.text, c.tempId]),
      [
        ['Bo Vela', first!.tempId],
        ['Nobody', second!.tempId]
      ]
    );
    call!.resolve({ owner: { 'Bo Vela': BO, Nobody: null } });
    await settled();
    assert.deepEqual(
      owner.log.map((set) => set.source),
      ['paste', 'resolve']
    );
    assert.deepEqual(owner.log[1]!.patches, [
      { recordId: first!.tempId, fieldId: 'owner', from: undefined, to: BO }
    ]);
    assert.deepEqual(
      owner.log[1]!.rejected.map((r) => [r.tempId, r.text]),
      [[second!.tempId, 'Nobody']]
    );
    assert.true(isInvalid(3, 3), 'the unresolved text is a rejection');
    await focusCell(0, 0);
    await pressed('z', { ctrlKey: true });
    assert.deepEqual(owner.ids, ['r0', 'r1'], 'one undo: both change sets');
    assert.strictEqual(owner.log.length, 3);
  });

  test('APR4 with @canInsert={{false}} nothing is emitted and it returns false', async function (assert) {
    const owner = new Owner();
    owner.canInsert = false;
    await renderSheet(owner);
    assert.false(owner.api!.appendRows([['Caro', '3']], ['name', 'qty']));
    await settled();
    assert.deepEqual(owner.log, []);
    owner.canInsert = undefined;
    await settled();
    assert.false(owner.api!.appendRows([], ['name']), 'no rows: false');
    assert.false(
      owner.api!.appendRows([['x']], ['nope']),
      'no known field: false'
    );
    assert.deepEqual(owner.log, [], 'nothing emitted');
    assert.true(owner.api!.appendRows([['x']], ['name']));
  });

  test('APR5 columns in another order and a hidden field: each value lands in its own field; grouped, the group field takes the last group’s value', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    owner.api!.appendRows(
      [
        ['D-1', 'zzz', '5', 'Eve', '19/11/2026'],
        ['D-2', 'yyy', '', 'Fer']
      ],
      ['code', 'nope', 'qty', 'name', 'due']
    );
    await settled();
    assert.deepEqual(
      owner.log[0]!.inserts.map((insert) => insert.values),
      [
        { code: 'D-1', qty: 5, name: 'Eve', due: '2026-11-19' },
        { code: 'D-2', qty: null, name: 'Fer' }
      ],
      'by id, not by position; an unknown id is dropped; a short row has only its cells'
    );
    assert.deepEqual(
      [text(2, 0), text(2, 1), text(2, 2)],
      ['Eve', '5', '19/11/2026']
    );

    // grouped by `status`: into the last group, whose value wins
    const grouped = new Owner();
    grouped.fields = [...FIELDS, { id: 'status', label: 'Status' }];
    grouped.records = [
      { id: 'r0', name: 'Ana', qty: 1, status: 'Open' },
      { id: 'r1', name: 'Bo', qty: 2, status: 'Done' }
    ];
    grouped.groupBy = [{ field: 'status', direction: 'asc' }];
    grouped.groups = [
      { key: 'status:Open', depth: 0, value: 'Open', count: 1, loaded: 1 },
      { key: 'status:Done', depth: 0, value: 'Done', count: 1, loaded: 1 }
    ];
    await renderSheet(grouped);
    grouped.api!.appendRows(
      [
        ['Caro', 'Open'],
        ['Dani', 'Later']
      ],
      ['name', 'status']
    );
    await settled();
    const inserts = grouped.log[0]!.inserts;
    assert.deepEqual(
      inserts.map((insert) => [insert.values, insert.groupKey]),
      [
        [{ name: 'Caro', status: 'Done' }, 'status:Done'],
        [{ name: 'Dani', status: 'Done' }, 'status:Done']
      ],
      'the group’s value overwrites the file’s'
    );
    assert.deepEqual(inserts[0]!.anchor, { recordId: 'r1', position: 'after' });
  });

  test('APR6 fields: an id @fields does not have yet, and an M/D/Y copy of a D/M/Y field; never stored', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    const size: EuiSheetField<Row> = {
      id: 'size',
      label: 'Size',
      type: 'number',
      decimalSeparator: ','
    };
    const mdy = { ...DUE, dateOrder: 'mdy' };
    owner.api!.appendRows(
      [
        ['Caro', '12,5', '11/19/2026'],
        ['Dani', '1.234,5', '02/01/2026']
      ],
      ['name', 'size', 'due'],
      { fields: [size, mdy] }
    );
    await settled();
    assert.deepEqual(
      owner.log[0]!.inserts.map((insert) => insert.values),
      [
        { name: 'Caro', size: 12.5, due: '2026-11-19' },
        { name: 'Dani', size: 1234.5, due: '2026-02-01' }
      ],
      'read with the given fields'
    );
    assert.deepEqual(owner.log[0]!.rejected, []);
    assert.strictEqual(owner.fields[2], DUE, 'the stored field is unchanged');
    assert.strictEqual(DUE['dateOrder'], undefined);
    assert.strictEqual(
      text(2, 2),
      '19/11/2026',
      'shown with the stored field (D/M/Y)'
    );

    // without `fields`: the new id is dropped, the date read as D/M/Y
    owner.api!.appendRows(
      [['Eve', '12,5', '11/19/2026']],
      ['name', 'size', 'due']
    );
    await settled();
    assert.deepEqual(owner.log[1]!.inserts[0]!.values, { name: 'Eve' });
    assert.deepEqual(
      owner.log[1]!.rejected.map((r) => [r.fieldId, r.text]),
      [['due', '11/19/2026']],
      'month 19 is not a D/M/Y date'
    );

    // a user field given only through `fields`, through @onResolve
    const resolving = new Owner().resolving();
    await renderSheet(resolving);
    const boss: EuiSheetField<Row> = {
      id: 'boss',
      label: 'Boss',
      type: 'user'
    };
    resolving.api!.appendRows([['Caro', 'Bo Vela']], ['name', 'boss'], {
      fields: [boss]
    });
    const [call] = resolving.calls;
    assert.strictEqual(call!.requests[0]!.fieldId, 'boss');
    call!.resolve({ boss: { 'Bo Vela': BO } });
    await settled();
    const tempId = resolving.log[0]!.inserts[0]!.tempId;
    assert.deepEqual(
      resolving.log[1]!.patches,
      [{ recordId: tempId, fieldId: 'boss', from: undefined, to: BO }],
      'resolved with the given field, not dropped'
    );
  });

  test('APR7 @newRecordValues fills the fields the file has no column for; the file’s columns win, also rejected ones', async function (assert) {
    const owner = new Owner();
    const calls: Array<[string | undefined, string | undefined]> = [];
    owner.newRecordValues = ({ above, below }) => {
      calls.push([above?.id, below?.id]);
      return { name: 'default', qty: 0, code: 'NEW' };
    };
    await renderSheet(owner);
    owner.api!.appendRows(
      [
        ['Caro', 'abc'],
        ['Dani', '4']
      ],
      ['name', 'qty']
    );
    await settled();
    assert.deepEqual(
      owner.log[0]!.inserts.map((insert) => insert.values),
      [
        { code: 'NEW', name: 'Caro' },
        { code: 'NEW', name: 'Dani', qty: 4 }
      ],
      'qty stays rejected on the first row, not 0'
    );
    assert.deepEqual(
      calls,
      [
        ['r1', undefined],
        ['r1', undefined]
      ],
      'called once per line, with the last record as above'
    );
    assert.strictEqual(text(2, 1), 'abc');
  });

  test('APR8 chunks: two calls in a row append in order, each its own undo step', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    owner.api!.appendRows([['a'], ['b']], ['name']);
    owner.api!.appendRows([['c'], ['d']], ['name']);
    await settled();
    assert.deepEqual(
      owner.records.map((row) => row.name),
      ['Ana', 'Bo', 'a', 'b', 'c', 'd'],
      'the second chunk after the first (the owner applied it)'
    );
    await focusCell(0, 0);
    await pressed('z', { ctrlKey: true });
    assert.deepEqual(
      owner.records.map((row) => row.name),
      ['Ana', 'Bo', 'a', 'b']
    );
    await pressed('z', { ctrlKey: true });
    assert.deepEqual(
      owner.records.map((row) => row.name),
      ['Ana', 'Bo']
    );
  });
});
