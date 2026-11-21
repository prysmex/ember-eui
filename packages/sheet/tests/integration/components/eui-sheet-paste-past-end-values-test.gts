/**
 * A paste from a record row whose lines run past the last record: the new
 * records get `@newRecordValues` (READINESS.md, the user's decision 1),
 * PPV1-PPV5, through the same path as a paste on the add row (PNV1-PNV4)
 * and `api.appendRows` (APR7): called once per insert with the last record
 * as `above`, for the fields the text has no column for; the text's
 * columns win (also rejected and pending ones), a group's values win over
 * both, and the records pasted over get none.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { applyChangeSet, defaultMessages } from '#src/core/index.ts';
import {
  clipboard,
  focusCell,
  isInvalid,
  pressed,
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

interface Row {
  id: string;
  name: string;
  qty: number | null;
  [key: string]: unknown;
}

const getId = (row: Row) => row.id;

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'qty', label: 'Qty', type: 'number' },
  { id: 'due', label: 'Due', type: 'date' }
];

const HIDDEN: EuiSheetField<Row>[] = [{ id: 'code', label: 'Code' }];

const BO: SheetUser = { id: 'u2', label: 'Bo Vela' };

interface Call {
  requests: ResolveRequest<Row>[];
  resolve: (result: ResolveResult) => void;
}

/** An owner: tracked records, `applyChangeSet` in `@onChange`. */
class Owner {
  @tracked fields: EuiSheetField<Row>[] = FIELDS;
  @tracked hidden: EuiSheetField<Row>[] = HIDDEN;
  @tracked records: Row[] = [
    { id: 'r0', name: 'Ana', qty: 1, due: null },
    { id: 'r1', name: 'Bo', qty: 2, due: null }
  ];
  @tracked groupBy: SheetGroupBy[] | undefined = undefined;
  @tracked groups: SheetGroup[] | undefined = undefined;
  log: ChangeSet[] = [];
  calls: Call[] = [];
  /** `[above, below]` ids of each `@newRecordValues` call. */
  seen: Array<[string | undefined, string | undefined]> = [];
  newRecordValues:
    | ((context: {
        above: Row | undefined;
        below: Row | undefined;
      }) => Record<string, unknown>)
    | undefined = undefined;
  onResolve:
    ((requests: ResolveRequest<Row>[]) => Promise<ResolveResult>) | undefined =
    undefined;

  onChange = (changeSet: ChangeSet): void => {
    this.log.push(changeSet);
    this.records = applyChangeSet(this.records, changeSet, {
      getRecordId: getId,
      createRecord: (values, tempId) => ({ id: tempId, ...values }) as Row
    });
  };

  /** `@newRecordValues` giving `values`, logging its calls. */
  defaults(values: Record<string, unknown>): this {
    this.newRecordValues = ({ above, below }) => {
      this.seen.push([above?.id, below?.id]);
      return { ...values };
    };
    return this;
  }

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
        @newRecordValues={{owner.newRecordValues}}
        @groupBy={{owner.groupBy}}
        @groups={{owner.groups}}
        @height={{300}}
      />
    </template>
  );
}

