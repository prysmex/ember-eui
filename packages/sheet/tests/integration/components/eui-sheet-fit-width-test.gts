/**
 * Fit a column to its content (v0.4 01, FW1-FW7): the header menu's
 * "Fit to content", a double-click on the resize edge and
 * `api.fitField` / `api.fitFields`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { cell, el, resizerOf } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { SheetApi } from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  notes: string;
  status: string | null;
  done: boolean;
}

const NAME: EuiSheetField<Row> = { id: 'name', label: 'Name', width: 100 };
const NOTES: EuiSheetField<Row> = { id: 'notes', label: 'Notes', width: 100 };
const STATUS: EuiSheetField<Row> = {
  id: 'status',
  label: 'Status',
  type: 'singleSelect',
  width: 90,
  options: [
    { value: 'p', label: 'In progress, waiting for review' },
    { value: 'd', label: 'Done' }
  ]
};
const DONE: EuiSheetField<Row> = {
  id: 'done',
  label: 'Completed by the team',
  type: 'checkbox',
  width: 100
};

const LONG = 'A much longer note that does not fit in a hundred pixels';

const rows = (): Row[] => [
  { id: 'a', name: 'Ana', notes: 'short', status: 'd', done: true },
  { id: 'b', name: 'Beto', notes: LONG, status: 'p', done: false },
  { id: 'c', name: 'Caro', notes: 'mid sized note', status: null, done: false }
];

const getId = (row: Row) => row.id;

class State {
  @tracked fields: EuiSheetField<Row>[] = [NAME, NOTES, STATUS, DONE];
  @tracked records: Row[] = rows();
  @tracked fieldWidths: Record<string, number> | undefined = undefined;
  onFieldWidthChange: ((id: string, width: number) => void) | undefined =
    undefined;
  api: SheetApi | null = null;
  onChange = () => {};
  registerApi = (api: SheetApi) => (this.api = api);
}

async function renderSheet(state: State): Promise<void> {
  await render(
    <template>
      <div style="width: 1200px">
        <EuiSheet
          @fields={{state.fields}}
          @records={{state.records}}
          @getRecordId={{getId}}
          @onChange={{state.onChange}}
          @fieldWidths={{state.fieldWidths}}
          @onFieldWidthChange={{state.onFieldWidthChange}}
          @registerApi={{state.registerApi}}
          @height={{300}}
        />
      </div>
    </template>
  );
}

function header(fieldId: string): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-id="${fieldId}"]`);
}

const widthOf = (fieldId: string) => parseFloat(header(fieldId).style.width);

async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

async function openMenu(fieldId: string): Promise<void> {
  await click(el(`[data-test-subj=dataGridHeaderCellActionButton-${fieldId}]`));
  await waitUntil(() =>
    document.querySelector(
      `[data-test-subj=dataGridHeaderCellActionGroup-${fieldId}]`
    )
  );
}

async function fitFromMenu(fieldId: string): Promise<void> {
  await openMenu(fieldId);
  await click(el(`[data-test-subj=euiSheetFitField-${fieldId}]`));
  await frame();
}

/** Whether an element's content is cut (it scrolls in its own box). */
function isCut(element: HTMLElement): boolean {
  return element.scrollWidth > element.clientWidth;
}

const content = (row: number, col: number) =>
  el('[data-datagrid-cellcontent]', cell(row, col));

/** A double-click as the browser sends it: two presses and releases, two clicks, then dblclick. */
async function doubleClick(element: HTMLElement): Promise<void> {
  for (let i = 1; i <= 2; i++) {
    await triggerEvent(element, 'mousedown', { clientX: 10, detail: i });
    await triggerEvent(window as unknown as Element, 'mouseup', {
      clientX: 10
    });
    await triggerEvent(element, 'click', { detail: i });
  }
  await triggerEvent(element, 'dblclick', { detail: 2 });
}

