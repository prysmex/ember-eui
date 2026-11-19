/**
 * The summary bar (V02-DESIGN.md 6.6): the owner's `@summary` texts in the
 * grid's footer row. The sheet computes nothing.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, render, settled } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  clipboard,
  editorFrame,
  el,
  focusCell,
  pressed,
  selected,
  text
} from '../../helpers/sheet.ts';

import type { ChangeSet, EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  qty: number | null;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name' },
  { id: 'qty', type: 'number' }
];

const getId = (row: Row) => row.id;

class State {
  @tracked summary: Record<string, string> | undefined = undefined;
  store = localRecords(
    [
      { id: 'a', name: 'Ana', qty: 3 },
      { id: 'b', name: 'Beto', qty: 1 }
    ],
    { getRecordId: getId }
  );
  changes: ChangeSet[] = [];
  onChange = (changeSet: ChangeSet) => {
    this.changes.push(changeSet);
    this.store.apply(changeSet);
  };
}

function footer(fieldId: string): HTMLElement {
  return el(
    `.euiDataGridFooterCell[data-gridcell-column-id="${fieldId}"] [data-test-subj=euiSheetSummary]`
  );
}

module('Integration | Component | EuiSheet summary bar', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state: State): Promise<void> {
    await render(
      <template>
        <div style="width:500px">
          <EuiSheet
            @fields={{FIELDS}}
            @records={{state.store.records}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @summary={{state.summary}}
          />
        </div>
      </template>
    );
  }

  test('SU1 @summary shows a footer with the texts under their fields', async function (assert) {
    const state = new State();
    state.summary = { '': '2 records', qty: 'Sum 4' };
    await renderSheet(state);
    assert.dom('[data-test-subj~=dataGridFooterRow]').exists();
    assert.dom(footer('qty')).hasText('Sum 4');
    assert.dom(footer('name')).hasText('', 'a field without a text');
    assert.dom(footer('euiSheetRow')).hasText('2 records', "@summary['']");
  });

  test('SU2 no @summary, no footer; {} shows an empty one', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert.dom('.euiDataGridFooterCell').doesNotExist();
    state.summary = {};
    await settled();
    assert.dom('.euiDataGridFooterCell').exists({ count: 3 });
  });

  test('SU3 footer cells take no edits and no range', async function (assert) {
    const state = new State();
    state.summary = { qty: 'Sum 4' };
    await renderSheet(state);
    await focusCell(0, 1);
    const footerCell = el(
      '.euiDataGridFooterCell[data-gridcell-column-id="qty"]'
    );
    await click(footerCell);
    assert.deepEqual(selected(), ['0:1'], 'a click does not select it');
    footerCell.focus();
    await settled();
    assert.false(await pressed('x'), 'typing is not the sheet’s');
    assert.strictEqual(editorFrame(), null, 'no editor');
    assert.false(await pressed('Delete'), 'Delete is not the sheet’s');
    const paste = await clipboard('paste', '9', footerCell);
    assert.false(paste.prevented, 'a paste is not the sheet’s');
    assert.strictEqual(state.changes.length, 0, 'no change set');
    assert.strictEqual(text(0, 1), '3');
  });

  test('SU4 the owner updates the object: the cells update', async function (assert) {
    const state = new State();
    state.summary = { qty: 'Sum 4' };
    await renderSheet(state);
    state.summary = { qty: 'Sum 9', name: '2 names' };
    await settled();
    assert.dom(footer('qty')).hasText('Sum 9');
    assert.dom(footer('name')).hasText('2 names');
  });
});
