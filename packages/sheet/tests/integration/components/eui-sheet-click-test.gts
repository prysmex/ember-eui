/** Airtable-style clicks: select, click again to edit, openers, one-click checkboxes. */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, doubleClick, render } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, editor, editorFrame, el } from '../../helpers/sheet.ts';

import type { EuiSheetField, SheetOption } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  done: boolean;
  status: string | null;
  due: string | null;
  code: string;
}

const STATUS: SheetOption[] = [
  { value: 'open', label: 'Open' },
  { value: 'closed', label: 'Closed' }
];

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name' },
  { id: 'done', type: 'checkbox' },
  { id: 'status', type: 'singleSelect', options: STATUS },
  { id: 'due', type: 'date' },
  { id: 'code', readOnly: true }
];

const ROWS = (): Row[] => [
  {
    id: 'r0',
    name: 'name0',
    done: false,
    status: 'open',
    due: null,
    code: 'C0'
  },
  {
    id: 'r1',
    name: 'name1',
    done: true,
    status: null,
    due: '2026-11-20',
    code: 'C1'
  }
];

const getId = (row: { id: string }) => row.id;

function opener(row: number, col: number): HTMLElement {
  return el('[data-test-subj=euiSheetOpener]', cell(row, col));
}

module('Integration | Component | EuiSheet clicks', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet() {
    const store = localRecords<Row>(ROWS(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:800px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('K1 the first click selects, a click on the selected cell edits', async function (assert) {
    await renderSheet();
    await click(cell(0, 0));
    assert.strictEqual(document.activeElement, cell(0, 0), 'selected');
    assert.strictEqual(editorFrame(), null, 'not editing yet');

    await click(cell(0, 0));
    assert.ok(editorFrame(), 'the second click edits');
    assert.strictEqual(editor()?.value, 'name0', 'with the current value');

    await click(cell(1, 0));
    assert.strictEqual(editorFrame(), null, 'another cell commits and selects');
    assert.strictEqual(document.activeElement, cell(1, 0));
  });

  test('K2 a checkbox toggles on one click anywhere in its cell', async function (assert) {
    const store = await renderSheet();
    await click(cell(0, 1));
    assert.true(store.records[0]!.done, 'a click on the cell toggles');
    await click(el('[data-test-subj=euiSheetCheckbox]', cell(0, 1)));
    assert.false(store.records[0]!.done, 'a click on the box toggles once');
    assert.strictEqual(store.log.length, 2, 'one change set per click');
    assert.strictEqual(editorFrame(), null, 'no editor');
  });

  test('K3 the select and date openers open the editor in one click', async function (assert) {
    await renderSheet();
    await click(opener(0, 2));
    assert.ok(editorFrame(), 'the select editor is open');
    assert.dom('[role=option]').exists({ count: 2 }, 'with its options');

    await click(cell(1, 0));
    assert.strictEqual(editorFrame(), null);

    await click(opener(1, 3));
    assert.ok(editorFrame(), 'the date editor is open');
    assert.dom(editor()).hasAttribute('type', 'date');
  });

  test('K4 openers only on editable cells; Shift+click and double-click', async function (assert) {
    await renderSheet();
    assert
      .dom('[data-test-subj=euiSheetOpener]', cell(0, 0))
      .doesNotExist('text cells have no opener');
    assert
      .dom('[data-test-subj=euiSheetOpener]', cell(0, 4))
      .doesNotExist('a read-only cell has none');

    await click(cell(0, 4));
    await click(cell(0, 4));
    assert.strictEqual(editorFrame(), null, 'a read-only cell does not edit');

    await click(cell(1, 0));
    await click(cell(1, 0), { shiftKey: true });
    assert.strictEqual(editorFrame(), null, 'Shift+click does not edit');

    await doubleClick(cell(0, 0));
    assert.strictEqual(
      document.querySelectorAll('[data-test-subj=euiSheetEditor]').length,
      1,
      'a double-click opens one editor'
    );
    assert.strictEqual(editor()?.value, 'name0');
  });
});