module('Integration | Component | EuiSheet fit width', function (hooks) {
  setupRenderingTest(hooks);

  test('FW1 a double-click on the resize edge emits the fitted width once, not a dragged one', async function (assert) {
    const state = new State();
    const calls: Array<[string, number]> = [];
    state.fieldWidths = { name: 100, notes: 100 };
    state.onFieldWidthChange = (id, width) => {
      calls.push([id, width]);
      state.fieldWidths = { ...state.fieldWidths, [id]: width };
    };
    await renderSheet(state);
    assert.true(isCut(content(1, 1)), 'the long note is cut before');
    await doubleClick(resizerOf(header('notes')));
    await frame();
    assert.strictEqual(calls.length, 1, JSON.stringify(calls));
    const [id, width] = calls[0]!;
    assert.strictEqual(id, 'notes');
    assert.true(width > 100 && width <= 480, `fitted: ${width}`);
    assert.strictEqual(widthOf('notes'), width, 'the grid shows it');
    assert.false(isCut(content(1, 1)), 'the long note is not cut');
    assert.strictEqual(widthOf('name'), 100, 'the other column is kept');

    // a press on the edge that moves nothing emits nothing (each click of
    // the double-click did, in v0.3)
    await triggerEvent(resizerOf(header('name')), 'mousedown', {
      clientX: 10
    });
    await triggerEvent(window as unknown as Element, 'mouseup', {
      clientX: 10
    });
    assert.strictEqual(calls.length, 1, 'no call for an unchanged width');
  });

  test('FW2 "Fit to content" on a text field: the longest value is not cut, the width at most 480', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await fitFromMenu('notes');
    const width = widthOf('notes');
    assert.true(width > 100 && width <= 480, `fitted: ${width}`);
    for (let row = 0; row < 3; row++) {
      assert.false(isCut(content(row, 1)), `row ${row} not cut`);
    }
    state.records = [
      ...rows(),
      {
        id: 'd',
        name: 'Dana',
        notes: LONG.repeat(4),
        status: null,
        done: false
      }
    ];
    await settled();
    await fitFromMenu('notes');
    assert.strictEqual(widthOf('notes'), 480, 'clamped to 480');
  });

  test('FW3 without a handler the sheet keeps the width: over field.width, with an earlier drag kept', async function (assert) {
    const state = new State();
    await renderSheet(state);
    // a drag of Name first: 100 → 140
    const resizer = resizerOf(header('name'));
    await triggerEvent(resizer, 'mousedown', { clientX: 300 });
    await triggerEvent(window as unknown as Element, 'mousemove', {
      clientX: 340
    });
    await triggerEvent(window as unknown as Element, 'mouseup');
    assert.strictEqual(widthOf('name'), 140);
    state.api!.fitField('notes');
    await frame();
    const fitted = widthOf('notes');
    assert.true(fitted > 100, `notes fitted: ${fitted}`);
    assert.false(isCut(content(1, 1)));
    assert.strictEqual(widthOf('name'), 140, 'the drag survives the fit');
    // new columns (a field added) keep both
    state.fields = [...state.fields, { id: 'extra', label: 'Extra' }];
    await settled();
    assert.strictEqual(widthOf('notes'), fitted, 'the fitted width is kept');
    assert.strictEqual(widthOf('name'), 140, 'the drag is kept');
  });

  test('FW4 a checkbox field fits to its header label', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const label = el('.euiDataGridHeaderCell__content', header('done'));
    assert.true(isCut(label), 'the label is cut at 100 px');
    await fitFromMenu('done');
    assert.false(isCut(label), 'the whole label shows');
    assert.true(widthOf('done') > 100, `width ${widthOf('done')}`);
  });

  test('FW5 api.fitFields() emits once per visible field', async function (assert) {
    const state = new State();
    const calls: Array<[string, number]> = [];
    state.onFieldWidthChange = (id, width) => {
      calls.push([id, width]);
      state.fieldWidths = { ...state.fieldWidths, [id]: width };
    };
    await renderSheet(state);
    state.api!.fitFields();
    await frame();
    assert.deepEqual(
      calls.map(([id]) => id),
      ['name', 'notes', 'status', 'done']
    );
    for (const [id, width] of calls) {
      assert.true(width >= 80 && width <= 480, `${id}: ${width}`);
      assert.strictEqual(widthOf(id), width, `${id} shown at ${width}`);
    }
    assert.strictEqual(
      calls.find(([id]) => id === 'name')![1],
      80,
      'a short field gets the least width'
    );
  });

  test('FW6 a single-select field leaves room for its opener: the chip and the button do not overlap', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await fitFromMenu('status');
    const target = cell(1, 2);
    const chip = el('[data-test-subj=euiSheetChip]', target);
    const opener = el('[data-test-subj=euiSheetOpener]', target);
    const chipBox = chip.getBoundingClientRect();
    const openerBox = opener.getBoundingClientRect();
    assert.true(
      chipBox.right <= openerBox.left,
      `chip right ${chipBox.right}, opener left ${openerBox.left}`
    );
    assert.false(isCut(chip), 'the label is whole');
  });

  test('FW7 the item joins a menu that is there; a field without one gets none', async function (assert) {
    const state = new State();
    await renderSheet(state);
    // the first field cannot be hidden or moved: no menu at all (as v0.3)
    assert
      .dom('[data-test-subj=dataGridHeaderCellActionButton-name]')
      .doesNotExist();
    await openMenu('notes');
    assert
      .dom('[data-test-subj=euiSheetFitField-notes]', document.body)
      .hasText('Fit to content');
    // the API still fits it
    state.api!.fitField('name');
    await frame();
    assert.strictEqual(widthOf('name'), 80);
    state.api!.fitField('missing');
    await frame();
    assert.strictEqual(widthOf('name'), 80, 'an unknown field: nothing');
  });
});
