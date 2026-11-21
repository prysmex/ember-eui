/**
 * A paste on the add row fills `@newRecordValues` (v0.4, decision 10),
 * PNV1-PNV5: the fields the pasted text has no column for get the
 * owner's defaults, as `api.appendRows` does (APR7); the text's columns
 * win, also rejected and pending ones, and a group's values win over both.
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
import type { SheetApi } from '#src/types.ts';

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

type NewValues = (context: {
  above: Row | undefined;
  below: Row | undefined;
}) => Record<string, unknown>;

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
  api: SheetApi | null = null;
  newRecordValues: NewValues | undefined = undefined;
  onResolve:
    ((requests: ResolveRequest<Row>[]) => Promise<ResolveResult>) | undefined =
    undefined;

  register = (api: SheetApi) => (this.api = api);

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

/** A paste without waiting for the sheet to settle (a pending resolve holds the test waiter). */
async function pasteNow(value: string): Promise<void> {
  const clipboardData = new DataTransfer();
  clipboardData.setData('text/plain', value);
  document.activeElement!.dispatchEvent(
    new ClipboardEvent('paste', {
      clipboardData,
      bubbles: true,
      cancelable: true
    })
  );
  await waitUntil(() => document.querySelector('.euiSheet__cell--pending'));
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
        @registerApi={{owner.register}}
        @height={{300}}
      />
    </template>
  );
}

module(
  'Integration | Component | EuiSheet paste on the add row, @newRecordValues',
  function (hooks) {
    setupRenderingTest(hooks);

    test('PNV1 the fields with no pasted column get @newRecordValues, once per line; the pasted columns win, also a rejected one', async function (assert) {
      const owner = new Owner().defaults({
        name: 'default',
        qty: 0,
        due: '2026-01-01',
        code: 'NEW'
      });
      await renderSheet(owner);
      // from the add row's second column: qty and due have a column
      await focusCell(2, 1);
      await clipboard('paste', 'abc\t19/11/2026\n4\t');
      assert.strictEqual(owner.log.length, 1, 'one change set');
      const [set] = owner.log;
      assert.strictEqual(set!.source, 'paste');
      assert.deepEqual(
        set!.inserts.map((insert) => insert.values),
        [
          { name: 'default', code: 'NEW', due: '2026-11-19' },
          { name: 'default', code: 'NEW', qty: 4, due: null }
        ],
        'name (left of the paste) and code (hidden) from the defaults; qty stays rejected, not 0; an empty due stays empty'
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
        'called once per line, with the last record as above'
      );
      assert.deepEqual(
        [text(2, 0), text(2, 1), text(3, 0), text(3, 1)],
        ['default', 'abc', 'default', '4']
      );
      assert.true(isInvalid(2, 1), 'the rejected cell is shown invalid');
      assert.strictEqual(owner.records[2]!['code'], 'NEW');
      await focusCell(0, 0);
      await pressed('z', { ctrlKey: true });
      assert.deepEqual(owner.ids, ['r0', 'r1'], 'one undo step');
    });

    test('PNV2 without @newRecordValues the inserts have only the pasted values', async function (assert) {
      const owner = new Owner();
      await renderSheet(owner);
      await focusCell(2, 0);
      await clipboard('paste', 'Caro\t3');
      assert.deepEqual(owner.log[0]!.inserts[0]!.values, {
        name: 'Caro',
        qty: 3
      });
    });

    test('PNV3 with @onResolve: a pending column is not filled from the defaults; the resolved value lands after', async function (assert) {
      const owner = new Owner()
        .resolving()
        .defaults({ owner: { id: 'u9', label: 'Default' }, code: 'NEW' });
      owner.fields = [...FIELDS, { id: 'owner', label: 'Owner', type: 'user' }];
      await renderSheet(owner);
      await focusCell(2, 3);
      await pasteNow('Bo Vela');
      const [paste] = owner.log;
      const [insert] = paste!.inserts;
      assert.deepEqual(
        insert!.values,
        { code: 'NEW' },
        'the default for the pending owner column is not used'
      );
      assert.deepEqual(owner.seen, [['r1', undefined]]);
      assert.strictEqual(owner.calls.length, 1, 'one resolve call');
      owner.calls[0]!.resolve({ owner: { 'Bo Vela': BO } });
      await settled();
      assert.deepEqual(owner.log[1]!.patches, [
        { recordId: insert!.tempId, fieldId: 'owner', from: undefined, to: BO }
      ]);
      assert.deepEqual(owner.records[2]!['owner'], BO);
    });

    test('PNV4 a group’s add row: the group’s values win over the pasted text and the defaults; above is the group’s last record', async function (assert) {
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
      // header, r0, the Open group's add row (grid row 2)
      await focusCell(2, 0);
      await clipboard('paste', 'Caro\t\t\tLater\nDani');
      const inserts = owner.log[0]!.inserts;
      assert.deepEqual(
        inserts.map((insert) => [insert.values, insert.groupKey]),
        [
          [
            { name: 'Caro', qty: null, due: null, status: 'Open', code: 'NEW' },
            'status:Open'
          ],
          [{ name: 'Dani', status: 'Open', code: 'NEW' }, 'status:Open']
        ],
        'qty has a column: a pasted empty qty stays empty, and a short line does not get the default (as appendRows); status is the group’s'
      );
      assert.deepEqual(
        owner.seen,
        [
          ['r0', undefined],
          ['r0', undefined]
        ],
        'above: the group’s last loaded record'
      );
    });

    test('PNV5 a paste on a record row does not call @newRecordValues, also for its lines past the end', async function (assert) {
      const owner = new Owner().defaults({ code: 'NEW' });
      await renderSheet(owner);
      await focusCell(1, 0);
      await clipboard('paste', 'Bea\nCaro');
      const [set] = owner.log;
      assert.deepEqual(
        set!.patches.map((patch) => [patch.recordId, patch.to]),
        [['r1', 'Bea']]
      );
      assert.deepEqual(
        set!.inserts.map((insert) => insert.values),
        [{ name: 'Caro' }],
        'the line past the end: the pasted values only (unchanged)'
      );
      assert.deepEqual(owner.seen, [], 'no call');
    });
  }
);