module(
  'Integration | Component | EuiSheet paste past the last record, @newRecordValues',
  function (hooks) {
    setupRenderingTest(hooks);

    test('PPV1 once per line past the end, the last record as above; the pasted columns win, also a rejected one and a short line; the record pasted over gets none', async function (assert) {
      const owner = new Owner().defaults({
        name: 'default',
        qty: 0,
        due: '2026-01-01',
        code: 'NEW'
      });
      await renderSheet(owner);
      // from r1's first column: name and qty have a column
      await focusCell(1, 0);
      await clipboard('paste', 'Bea\t5\nCaro\tabc\nDani');
      assert.strictEqual(owner.log.length, 1, 'one change set');
      const [set] = owner.log;
      assert.strictEqual(set!.source, 'paste');
      assert.deepEqual(
        set!.patches.map((patch) => [patch.recordId, patch.fieldId, patch.to]),
        [
          ['r1', 'name', 'Bea'],
          ['r1', 'qty', 5]
        ],
        'the record pasted over: only the pasted values'
      );
      assert.deepEqual(
        set!.inserts.map((insert) => insert.values),
        [
          { name: 'Caro', due: '2026-01-01', code: 'NEW' },
          { name: 'Dani', due: '2026-01-01', code: 'NEW' }
        ],
        'due (no column) and code (hidden) from the defaults; qty stays rejected, not 0; a short line does not get the default'
      );
      assert.deepEqual(set!.rejected, [
        {
          tempId: set!.inserts[0]!.tempId,
          fieldId: 'qty',
          text: 'abc',
          message: defaultMessages.notANumber('abc')
        }
      ]);
      assert.deepEqual(
        owner.seen,
        [
          ['r1', undefined],
          ['r1', undefined]
        ],
        'two calls: one per insert, none for the line pasted over'
      );
      assert.strictEqual(owner.records[1]!['due'], null, 'r1 keeps its due');
      assert.deepEqual(
        owner.records.slice(2).map((row) => row['code']),
        ['NEW', 'NEW']
      );
      assert.deepEqual(
        [text(2, 0), text(2, 1), text(2, 2), text(3, 0)],
        ['Caro', 'abc', '01/01/2026', 'Dani']
      );
      assert.true(isInvalid(2, 1), 'the rejected cell is shown invalid');
    });

    test('PPV2 one undo step takes the inserts and the patch back', async function (assert) {
      const owner = new Owner().defaults({ code: 'NEW' });
      await renderSheet(owner);
      await focusCell(1, 0);
      await clipboard('paste', 'Bea\nCaro\nDani');
      assert.deepEqual(owner.ids.length, 4);
      await focusCell(0, 0);
      await pressed('z', { ctrlKey: true });
      assert.deepEqual(owner.ids, ['r0', 'r1'], 'the inserts are gone');
      assert.strictEqual(owner.records[1]!.name, 'Bo', 'the patch is undone');
      await pressed('z', { ctrlKey: true, shiftKey: true });
      assert.deepEqual(
        owner.records.slice(1).map((row) => [row.name, row['code']]),
        [
          ['Bea', undefined],
          ['Caro', 'NEW'],
          ['Dani', 'NEW']
        ],
        'redo brings the defaults back'
      );
      assert.strictEqual(owner.seen.length, 2, 'redo does not call again');
    });

    test('PPV3 without @newRecordValues the inserts have only the pasted values; with no line past the end, no call', async function (assert) {
      const plain = new Owner();
      await renderSheet(plain);
      await focusCell(1, 0);
      await clipboard('paste', 'Bea\nCaro');
      assert.deepEqual(
        plain.log[0]!.inserts.map((insert) => insert.values),
        [{ name: 'Caro' }]
      );

      const owner = new Owner().defaults({ code: 'NEW' });
      await renderSheet(owner);
      await focusCell(0, 0);
      await clipboard('paste', 'Ana 2\nBo 2');
      assert.deepEqual(owner.log[0]!.inserts, [], 'no insert');
      assert.deepEqual(owner.seen, [], 'no call');
    });

    test('PPV4 with @onResolve: a pending column of a line past the end is not filled from the defaults; the resolved value lands after', async function (assert) {
      const owner = new Owner()
        .resolving()
        .defaults({ owner: { id: 'u9', label: 'Default' }, code: 'NEW' });
      owner.fields = [...FIELDS, { id: 'owner', label: 'Owner', type: 'user' }];
      await renderSheet(owner);
      await focusCell(1, 3);
      const clipboardData = new DataTransfer();
      clipboardData.setData('text/plain', 'Bo Vela\nBo Vela');
      document.activeElement!.dispatchEvent(
        new ClipboardEvent('paste', {
          clipboardData,
          bubbles: true,
          cancelable: true
        })
      );
      await waitUntil(() => document.querySelector('.euiSheet__cell--pending'));
      const [paste] = owner.log;
      const [insert] = paste!.inserts;
      assert.deepEqual(
        insert!.values,
        { code: 'NEW' },
        'the default for the pending owner column is not used'
      );
      assert.deepEqual(owner.seen, [['r1', undefined]], 'one call');
      assert.strictEqual(owner.calls.length, 1, 'one resolve call');
      owner.calls[0]!.resolve({ owner: { 'Bo Vela': BO } });
      await settled();
      assert.deepEqual(
        owner.log[1]!.patches.map((patch) => [patch.recordId, patch.to]),
        [
          ['r1', BO],
          [insert!.tempId, BO]
        ]
      );
      assert.deepEqual(owner.records[2]!['owner'], BO);
    });

    test('PPV5 grouped: the lines past the end go into the last record’s group, its values win over the pasted text and the defaults', async function (assert) {
      const owner = new Owner().defaults({
        status: 'Elsewhere',
        qty: 9,
        code: 'NEW'
      });
      owner.fields = [...FIELDS, { id: 'status', label: 'Status' }];
      owner.records = [
        { id: 'r0', name: 'Ana', qty: 1, status: 'Open' },
        { id: 'r1', name: 'Bo', qty: 2, status: 'Done' }
      ];
      owner.groupBy = [{ field: 'status', direction: 'asc' }];
      owner.groups = [
        { key: 'status:Open', depth: 0, value: 'Open', count: 1, loaded: 1 },
        { key: 'status:Done', depth: 0, value: 'Done', count: 1, loaded: 1 }
      ];
      await renderSheet(owner);
      // header, r0, Open's add row, header, r1 (grid row 4)
      await focusCell(4, 0);
      await clipboard('paste', 'Bea\nCaro\t\t\tLater');
      const [set] = owner.log;
      assert.deepEqual(
        set!.patches.map((patch) => [patch.recordId, patch.fieldId, patch.to]),
        [['r1', 'name', 'Bea']]
      );
      assert.deepEqual(
        set!.inserts.map((insert) => [insert.values, insert.groupKey]),
        [
          [
            { name: 'Caro', qty: null, due: null, status: 'Done', code: 'NEW' },
            'status:Done'
          ]
        ],
        'qty has a column: a pasted empty qty stays empty; status is the group’s'
      );
      assert.deepEqual(
        owner.seen,
        [['r1', undefined]],
        'above: the last record'
      );
    });
  }
);
