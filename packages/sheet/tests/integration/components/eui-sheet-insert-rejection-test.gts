/**
 * A rejection on an inserted row (READINESS.md item 5, RI1-RI7): shown
 * while the cell holds the value its record arrived with, also when the
 * owner's `createRecord` gives the field a default (`qty: null`, `qty: 0`);
 * hidden once the owner changes it. For `api.appendRows` and a paste on the
 * add row; through undo and redo, and `remapIds`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { applyChangeSet, defaultMessages } from '#src/core/index.ts';
import { localRecords } from '#src/local-records.ts';
import {
  clipboard,
  focusCell,
  isInvalid,
  pressed,
  text
} from '../../helpers/sheet.ts';

import type { ChangeSet, EuiSheetField } from '#src/core/index.ts';
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
  { id: 'qty', label: 'Qty', type: 'number' }
];

/** An owner whose `createRecord` gives every new record `defaults` first. */
class Owner {
  @tracked records: Row[] = [
    { id: 'r0', name: 'Ana', qty: 1 },
    { id: 'r1', name: 'Bo', qty: 2 }
  ];
  log: ChangeSet[] = [];
  api: SheetApi | null = null;

  constructor(public defaults: Record<string, unknown>) {}

  register = (api: SheetApi) => (this.api = api);

  onChange = (changeSet: ChangeSet): void => {
    this.log.push(changeSet);
    this.records = applyChangeSet(this.records, changeSet, {
      getRecordId: getId,
      createRecord: (values, tempId) =>
        ({ id: tempId, name: '', ...this.defaults, ...values }) as Row
    });
  };

  /** The owner writes a value itself (not through the sheet). */
  set(index: number, values: Partial<Row>): void {
    this.records = this.records.map((row, i) =>
      i === index ? { ...row, ...values } : row
    );
  }

  get ids(): string[] {
    return this.records.map((row) => row.id);
  }
}

async function renderSheet(owner: Owner): Promise<void> {
  await render(
    <template>
      <EuiSheet
        @fields={{FIELDS}}
        @records={{owner.records}}
        @getRecordId={{getId}}
        @onChange={{owner.onChange}}
        @registerApi={{owner.register}}
      />
    </template>
  );
}

module(
  'Integration | Component | EuiSheet inserted-row rejections',
  function (hooks) {
    setupRenderingTest(hooks);

    test('RI1 appendRows: a bad number stays shown when createRecord gives qty: null', async function (assert) {
      const owner = new Owner({ qty: null });
      await renderSheet(owner);
      owner.api!.appendRows([['Caro', 'abc']], ['name', 'qty']);
      await settled();
      const [set] = owner.log;
      assert.deepEqual(set!.inserts[0]!.values, { name: 'Caro' });
      assert.strictEqual(set!.rejected.length, 1);
      assert.strictEqual(owner.records[2]!.qty, null, 'the owner’s default');
      assert.true(isInvalid(2, 1), 'the cell is invalid');
      assert.strictEqual(text(2, 1), 'abc', 'and shows the rejected text');
      // a later render (another cell's edit) keeps it
      await focusCell(0, 0);
      await pressed('Delete');
      assert.true(isInvalid(2, 1), 'still after another change set');
      assert.strictEqual(text(2, 1), 'abc');
    });

    test('RI2 a paste on the add row: shown with a default too', async function (assert) {
      const owner = new Owner({ qty: null });
      await renderSheet(owner);
      await focusCell(2, 0);
      await clipboard('paste', 'Caro\tabc\nDani\t4');
      const [set] = owner.log;
      assert.deepEqual(
        set!.inserts.map((insert) => insert.values),
        [{ name: 'Caro' }, { name: 'Dani', qty: 4 }]
      );
      assert.deepEqual(set!.rejected, [
        {
          tempId: set!.inserts[0]!.tempId,
          fieldId: 'qty',
          text: 'abc',
          message: defaultMessages.notANumber('abc')
        }
      ]);
      assert.true(isInvalid(2, 1), 'the rejected cell is invalid');
      assert.strictEqual(text(2, 1), 'abc');
      assert.false(isInvalid(3, 1));
      assert.strictEqual(text(3, 1), '4');
    });

    test('RI3 a default that is a value (qty: 0) does not hide it either', async function (assert) {
      const owner = new Owner({ qty: 0 });
      await renderSheet(owner);
      owner.api!.appendRows([['Caro', 'abc']], ['name', 'qty']);
      await settled();
      assert.strictEqual(owner.records[2]!.qty, 0);
      assert.true(isInvalid(2, 1));
      assert.strictEqual(text(2, 1), 'abc');
    });

    test('RI4 the owner changing the value afterwards hides it', async function (assert) {
      const owner = new Owner({ qty: null });
      await renderSheet(owner);
      owner.api!.appendRows([['Caro', 'abc']], ['name', 'qty']);
      await settled();
      assert.true(isInvalid(2, 1));
      owner.set(2, { qty: 5 });
      await settled();
      assert.false(isInvalid(2, 1), 'the owner’s value wins');
      assert.strictEqual(text(2, 1), '5');
    });

    test('RI5 undo removes the row; redo shows the rejection again', async function (assert) {
      const owner = new Owner({ qty: null });
      await renderSheet(owner);
      await focusCell(2, 0);
      await clipboard('paste', 'Caro\tabc');
      assert.true(isInvalid(2, 1));
      await focusCell(0, 0);
      await pressed('z', { ctrlKey: true });
      assert.deepEqual(owner.ids, ['r0', 'r1'], 'undone');
      await pressed('z', { ctrlKey: true, shiftKey: true });
      assert.strictEqual(owner.records.length, 3, 'redone');
      assert.strictEqual(owner.records[2]!.qty, null);
      assert.true(isInvalid(2, 1), 'the rejection is back');
      assert.strictEqual(text(2, 1), 'abc');
    });

    test('RI6 remapIds: the record’s new id keeps it', async function (assert) {
      const owner = new Owner({ qty: null });
      await renderSheet(owner);
      owner.api!.appendRows([['Caro', 'abc']], ['name', 'qty']);
      await settled();
      const tempId = owner.records[2]!.id;
      // the server answers with an id
      owner.records = owner.records.map((row) =>
        row.id === tempId ? { ...row, id: 'r9' } : row
      );
      owner.api!.remapIds({ [tempId]: 'r9' });
      await settled();
      assert.true(isInvalid(2, 1), 'still shown');
      assert.strictEqual(text(2, 1), 'abc');
      owner.set(2, { qty: 7 });
      await settled();
      assert.false(isInvalid(2, 1), 'and hidden by the owner’s change');
    });

    test('RI7 localRecords’ default createRecord: as before', async function (assert) {
      const store = localRecords<Row>(
        [
          { id: 'r0', name: 'Ana', qty: 1 },
          { id: 'r1', name: 'Bo', qty: 2 }
        ],
        { getRecordId: getId, fields: FIELDS }
      );
      await render(
        <template>
          <EuiSheet
            @records={{store.records}}
            @fields={{store.fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </template>
      );
      await focusCell(2, 0);
      await clipboard('paste', 'Caro\tabc');
      assert.strictEqual(store.records.length, 3);
      assert.strictEqual(store.records[2]!.qty, undefined, 'no default');
      assert.true(isInvalid(2, 1));
      assert.strictEqual(text(2, 1), 'abc');
    });
  }
);
