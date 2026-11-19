/** The focused cell's error box (shown next to the cell, not only on hover). */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { blur, render } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  clipboard,
  editorFrame,
  el,
  focusCell,
  press
} from '../../helpers/sheet.ts';

import type { CellErrors, EuiSheetField } from '#src/core/index.ts';

interface Item {
  id: string;
  name: string;
  qty: number | null;
}

const FIELDS: EuiSheetField<Item>[] = [
  { id: 'name', required: true },
  { id: 'qty', type: 'number', max: 10 }
];

const ITEMS = (): Item[] => [
  { id: 'a', name: 'Gloves', qty: 3 },
  { id: 'b', name: '', qty: 20 },
  { id: 'c', name: 'Masks', qty: 1 }
];

const getId = (item: { id: string }) => item.id;

function errorBox(): HTMLElement | null {
  return document.querySelector<HTMLElement>(
    '[data-test-subj=euiSheetCellError]'
  );
}

function errorText(): string | null {
  return errorBox()?.textContent?.replace(/\s+/g, ' ').trim() ?? null;
}

module('Integration | Component | EuiSheet cell error', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(
    options: {
      cellErrors?: CellErrors;
      messages?: Record<string, unknown>;
    } = {}
  ) {
    const store = localRecords<Item>(ITEMS(), { getRecordId: getId });
    const { cellErrors, messages } = options;
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @cellErrors={{cellErrors}}
            @messages={{messages}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('E1 an invalid focused cell shows its errors next to it', async function (assert) {
    await renderSheet();
    assert.strictEqual(errorBox(), null, 'nothing before focus');

    await focusCell(1, 0);
    assert.strictEqual(errorText(), 'Required');
    const box = errorBox()!.getBoundingClientRect();
    const target = cell(1, 0).getBoundingClientRect();
    assert.true(box.top >= target.bottom - 1, 'the box is below the cell');
    assert.true(
      Math.abs(box.left - target.left) <= 1,
      'and starts at its left edge'
    );
    assert
      .dom('[role=status]', el('[data-test-subj=euiSheet]'))
      .includesText('Required', 'inside the live region');

    await focusCell(0, 0);
    assert.strictEqual(errorBox(), null, 'a valid cell shows none');

    await focusCell(1, 1);
    assert.strictEqual(errorText(), 'Must be 10 or less');
  });

  test('E2 hidden while editing, back after Escape, gone when focus leaves', async function (assert) {
    await renderSheet();
    await focusCell(1, 0);
    assert.ok(errorBox(), 'shown');

    await press('Enter');
    assert.ok(editorFrame(), 'editing');
    assert.strictEqual(errorBox(), null, 'hidden while editing');

    await press('Escape');
    assert.strictEqual(errorText(), 'Required', 'back on the cell');

    await blur(cell(1, 0));
    assert.strictEqual(errorBox(), null, 'gone when focus leaves the grid');
  });

  test('E3 rejections, owner errors and @messages', async function (assert) {
    await renderSheet({
      cellErrors: { a: { name: 'Already in the catalog' } },
      messages: { required: () => 'Falta este dato' }
    });
    await focusCell(0, 0);
    assert.strictEqual(errorText(), 'Already in the catalog', '@cellErrors');

    await focusCell(1, 0);
    assert.strictEqual(errorText(), 'Falta este dato', '@messages');

    await focusCell(2, 1);
    await clipboard('paste', 'abc');
    assert.strictEqual(
      errorText(),
      '"abc" is not a number',
      'a rejected paste'
    );
  });
});
