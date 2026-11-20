/**
 * The selection, exposed (V03 11.2, SL1-SL3, SL5): the block's
 * `selection`, `api.getSelection()` and `@onSelectionChange`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, render, settled, triggerEvent } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, el, focusCell, press } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { SheetApi, SheetSelection } from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  qty: number | null;
  city: string;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'qty', label: 'Qty', type: 'number' },
  { id: 'city', label: 'City' }
];

const rowsOf = (count = 4): Row[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    qty: i,
    city: i % 2 ? 'Lima' : 'Madrid'
  }));

const getId = (row: { id: string }) => row.id;

/** A selection as one line: kind, record ids, field ids, cell count. */
function describe(selection: SheetSelection | null | undefined): string {
  if (!selection) return 'none';
  return [
    selection.kind,
    selection.recordIds.join(','),
    selection.fields.map((field) => field.id).join(','),
    selection.cellCount
  ].join(' ');
}

class State {
  @tracked records: Row[] = rowsOf();
  api: SheetApi | null = null;
  calls: string[] = [];
  register = (api: SheetApi) => (this.api = api);
  onChange = () => {};
  onSelectionChange = (selection: SheetSelection<Row> | null) => {
    this.calls.push(describe(selection));
    // the records are the selection's, in the order shown
    if (selection) {
      const ids = selection.records.map((record) => record.id);
      if (ids.join(',') !== selection.recordIds.join(',')) {
        this.calls.push('records out of step');
      }
    }
  };
}

function rowCell(row: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
  );
}

function header(col: number): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-index="${col + 1}"]`);
}

const shown = () => el('[data-test-selection]').textContent?.trim();

module('Integration | Component | EuiSheet selection', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state: State): Promise<void> {
    await render(
      <template>
        <EuiSheet
          @fields={{FIELDS}}
          @records={{state.records}}
          @getRecordId={{getId}}
          @onChange={{state.onChange}}
          @onSelectionChange={{state.onSelectionChange}}
          @registerApi={{state.register}}
        >
          <:footer as |sheet|>
            <span data-test-selection>{{describe sheet.selection}}</span>
          </:footer>
        </EuiSheet>
      </template>
    );
  }

  test('SL1 the block’s selection: a cell, a rectangle, rows, columns', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert.strictEqual(shown(), 'none', 'no range');
    await focusCell(1, 1);
    assert.strictEqual(shown(), 'cells r1 qty 1', 'a focused cell');
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowRight', { shiftKey: true });
    assert.strictEqual(shown(), 'cells r1,r2 qty,city 4', 'a rectangle');
    await click(rowCell(2));
    await click(rowCell(3), { shiftKey: true });
    assert.strictEqual(shown(), 'rows r2,r3 name,qty,city 6', 'rows');
    await click(el('.euiDataGridHeaderCell__content', header(0)));
    assert.strictEqual(shown(), 'columns r0,r1,r2,r3 name 4', 'a column');
    // the add row is no record: a selection of nothing
    await focusCell(4, 0);
    assert.strictEqual(shown(), 'none', 'the add row');
  });

  test('SL2 @onSelectionChange: once per change, null when gone, not on a re-render', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert.deepEqual(state.calls, [], 'nothing on the first render');
    await focusCell(0, 0);
    assert.deepEqual(state.calls, ['cells r0 name 1']);
    // a drag reports each new rectangle once
    await triggerEvent(cell(0, 0), 'mousedown', { button: 0 });
    await triggerEvent(cell(1, 1), 'mouseover');
    await triggerEvent(cell(1, 1), 'mouseover');
    await triggerEvent(cell(2, 1), 'mouseover');
    await triggerEvent(cell(2, 1), 'mouseup', { button: 0 });
    assert.deepEqual(state.calls.slice(1), [
      'cells r0,r1 name,qty 4',
      'cells r0,r1,r2 name,qty 6'
    ]);
    state.calls = [];
    // new record objects with the same ids: no call
    state.records = state.records.map((record) => ({ ...record }));
    await settled();
    assert.deepEqual(state.calls, [], 'a re-render without a change');
    // several changes in one run loop: one call, with the last
    state.api!.focusCell({ recordId: 'r3', fieldId: 'city' });
    state.api!.focusCell({ recordId: 'r2', fieldId: 'name' });
    await settled();
    assert.deepEqual(state.calls, ['cells r2 name 1'], 'one call');
    // the range gone: on the add row
    await focusCell(4, 0);
    assert.deepEqual(state.calls.slice(1), ['none'], 'null');
    // a change of kind with the same cells is a change
    state.calls = [];
    state.records = rowsOf(1);
    await settled();
    await focusCell(0, 0);
    await click(el('.euiDataGridHeaderCell__content', header(0)));
    assert.deepEqual(state.calls, ['cells r0 name 1', 'columns r0 name 1']);
  });

  test('SL3 with groups, a range across a header lists the records on both sides only', async function (assert) {
    const store = localRecords<Row>(rowsOf(4), {
      getRecordId: getId,
      fields: FIELDS,
      groupBy: [{ field: 'city', direction: 'asc' }]
    });
    const state = new State();
    await render(
      <template>
        <EuiSheet
          @fields={{store.fields}}
          @records={{store.view.records}}
          @groups={{store.view.groups}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @onSelectionChange={{state.onSelectionChange}}
          @registerApi={{state.register}}
        />
      </template>
    );
    // header Lima (0), r1 (1), r3 (2), add row (3), header Madrid (4), r0 (5), r2 (6), add row (7)
    await triggerEvent(cell(2, 0), 'mousedown', { button: 0 });
    await triggerEvent(cell(5, 1), 'mouseover');
    await triggerEvent(cell(5, 1), 'mouseup', { button: 0 });
    const selection = state.api!.getSelection()!;
    assert.strictEqual(selection.kind, 'cells');
    assert.deepEqual(
      selection.recordIds,
      ['r3', 'r0'],
      'no header, no add row'
    );
    assert.deepEqual(
      selection.records.map((record) => record.name),
      ['name3', 'name0']
    );
    assert.strictEqual(selection.cellCount, 4);
    assert.deepEqual(
      state.calls[state.calls.length - 1],
      'cells r3,r0 name,qty 4'
    );
  });

  test('SL5 api.getSelection()', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert.strictEqual(state.api!.getSelection(), null, 'none yet');
    await focusCell(2, 2);
    await press('ArrowUp', { shiftKey: true });
    const selection = state.api!.getSelection()!;
    assert.strictEqual(describe(selection), 'cells r1,r2 city 2');
    assert.deepEqual(
      selection.records.map((record) => record.city),
      ['Lima', 'Madrid']
    );
    assert.strictEqual(
      state.api!.getSelection(),
      selection,
      'the same object while nothing changed'
    );
    // checked rows stay separate (checkedRecords)
    await click(el('[data-eui-sheet-row-check]', rowCell(0)));
    assert.strictEqual(
      describe(state.api!.getSelection()),
      'cells r1,r2 city 2'
    );
  });
});
