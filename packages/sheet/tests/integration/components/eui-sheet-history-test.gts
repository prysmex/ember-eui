/** Undo and redo: Ctrl/Cmd+Z, Ctrl/Cmd+Shift+Z, Ctrl+Y. */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  fillIn,
  render,
  settled,
  triggerEvent
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  clipboard,
  editor,
  el,
  focusCell,
  isInvalid,
  press,
  pressed,
  selected,
  text,
  type
} from '../../helpers/sheet.ts';

import type { CellErrors, EuiSheetField } from '#src/core/index.ts';
import type { SheetApi } from '#src/types.ts';

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
  api: SheetApi | null = null;
  register = (api: SheetApi) => (this.api = api);
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
            @registerApi={{state.register}}
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

  test('U4 a new edit clears the redo stack; a rejection is its own entry', async function (assert) {
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

    // batch 2: a rejection is history, so the first Ctrl+Z clears it
    // (and emits nothing), the second undoes B
    await focusCell(0, 2);
    await clipboard('paste', 'abc');
    assert.strictEqual(store.log.at(-1)!.rejected.length, 1, 'a rejection');
    const afterReject = store.log.length;
    await undo();
    assert.strictEqual(store.log.length, afterReject, 'nothing emitted');
    assert.false(isInvalid(0, 2), 'the rejection is undone');
    assert.strictEqual(text(1, 0), 'B', 'B is still there');
    await undo();
    assert.strictEqual(store.log.at(-1)!.source, 'undo');
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
    // batch 2: the rejected paste is the last entry: its undo clears it
    await undo();
    assert.strictEqual(text(0, 2), '5', 'the value before the rejected paste');
    assert.false(isInvalid(0, 2), 'the rejection is gone');
    await undo();
    assert.strictEqual(text(0, 2), '0', 'the value before the paste of 5');
    assert.false(isInvalid(0, 2));
  });

  test('U11 a paste with rejected cells: undo removes all of it, redo brings it back', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 1);
    await clipboard('paste', 'c\tabc\nd\t7');
    assert.deepEqual(
      [text(0, 1), text(0, 2), text(1, 1), text(1, 2)],
      ['c', 'abc', 'd', '7']
    );
    assert.true(isInvalid(0, 2), 'abc is rejected');

    await focusCell(2, 0);
    await undo();
    assert.deepEqual(
      [text(0, 1), text(0, 2), text(1, 1), text(1, 2)],
      ['city0', '0', 'city1', '1'],
      'the rejected cell shows its value again'
    );
    assert.false(isInvalid(0, 2), 'no red');
    assert.deepEqual(
      store.log.at(-1)!.rejected,
      [],
      'the owner gets no rejections'
    );
    assert.deepEqual(
      selected(),
      ['0:1', '0:2', '1:1', '1:2'],
      'the whole paste'
    );

    await redo();
    assert.deepEqual(
      [text(0, 1), text(0, 2), text(1, 1), text(1, 2)],
      ['c', 'abc', 'd', '7'],
      'the rejected text again'
    );
    assert.true(isInvalid(0, 2));
    assert.deepEqual(store.log.at(-1)!.rejected, []);
  });

  test('U12 a paste whose every cell is rejected: Ctrl+Z clears it, Ctrl+Shift+Z brings it back', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 2);
    await clipboard('paste', 'abc\nxyz');
    assert.strictEqual(store.log.length, 1);
    assert.deepEqual([text(0, 2), text(1, 2)], ['abc', 'xyz']);

    await focusCell(2, 0);
    assert.true(await undo(), 'prevented');
    assert.strictEqual(store.log.length, 1, 'nothing emitted: no data changed');
    assert.deepEqual([text(0, 2), text(1, 2)], ['0', '1']);
    assert.false(isInvalid(0, 2) || isInvalid(1, 2), 'no red');
    assert.deepEqual(selected(), ['0:2', '1:2'], 'the cells are selected');
    assert.strictEqual(document.activeElement, cell(0, 2), 'and focused');

    await focusCell(2, 0);
    await redo();
    assert.strictEqual(store.log.length, 1);
    assert.deepEqual([text(0, 2), text(1, 2)], ['abc', 'xyz']);
    assert.true(isInvalid(0, 2) && isInvalid(1, 2));
    assert.strictEqual(document.activeElement, cell(0, 2));

    // an owner change since: the redo does not put the text back there
    await undo();
    await ownerSets(store, 'r0', { hours: 9 });
    await redo();
    assert.deepEqual([text(0, 2), text(1, 2)], ['9', 'xyz']);
    assert.false(isInvalid(0, 2));
  });

  test('U13 each rejection is undone by its own entry, last first', async function (assert) {
    // The nearest sequence the UI allows to "a later rejection on the same
    // cell survives undoing the paste": a later rejection is a later entry,
    // so it is always undone first. The guard itself (only a rejection with
    // the entry's text and message is cleared) is unit test RJ1.
    const store = await renderSheet();
    await focusCell(0, 1);
    await clipboard('paste', 'c\tabc');
    await focusCell(0, 2);
    await type('x');
    await fillIn(editor()!, 'xyz');
    await press('Enter');
    assert.strictEqual(text(0, 2), 'xyz', 'the later rejection');

    await undo();
    assert.strictEqual(text(0, 2), '0', 'its undo clears it');
    assert.strictEqual(text(0, 1), 'c', 'the paste is still there');
    await undo();
    assert.deepEqual([text(0, 1), text(0, 2)], ['city0', '0']);
    assert.false(isInvalid(0, 2));
    await redo();
    assert.deepEqual([text(0, 1), text(0, 2)], ['c', 'abc'], 'the paste again');
    await redo();
    assert.strictEqual(text(0, 2), 'xyz', 'then the later rejection');
    assert.strictEqual(
      store.log.filter((set) => set.source === 'redo').length,
      1
    );
  });

  test('U14 rejected cells on rows the paste inserted go with the rows', async function (assert) {
    const store = await renderSheet(2);
    await focusCell(1, 2);
    await clipboard('paste', '5\nabc\n6');
    assert.strictEqual(store.records.length, 4, 'two rows inserted');
    const tempId = store.log[0]!.inserts[0]!.tempId;
    assert.deepEqual(
      store.log[0]!.rejected.map((r) => r.tempId),
      [tempId]
    );
    assert.strictEqual(text(2, 2), 'abc');
    assert.true(isInvalid(2, 2));

    await focusCell(0, 0);
    await undo();
    assert.strictEqual(store.records.length, 2, 'the rows are removed');
    assert.strictEqual(text(1, 2), '1');

    await redo();
    assert.strictEqual(store.records.length, 4, 'the rows are back');
    assert.strictEqual(store.records[2]!.id, tempId);
    assert.strictEqual(text(2, 2), 'abc', 'with the rejected text');
    assert.true(isInvalid(2, 2));
    assert.strictEqual(text(3, 2), '6');
  });
  test('U9 an insert: undo removes the row, redo puts it back', async function (assert) {
    const store = await renderSheet(3);
    await focusCell(0, 0);
    await pressed('Enter', { shiftKey: true });
    const insert = store.log[0]!;
    const tempId = insert.inserts[0]!.tempId;
    assert.deepEqual(
      store.records.map((row) => row.id),
      ['r0', tempId, 'r1', 'r2']
    );
    await undo();
    assert.deepEqual(store.log[1]!.deletes, [tempId]);
    assert.deepEqual(
      store.records.map((row) => row.id),
      ['r0', 'r1', 'r2']
    );
    await redo();
    assert.strictEqual(store.log[2]!.source, 'redo');
    assert.deepEqual(
      store.records.map((row) => row.id),
      ['r0', tempId, 'r1', 'r2'],
      'at its position again'
    );
  });

  test('U10 a delete of 3 rows in the middle: undo keeps their order', async function (assert) {
    const store = await renderSheet(6);
    const before = [...store.records];
    const rowCell = (row: number) =>
      el(
        `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
      );
    await click(rowCell(1));
    await click(rowCell(3), { shiftKey: true });
    await triggerEvent(rowCell(2), 'contextmenu');
    await click(el('[data-test-subj=euiSheetRowMenu-delete]'));
    assert.deepEqual(
      store.records.map((row) => row.id),
      ['r0', 'r4', 'r5']
    );
    await undo();
    assert.deepEqual(
      store.records.map((row) => row.id),
      ['r0', 'r1', 'r2', 'r3', 'r4', 'r5'],
      'in their order'
    );
    assert.true(
      store.records.every((row, i) => row === before[i]),
      'the same objects'
    );
    await redo();
    assert.deepEqual(
      store.records.map((row) => row.id),
      ['r0', 'r4', 'r5']
    );
  });
  test('U15 remapIds keeps the rejected cells of inserted rows in the history', async function (assert) {
    const state = new State();
    const store = await renderSheet(2, state);
    await focusCell(1, 2);
    await clipboard('paste', '5\nabc');
    const tempId = store.log[0]!.inserts[0]!.tempId;
    assert.strictEqual(text(2, 2), 'abc');

    // the owner's server gives the row another id
    state.api!.remapIds({ [tempId]: 'srv-1' });
    store.records = store.records.map((row) =>
      row.id === tempId ? { ...row, id: 'srv-1' } : row
    );
    await settled();
    assert.strictEqual(text(2, 2), 'abc', 'the rejection follows the new id');
    assert.true(isInvalid(2, 2));

    await focusCell(0, 0);
    await undo();
    assert.deepEqual(store.log.at(-1)!.deletes, ['srv-1'], 'the remapped id');
    assert.strictEqual(store.records.length, 2);
    await redo();
    assert.strictEqual(store.records[2]!.id, 'srv-1');
    assert.strictEqual(text(2, 2), 'abc', 'the rejected text is back');
    assert.true(isInvalid(2, 2));
  });
});
