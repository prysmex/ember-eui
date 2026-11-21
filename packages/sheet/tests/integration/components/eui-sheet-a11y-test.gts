/**
 * Accessibility attributes (READINESS.md item 3): what a screen reader is
 * told about a cell, a row number, the row-number header, a checkbox and a
 * rating, and the expanded record's boxes.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { fillIn, render, settled, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  clipboard,
  editor,
  el,
  focusCell,
  press,
  pressed,
  text,
  type
} from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { SheetApi } from '#src/index.ts';

interface Item {
  id: string;
  name: string;
  code: string;
  done: boolean;
  stars: number | null;
}

const FIELDS: EuiSheetField<Item>[] = [
  { id: 'name', label: 'Name' },
  { id: 'code', label: 'Code', readOnly: true },
  { id: 'done', label: 'Done', type: 'checkbox' },
  { id: 'stars', label: 'Stars', type: 'rating' }
];

const ITEMS = (): Item[] => [
  { id: 'a', name: 'Gloves', code: 'G1', done: true, stars: 3 },
  { id: 'b', name: 'Masks', code: 'M1', done: false, stars: null }
];

const getId = (item: { id: string }) => item.id;

module('Integration | Component | EuiSheet accessibility', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(
    options: { readOnly?: boolean; messages?: Record<string, unknown> } = {}
  ) {
    const store = localRecords<Item>(ITEMS(), { getRecordId: getId });
    const { readOnly, messages } = options;
    await render(
      <template>
        <div style="width:700px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @readOnly={{readOnly}}
            @messages={{messages}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('A1 a read-only cell has aria-readonly; an editable one has none; @readOnly marks every cell', async function (assert) {
    await renderSheet();
    assert
      .dom(cell(0, 1))
      .hasAttribute('aria-readonly', 'true', 'readOnly field');
    assert.dom(cell(0, 0)).doesNotHaveAttribute('aria-readonly', 'editable');
    assert.dom(cell(1, 2)).doesNotHaveAttribute('aria-readonly', 'checkbox');

    await renderSheet({ readOnly: true });
    for (const col of [0, 1, 2, 3]) {
      assert
        .dom(cell(0, col))
        .hasAttribute('aria-readonly', 'true', `col ${col}`);
    }
  });

  test('A2 a checked row says so in its row number; the row-number header has a name', async function (assert) {
    await renderSheet();
    const rowCell = cell(1, -1);
    assert.dom(rowCell).hasAttribute('aria-label', 'Row 2');
    await focusCell(1, -1);
    await pressed(' ');
    assert.dom(cell(1, -1)).hasAttribute('aria-label', 'Row 2, checked');
    await pressed(' ');
    assert.dom(cell(1, -1)).hasAttribute('aria-label', 'Row 2', 'unchecked');

    const header = el(
      '[role=columnheader][data-gridcell-column-id=euiSheetRow]'
    );
    assert.strictEqual(
      header.querySelector('.euiSheet__srOnly')?.textContent?.trim(),
      'Row number',
      'the header has text for screen readers'
    );
  });

  test('A3 a checkbox cell is labelled checked or not, in the messages; an empty rating is no empty image', async function (assert) {
    await renderSheet();
    const box = (row: number) =>
      el('[data-test-subj=euiSheetCheckbox]', cell(row, 2));
    assert.dom(box(0)).hasAttribute('role', 'img');
    assert.dom(box(0)).hasAttribute('aria-label', 'Checked');
    assert.dom(box(1)).hasAttribute('aria-label', 'Not checked');

    const rating = (row: number) =>
      el('[data-test-subj=euiSheetRating]', cell(row, 3));
    assert.dom(rating(0)).hasAttribute('role', 'img');
    assert.dom(rating(0)).hasAttribute('aria-label', '3');
    assert.dom(rating(1)).doesNotHaveAttribute('role', 'no value: no image');
    assert.dom(rating(1)).doesNotHaveAttribute('aria-label');

    await renderSheet({
      messages: { cellChecked: () => 'Sí', cellUnchecked: () => 'No' }
    });
    assert.dom(box(0)).hasAttribute('aria-label', 'Sí', '@messages');
    assert.dom(box(1)).hasAttribute('aria-label', 'No');
  });

  test('A4 the expanded record: a box is named by its label and its value', async function (assert) {
    await renderSheet();
    await focusCell(0, 0);
    await pressed(' ');
    await waitUntil(() =>
      document.querySelector('[data-test-subj=euiSheetRecord]')
    );
    const box = (id: string) =>
      el(
        `[data-test-subj="euiSheetRecordField-${id}"] [data-test-subj=euiSheetRecordBox]`
      );
    const label = (id: string) =>
      el(`[data-test-subj="euiSheetRecordField-${id}"] .euiSheetRecord__label`);
    const name = box('name');
    assert.dom(name).hasAttribute('role', 'button');
    assert.deepEqual(
      name.getAttribute('aria-labelledby')?.split(' '),
      [label('name').id, name.id],
      'the label, then the box itself (its value)'
    );
    assert.ok(name.id, 'the box has an id');
    assert
      .dom(el('[data-test-subj=euiSheetCheckbox]', box('done')))
      .hasAttribute('aria-label', 'Checked', 'a cell component in the form');
  });

  test('A5 a polite live region announces a paste, an undo, a redo, a text not stored and an edit left invalid', async function (assert) {
    const fields: EuiSheetField<Item>[] = [
      { id: 'name', label: 'Name', required: true },
      { id: 'code', label: 'Code' },
      { id: 'stars', label: 'Stars', type: 'number' }
    ];
    const store = localRecords<Item>(ITEMS(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:700px">
          <EuiSheet
            @records={{store.records}}
            @fields={{fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </div>
      </template>
    );
    const region = el('[data-test-subj=euiSheetAnnouncer]');
    const said = () => region.textContent!.replace(/\u00a0/g, '').trim();
    assert.dom(region).hasAttribute('role', 'status');
    assert.strictEqual(said(), '', 'quiet at first');

    await focusCell(0, 0);
    await clipboard('paste', 'a\tb\nc\td');
    assert.strictEqual(said(), '4 cells pasted');
    await focusCell(1, 1);
    await clipboard('paste', 'x');
    assert.strictEqual(said(), '1 cell pasted');

    await pressed('z', { ctrlKey: true });
    assert.strictEqual(said(), 'Undone');
    const first = region.textContent;
    await pressed('z', { ctrlKey: true });
    assert.strictEqual(said(), 'Undone', 'a second undo');
    assert.notStrictEqual(
      region.textContent,
      first,
      'a new text for the region'
    );
    await pressed('Z', { ctrlKey: true, shiftKey: true });
    assert.strictEqual(said(), 'Redone');

    await focusCell(0, 2);
    await type('a');
    await fillIn(editor()!, 'abc');
    await press('Enter');
    assert.strictEqual(said(), '"abc" is not a number', 'the rejection');
    await focusCell(0, 0);
    await clipboard('paste', 'p\tq\tr\ns\tt\tu');
    assert.strictEqual(
      said(),
      '4 cells pasted. 2 values could not be read',
      'a paste with two rejections'
    );

    // Enter moves down: the edited cell's error is announced
    await focusCell(0, 0);
    await type('x');
    await fillIn(editor()!, '');
    await press('Enter');
    assert.strictEqual(text(0, 0), '', 'cleared');
    assert.strictEqual(said(), 'Name: Required', 'focus moved on: the error');
    // on the last record Enter stays: the cell's own error box says it
    const before = region.textContent;
    await focusCell(1, 0);
    await type('x');
    await fillIn(editor()!, '');
    await press('Enter');
    assert.strictEqual(region.textContent, before, 'not announced again');
    assert
      .dom('[data-test-subj=euiSheetCellError]')
      .hasText('Required', 'the focused cell shows it, in its own live region');
  });

  test('A6 the announcements go through @messages', async function (assert) {
    await renderSheet({
      messages: {
        announcePastedOne: (n: number) => `${n} celda pegada`,
        announceUndone: () => 'Deshecho'
      }
    });
    const region = el('[data-test-subj=euiSheetAnnouncer]');
    await focusCell(0, 0);
    await clipboard('paste', 'a');
    const said = () => region.textContent!.replace(/\u00a0/g, '').trim();
    assert.strictEqual(said(), '1 celda pegada');
    await pressed('z', { ctrlKey: true });
    assert.strictEqual(said(), 'Deshecho');
  });

  test('A7 a paste past the last record counts its own cells, not @newRecordValues; appendRows announces no paste', async function (assert) {
    const store = localRecords<Item>(ITEMS(), { getRecordId: getId });
    const state: { api: SheetApi | null } = { api: null };
    const register = (api: SheetApi) => (state.api = api);
    const newValues = () => ({ code: 'NEW', done: false });
    await render(
      <template>
        <div style="width:700px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @newRecordValues={{newValues}}
            @registerApi={{register}}
          />
        </div>
      </template>
    );
    const region = el('[data-test-subj=euiSheetAnnouncer]');
    const said = () => region.textContent!.replace(/\u00a0/g, '').trim();
    await focusCell(1, 0);
    await clipboard('paste', 'a\nb\nc');
    assert.strictEqual(store.records.length, 4, 'two new records');
    assert.strictEqual(store.records[3]!.code, 'NEW', 'with @newRecordValues');
    assert.strictEqual(said(), '3 cells pasted', 'the three pasted cells');
    const before = region.textContent;
    state.api!.appendRows([['d'], ['e']], ['name']);
    await settled();
    assert.strictEqual(store.records.length, 6, 'appended');
    assert.strictEqual(region.textContent, before, 'not announced as a paste');
  });
});
