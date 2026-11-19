/** Undo and redo: Ctrl/Cmd+Z, Ctrl/Cmd+Shift+Z, Ctrl+Y. */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { fillIn, render, settled } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  clipboard,
  editor,
  focusCell,
  isInvalid,
  press,
  pressed,
  selected,
  text,
  type
} from '../../helpers/sheet.ts';

import type { CellErrors, EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  city: string;
  hours: number | null;
  done: boolean;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name' },
  { id: 'city' },
  { id: 'hours', type: 'number' },
  { id: 'done', type: 'checkbox' }
];

const rows = (count: number): Row[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    city: `city${i}`,
    hours: i,
    done: false
  }));

const getId = (row: { id: string }) => row.id;

class State {
  @tracked readOnly = false;
}

/** `@validate`: a name of "bad" is an error. */
const validate = ({ records }: { records: readonly Row[] }): CellErrors =>
  Object.fromEntries(
    records
      .filter((row) => row.name === 'bad')
      .map((row) => [row.id, { name: 'no bad names' }])
  );

const undo = () => pressed('z', { ctrlKey: true });
const redo = () => pressed('Z', { ctrlKey: true, shiftKey: true });

module('Integration | Component | EuiSheet undo and redo', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(count = 3, state = new State()) {
    const store = localRecords<Row>(rows(count), { getRecordId: getId });
    await render(
      <template>
        <div style="width:800px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @readOnly={{state.readOnly}}
            @validate={{validate}}
          />
        </div>
      </template>
    );
    return store;
  }

  /** The owner changes one value (not through the sheet). */
  async function ownerSets(
    store: ReturnType<typeof localRecords<Row>>,
    id: string,
    values: Partial<Row>
  ) {
    store.records = store.records.map((row) =>
      row.id === id ? { ...row, ...values } : row
    );
    await settled();
  }

  test('U1 an edit: Ctrl+Z restores, Ctrl+Shift+Z and Ctrl+Y re-apply', async function (assert) {
    const store = await renderSheet();
    await focusCell(1, 0);
    await type('x');
    await fillIn(editor()!, 'xy');
    await press('Enter');
    assert.strictEqual(text(1, 0), 'xy');

    await focusCell(2, 2);
    assert.true(await undo(), 'Ctrl+Z is prevented');
    assert.strictEqual(text(1, 0), 'name1', 'restored');
    assert.deepEqual(store.log[1], {
      source: 'undo',
      patches: [{ recordId: 'r1', fieldId: 'name', from: 'xy', to: 'name1' }],
      inserts: [],
      rejected: [],
      newOptions: []
    });
    assert.strictEqual(
      document.activeElement,
      cell(1, 0),
      'focus goes to the undone cell'
    );
    assert.deepEqual(selected(), ['1:0']);

    assert.true(await redo(), 'Ctrl+Shift+Z is prevented');
    assert.strictEqual(text(1, 0), 'xy', 'Ctrl+Shift+Z re-applies');
    assert.deepEqual(store.log[2], {
      source: 'redo',
      patches: [{ recordId: 'r1', fieldId: 'name', from: 'name1', to: 'xy' }],
      inserts: [],
      rejected: [],
      newOptions: []
    });

    assert.true(await pressed('z', { metaKey: true }), 'Cmd+Z');
    assert.strictEqual(text(1, 0), 'name1', 'Cmd+Z undoes');
    assert.true(await pressed('y', { ctrlKey: true }), 'Ctrl+Y is prevented');
    assert.strictEqual(text(1, 0), 'xy', 'Ctrl+Y re-applies');
    assert.strictEqual(store.log.length, 5);

    assert.true(await redo(), 'an empty redo stack is still prevented');
    assert.strictEqual(store.log.length, 5, 'and emits nothing');
  });

  test('U2 a paste that inserted rows: undo deletes them, redo re-adds them', async function (assert) {
    const store = await renderSheet(2);
    await focusCell(1, 0);
    await clipboard('paste', 'a\tb\nc\td\ne\tf');
    assert.strictEqual(store.records.length, 4, 'two rows inserted');
    const paste = store.log[0]!;
    const tempIds = paste.inserts.map((insert) => insert.tempId);
    assert.strictEqual(tempIds.length, 2);

    await focusCell(0, 0);
    await undo();
    const undoSet = store.log[1]!;
    assert.strictEqual(undoSet.source, 'undo');
    assert.deepEqual(undoSet.deletes, tempIds, 'the inserted ids');
    assert.deepEqual(undoSet.patches, [
      { recordId: 'r1', fieldId: 'name', from: 'a', to: 'name1' },
      { recordId: 'r1', fieldId: 'city', from: 'b', to: 'city1' }
    ]);
    assert.deepEqual(
      store.records.map((row) => row.id),
      ['r0', 'r1'],
      'localRecords applied the deletes'
    );
    assert.deepEqual([text(1, 0), text(1, 1)], ['name1', 'city1']);
    assert.deepEqual(selected(), ['1:0', '1:1'], 'the restored cells');

    await redo();
    const redoSet = store.log[2]!;
    assert.strictEqual(redoSet.source, 'redo');
    assert.deepEqual(
      redoSet.inserts.map((insert) => [insert.tempId, insert.values]),
      paste.inserts.map((insert) => [insert.tempId, insert.values]),
      'the same tempIds and values'
    );
    assert.deepEqual(
      store.records.map((row) => row.id),
      ['r0', 'r1', ...tempIds]
    );
    assert.deepEqual(
      [text(2, 0), text(2, 1), text(3, 0), text(3, 1)],
      ['c', 'd', 'e', 'f']
    );
  });

  test('U3 undo skips a cell the owner changed since', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 0);
    await clipboard('paste', 'x\ty');
    await ownerSets(store, 'r0', { name: 'owner' });

    await undo();
    assert.deepEqual(
      store.log[1]!.patches,
      [{ recordId: 'r0', fieldId: 'city', from: 'y', to: 'city0' }],
      'only the cell that still holds the pasted value'
    );
    assert.deepEqual([text(0, 0), text(0, 1)], ['owner', 'city0']);

    // nothing left: no change set, but the entry still moves
    await focusCell(2, 0);
    await clipboard('paste', 'first');
    await focusCell(1, 0);
    await clipboard('paste', 'second');
    await ownerSets(store, 'r1', { name: 'owner1' });
    const count = store.log.length;
    await undo();
    assert.strictEqual(store.log.length, count, 'nothing to undo is emitted');
    await undo();
    assert.strictEqual(store.log.length, count + 1, 'the next undo goes on');
    assert.strictEqual(text(2, 0), 'name2', 'the earlier paste is undone');
  });

  test('U4 a new edit clears the redo stack; rejections are not history', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 0);
    await clipboard('paste', 'A');
    await undo();
    assert.strictEqual(text(0, 0), 'name0');

    await focusCell(1, 0);
    await clipboard('paste', 'B');
    const count = store.log.length;
    await redo();
    assert.strictEqual(store.log.length, count, 'no redo after a new edit');
    assert.strictEqual(text(0, 0), 'name0', 'A is not re-applied');

    await focusCell(0, 2);
    await clipboard('paste', 'abc');
    assert.strictEqual(store.log.at(-1)!.rejected.length, 1, 'a rejection');
    await undo();
    assert.strictEqual(
      store.log.at(-1)!.source,
      'undo',
      'Ctrl+Z undoes the last change, not the rejection'
    );
    assert.strictEqual(text(1, 0), 'name1', 'B is undone');
  });

  test('U5 the history keeps 100 entries', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 3);
    for (let i = 0; i < 101; i++) await pressed(' ');
    assert.strictEqual(store.log.length, 101, '101 toggles');
    assert.true(store.records[0]!.done);

    for (let i = 0; i < 101; i++) await undo();
    assert.strictEqual(
      store.log.length,
      201,
      '100 undos emitted, the 101st has no entry'
    );
    assert.true(
      store.records[0]!.done,
      'back to the state after the first toggle'
    );
  });

  test("U6 Ctrl+Z inside an open editor is the input's", async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 0);
    await clipboard('paste', 'A');

    await focusCell(1, 0);
    await press('Enter');
    await fillIn(editor()!, 'typed');
    assert.false(
      await pressed('z', { ctrlKey: true }),
      'not prevented: the input undoes natively'
    );
    assert.ok(editor(), 'the editor stays open');
    assert.strictEqual(store.log.length, 1, 'the sheet does not undo');
    assert.strictEqual(text(0, 0), 'A');

    await press('Escape');
    await undo();
    assert.strictEqual(text(0, 0), 'name0', 'on a cell, Ctrl+Z undoes');
  });

  test('U7 undo with focus on an inserted row keeps focus on a remaining row', async function (assert) {
    const store = await renderSheet(2);
    // no patches: the first line equals row 1, the second is inserted
    await focusCell(1, 0);
    await clipboard('paste', 'name1\tcity1\nc\td');
    assert.strictEqual(store.log[0]!.patches.length, 0, 'only an insert');
    assert.strictEqual(store.records.length, 3);
    await press('ArrowDown');
    assert.strictEqual(document.activeElement, cell(2, 0), 'on the new row');

    await undo();
    await settled();
    assert.strictEqual(store.records.length, 2, 'the row is removed');
    assert.strictEqual(
      document.activeElement,
      cell(1, 0),
      'focus on the last remaining row'
    );
    await redo();
    assert.strictEqual(store.records.length, 3, 'Ctrl+Shift+Z re-inserts');

    // with patches: the restored cells are selected
    await focusCell(0, 0);
    await clipboard('paste', 'x\ny\nz\nw');
    assert.strictEqual(store.records.length, 4);
    await press('ArrowDown');
    await press('ArrowDown');
    await press('ArrowDown');
    assert.strictEqual(document.activeElement, cell(3, 0));
    await undo();
    await settled();
    assert.strictEqual(store.records.length, 3, 'the inserted row is removed');
    assert.deepEqual(
      [text(0, 0), text(1, 0), text(2, 0)],
      ['name0', 'name1', 'c']
    );
    assert.strictEqual(document.activeElement, cell(0, 0));
    assert.deepEqual(selected(), ['0:0', '1:0', '2:0']);
  });

  test('U8 with @readOnly undo does nothing; rejections and @validate follow an undo', async function (assert) {
    const state = new State();
    const store = await renderSheet(3, state);
    await focusCell(0, 0);
    await clipboard('paste', 'bad');
    await settled();
    assert.true(isInvalid(0, 0), '@validate marks the pasted name');

    state.readOnly = true;
    await settled();
    assert.true(await undo(), 'still prevented');
    assert.strictEqual(store.log.length, 1, 'a read-only sheet does not undo');

    state.readOnly = false;
    await settled();
    await undo();
    await settled();
    assert.strictEqual(text(0, 0), 'name0', 'the entry was kept');
    assert.false(isInvalid(0, 0), '@validate ran again after the undo');

    // a rejection on a cell an undo writes is cleared
    await focusCell(0, 2);
    await clipboard('paste', '5');
    await clipboard('paste', 'abc');
    assert.true(isInvalid(0, 2), 'the rejected text');
    assert.strictEqual(text(0, 2), 'abc');
    await undo();
    assert.strictEqual(text(0, 2), '0', 'the value before the paste of 5');
    assert.false(isInvalid(0, 2), 'the rejection is gone');
  });
});
