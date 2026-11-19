/**
 * Drag to select, fill down (Ctrl/Cmd+D), tiled paste and select all
 * (Ctrl/Cmd+A). The active cell stays at the anchor (V03 batch 1): AN1-AN4.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, focus, render, triggerEvent } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  clipboard,
  editorFrame,
  el,
  focusCell,
  press,
  pressed,
  selected,
  text,
  type
} from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  done: boolean;
  city: string;
  code: string;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name' },
  { id: 'done', type: 'checkbox' },
  { id: 'city' },
  { id: 'code', readOnly: true }
];

const rows = (count = 4): Row[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    done: false,
    city: `city${i}`,
    code: `C${i}`
  }));

const getId = (row: { id: string }) => row.id;

/** A left-button drag from one cell over others; returns before the click. */
async function drag(
  from: [number, number],
  ...over: Array<[number, number]>
): Promise<void> {
  await triggerEvent(cell(...from), 'mousedown', { button: 0 });
  for (const pos of over) await triggerEvent(cell(...pos), 'mouseover');
}

async function release(at: [number, number]): Promise<void> {
  await triggerEvent(cell(...at), 'mouseup', { button: 0 });
  await triggerEvent(cell(...at), 'click', { button: 0 });
}

module('Integration | Component | EuiSheet ranges', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(
    count?: number,
    fields: EuiSheetField<Row>[] = FIELDS
  ) {
    const store = localRecords<Row>(rows(count), { getRecordId: getId });
    await render(
      <template>
        <div style="width:800px">
          <EuiSheet
            @records={{store.records}}
            @fields={{fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('R1 a drag from (0,0) to (2,1) selects 6 cells and does not edit', async function (assert) {
    const store = await renderSheet();
    // the press is on the focused cell: a plain click there would edit
    await focusCell(0, 0);
    await drag([0, 0], [1, 0], [2, 1]);
    assert
      .dom(el('[data-test-subj=euiSheet]'))
      .hasClass('euiSheet--dragging', 'no text selection while dragging');
    assert.deepEqual(selected(), ['0:0', '0:1', '1:0', '1:1', '2:0', '2:1']);

    await release([2, 1]);
    assert.deepEqual(
      selected(),
      ['0:0', '0:1', '1:0', '1:1', '2:0', '2:1'],
      'still selected after the release'
    );
    assert
      .dom(el('[data-test-subj=euiSheet]'))
      .doesNotHaveClass('euiSheet--dragging');
    assert.strictEqual(editorFrame(), null, 'no editor');
    assert.strictEqual(
      document.activeElement,
      cell(0, 0),
      'focus stays on the anchor (V03 batch 1)'
    );
    assert.strictEqual(store.log.length, 0, 'the checkbox did not toggle');

    await press('ArrowDown', { shiftKey: true });
    assert.strictEqual(
      selected().length,
      8,
      'Shift+arrows continue from the anchor'
    );
  });

  test('R2 the click ending a drag on a checkbox does not toggle; a plain click does', async function (assert) {
    const store = await renderSheet();
    await drag([0, 1], [1, 1]);
    await release([1, 1]);
    assert.deepEqual(selected(), ['0:1', '1:1']);
    assert.strictEqual(store.log.length, 0, 'no toggle');
    assert.false(store.records[1]!.done);

    // a press that stays on its cell is a click
    await drag([2, 1], [2, 1]);
    await release([2, 1]);
    assert.strictEqual(store.log.length, 1, 'one toggle');
    assert.true(store.records[2]!.done);

    // no drag with Shift
    await focusCell(0, 0);
    await triggerEvent(cell(0, 0), 'mousedown', { button: 0, shiftKey: true });
    await triggerEvent(cell(1, 2), 'mouseover');
    assert
      .dom(el('[data-test-subj=euiSheet]'))
      .doesNotHaveClass('euiSheet--dragging', 'Shift+press does not drag');
  });

  test('R3 Ctrl+D over several rows copies the top values down; Ctrl+Z undoes it', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 2);
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowRight', { shiftKey: true });
    assert.true(await pressed('d', { ctrlKey: true }), 'prevented');
    assert.deepEqual(store.log[0], {
      source: 'fill',
      patches: [
        { recordId: 'r1', fieldId: 'city', from: 'city1', to: 'city0' },
        { recordId: 'r2', fieldId: 'city', from: 'city2', to: 'city0' }
      ],
      inserts: [],
      rejected: [],
      newOptions: []
    });
    assert.deepEqual(
      [text(1, 3), text(2, 3)],
      ['C1', 'C2'],
      'the read-only column is skipped'
    );

    await pressed('z', { ctrlKey: true });
    assert.deepEqual([text(1, 2), text(2, 2)], ['city1', 'city2']);
  });

  test('R4 Ctrl+D on one cell copies the cell above', async function (assert) {
    const store = await renderSheet();
    await focusCell(2, 0);
    assert.true(await pressed('d', { metaKey: true }), 'Cmd+D is prevented');
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r2', fieldId: 'name', from: 'name2', to: 'name1' }
    ]);
    assert.strictEqual(store.log[0]!.source, 'fill');

    await focusCell(0, 0);
    assert.true(await pressed('d', { ctrlKey: true }));
    assert.strictEqual(store.log.length, 1, 'nothing above the first row');
  });

  test('R5 paste of one cell into a 3x2 selection fills 6 cells', async function (assert) {
    const store = await renderSheet();
    // 3 rows x 2 columns: name and done
    await focusCell(0, 0);
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowRight', { shiftKey: true });
    await clipboard('paste', 'true');
    assert.strictEqual(store.log.length, 1, 'one change set');
    assert.strictEqual(store.log[0]!.patches.length, 6, 'six cells');
    assert.deepEqual(
      [text(0, 0), text(1, 0), text(2, 0)],
      ['true', 'true', 'true']
    );
    assert.deepEqual(
      store.records.slice(0, 3).map((row) => row.done),
      [true, true, true]
    );
    assert.deepEqual(selected(), ['0:0', '0:1', '1:0', '1:1', '2:0', '2:1']);

    // 3 rows x 2 columns: city and the read-only code (a click: focus()
    // alone would extend the range, as after Shift+arrows)
    await click(cell(0, 2));
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowRight', { shiftKey: true });
    await clipboard('paste', 'x');
    assert.deepEqual(
      store.log[1]!.patches.map(
        (patch) => `${patch.recordId}.${patch.fieldId}`
      ),
      ['r0.city', 'r1.city', 'r2.city'],
      'the read-only cells are skipped'
    );

    // a block that does not fit a whole number of times: pasted as today
    await click(cell(0, 2));
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowDown', { shiftKey: true });
    await clipboard('paste', 'p\nq');
    assert.deepEqual(
      store.log[2]!.patches.map((patch) => patch.to),
      ['p', 'q'],
      '2x1 into 3x1 pastes the block once'
    );
    assert.deepEqual(selected(), ['0:2', '1:2'], 'the pasted block');
  });

  test('R6 Ctrl+A selects every cell; Delete clears the writable ones', async function (assert) {
    const store = await renderSheet(3);
    await focusCell(1, 2);
    assert.true(await pressed('a', { ctrlKey: true }), 'prevented');
    assert.strictEqual(selected().length, 12, '3 rows x 4 columns');
    assert.strictEqual(document.activeElement, cell(1, 2), 'focus stays');

    const copied = await clipboard('copy');
    assert.strictEqual(copied.text.split('\n').length, 3, 'copy takes all');

    await press('Delete');
    const patched = store.log[0]!.patches.map(
      (patch) => `${patch.recordId}.${patch.fieldId}`
    );
    assert.deepEqual(
      patched,
      ['r0.name', 'r0.city', 'r1.name', 'r1.city', 'r2.name', 'r2.city'],
      'every writable cell that was not empty (done is already false)'
    );
    assert.deepEqual(
      [text(0, 3), text(1, 3), text(2, 3)],
      ['C0', 'C1', 'C2'],
      'the read-only column keeps its values'
    );
  });

  test('R7 no drag from an opener or while editing; a release outside the sheet does not swallow the next click', async function (assert) {
    const store = await renderSheet(4, [
      ...FIELDS,
      { id: 'due', type: 'date' }
    ]);
    const wrapper = el('[data-test-subj=euiSheet]');

    await triggerEvent(
      el('[data-test-subj=euiSheetOpener]', cell(0, 4)),
      'mousedown',
      { button: 0 }
    );
    await triggerEvent(cell(1, 4), 'mouseover');
    assert
      .dom(wrapper)
      .doesNotHaveClass('euiSheet--dragging', 'a press on an opener');
    await triggerEvent(document.body, 'mouseup', { button: 0 });

    await focusCell(0, 0);
    await press('Enter');
    assert.ok(editorFrame(), 'editing');
    await triggerEvent(cell(1, 0), 'mousedown', { button: 0 });
    await triggerEvent(cell(2, 0), 'mouseover');
    assert
      .dom(wrapper)
      .doesNotHaveClass('euiSheet--dragging', 'no drag while editing');
    await triggerEvent(document.body, 'mouseup', { button: 0 });
    await press('Escape');
    assert.strictEqual(editorFrame(), null);

    // released outside the sheet: no click follows
    await drag([0, 0], [1, 0]);
    await triggerEvent(document.body, 'mouseup', { button: 0 });
    assert.deepEqual(selected(), ['0:0', '1:0'], 'the drag ended');
    assert.dom(wrapper).doesNotHaveClass('euiSheet--dragging');
    await click(cell(2, 1));
    assert.strictEqual(store.log.length, 1, 'the next click toggles');
    assert.true(store.records[2]!.done);
  });
  /* The active cell stays at the anchor (V03 batch 1) */

  const WIDE: EuiSheetField<Row>[] = [
    { id: 'name' },
    { id: 'city' },
    { id: 'a' },
    { id: 'b' },
    { id: 'c' }
  ];

  test('AN1 after a mouse drag from (0,1) to (0,4) focus is on (0,1); typing edits it', async function (assert) {
    const store = await renderSheet(4, WIDE);
    // a real press focuses the pressed cell
    await triggerEvent(cell(0, 1), 'mousedown', { button: 0 });
    await focus(cell(0, 1));
    for (const col of [2, 3, 4]) await triggerEvent(cell(0, col), 'mouseover');
    await release([0, 4]);
    assert.deepEqual(selected(), ['0:1', '0:2', '0:3', '0:4'], '1×4');
    assert.strictEqual(document.activeElement, cell(0, 1), 'the anchor');
    await type('z');
    assert.ok(editorFrame(), 'typing opens the editor');
    const frame = editorFrame()!.getBoundingClientRect();
    const anchor = cell(0, 1).getBoundingClientRect();
    assert.true(Math.abs(frame.left - anchor.left) < 2, 'over the anchor');
    await press('Enter');
    assert.deepEqual(
      store.log.map((set) =>
        set.patches.map((p) => `${p.recordId}.${p.fieldId}=${String(p.to)}`)
      ),
      [['r0.city=z']],
      'the anchor cell is edited'
    );
  });

  test('AN2 Shift+ArrowRight ×3 then Shift+ArrowDown: focus on the anchor, a 2×4 range', async function (assert) {
    await renderSheet(4, WIDE);
    await focusCell(0, 1);
    for (let i = 0; i < 3; i++) {
      assert.true(
        await pressed('ArrowRight', { shiftKey: true }),
        'the sheet’s'
      );
    }
    await press('ArrowDown', { shiftKey: true });
    assert.deepEqual(selected(), [
      '0:1',
      '0:2',
      '0:3',
      '0:4',
      '1:1',
      '1:2',
      '1:3',
      '1:4'
    ]);
    assert.strictEqual(document.activeElement, cell(0, 1), 'the anchor');
    // at the last field Shift+ArrowRight stays
    await press('ArrowRight', { shiftKey: true });
    assert.strictEqual(selected().length, 8, 'clamped');
    // Delete clears the whole range
    await press('Delete');
    assert.deepEqual([text(1, 1), text(0, 4)], ['', '']);
  });

  test('AN3 Escape collapses the range to the active cell; a plain arrow moves from it', async function (assert) {
    await renderSheet(4, WIDE);
    await focusCell(1, 1);
    await press('ArrowRight', { shiftKey: true });
    await press('ArrowDown', { shiftKey: true });
    assert.strictEqual(selected().length, 4);
    assert.true(await pressed('Escape'), 'the sheet’s');
    assert.deepEqual(selected(), ['1:1'], 'collapsed to the anchor');
    assert.strictEqual(document.activeElement, cell(1, 1));
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowDown');
    assert.deepEqual(selected(), ['2:1'], 'from the active cell');
  });

  test('AN4 Shift+click extends; focus stays; a press on the active cell collapses without editing', async function (assert) {
    await renderSheet(4, WIDE);
    await focusCell(0, 1);
    await click(cell(2, 3), { shiftKey: true });
    assert.strictEqual(selected().length, 9, '3×3');
    assert.strictEqual(document.activeElement, cell(0, 1), 'the anchor');
    await click(cell(0, 1));
    assert.deepEqual(selected(), ['0:1'], 'collapsed');
    assert.strictEqual(editorFrame(), null, 'no edit');
    await click(cell(0, 1));
    assert.ok(editorFrame(), 'a second click on the active cell edits');
  });
});
