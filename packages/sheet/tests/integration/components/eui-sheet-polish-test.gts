/**
 * EuiSheet editing polish of v0.2 batch 6 (V02-DESIGN.md 8.4, 8.7); the
 * shortcut list (V03 5.5, KH1-KH4) and the range feedback of v0.3 batch 1
 * (RF1, RF2, FH1).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  focus,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';

import EuiSheet from '#src/components/eui-sheet.gts';
import { frames as autoScrollFrames } from '#src/-private/auto-scroll.ts';
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
  text
} from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { SheetApi } from '#src/types.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const getId = (row: { id: string }) => row.id;

/** Waits `count` animation frames. */
async function frames(count: number): Promise<void> {
  for (let i = 0; i < count; i++) {
    await new Promise((resolve) => requestAnimationFrame(resolve));
  }
  await settled();
}

/** `count` text fields of 150 px: f0, f1, ... */
function wideFields(count: number): EuiSheetField<Row>[] {
  return Array.from({ length: count }, (_, i) => ({
    id: `f${i}`,
    label: `F${i}`,
    width: 150
  }));
}

function wideRows(count: number, fields: number): Row[] {
  return Array.from({ length: count }, (_, row) => {
    const record: Row = { id: `r${row}` };
    for (let col = 0; col < fields; col++) record[`f${col}`] = `${row}-${col}`;
    return record;
  });
}

/** The focused cell's position, as `row:col` (data column). */
function focusedAt(): string {
  const active = document.activeElement as HTMLElement | null;
  const row = active?.dataset['gridcellVisibleRowIndex'];
  const col = active?.dataset['gridcellColumnIndex'];
  return row === undefined ? 'none' : `${row}:${Number(col) - 1}`;
}

/** Scrolls the grid's body to `top` and waits for the render. */
async function scrollGridTo(top: number): Promise<void> {
  const outer = document.querySelector<HTMLElement>(
    '.euiDataGrid__virtualized'
  )!;
  outer.scrollTop = top;
  await triggerEvent(outer, 'scroll');
}

/** A mouse event on the document at a point (the drags listen there). */
async function mouseAt(
  type: 'mousemove' | 'mouseup',
  x: number,
  y: number,
  init: MouseEventInit = {}
): Promise<void> {
  document.dispatchEvent(
    new MouseEvent(type, {
      bubbles: true,
      cancelable: true,
      clientX: x,
      clientY: y,
      button: 0,
      ...init
    })
  );
  await settled();
}

function center(element: Element): { x: number; y: number } {
  const box = element.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
}

/** A cut on the focused cell; the clipboard's text and whether it was the sheet's. */
async function cut(): Promise<{ text: string; prevented: boolean }> {
  const clipboardData = new DataTransfer();
  const event = new ClipboardEvent('cut', {
    clipboardData,
    bubbles: true,
    cancelable: true
  });
  document.activeElement!.dispatchEvent(event);
  await settled();
  return {
    text: clipboardData.getData('text/plain'),
    prevented: event.defaultPrevented
  };
}

const numberFields = (): EuiSheetField<Row>[] => [
  { id: 'n', label: 'N', type: 'number' },
  { id: 'd', label: 'D', type: 'date' },
  { id: 't', label: 'T' }
];

function numberRows(): Row[] {
  return [
    { id: 'r0', n: 1, d: '2026-01-01', t: 'a' },
    { id: 'r1', n: 2, d: '2026-01-08', t: 'b' },
    { id: 'r2', n: null, d: null, t: '' },
    { id: 'r3', n: null, d: null, t: '' },
    { id: 'r4', n: 9, d: null, t: 'z' }
  ];
}

/** `count` rows whose first field has a value up to row `filled`. */
function tallRows(count: number, filled: number): Row[] {
  return Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    a: i < filled ? `a${i}` : '',
    b: `b${i}`
  }));
}

const tallFields = (): EuiSheetField<Row>[] => [
  { id: 'a', label: 'A' },
  { id: 'b', label: 'B' }
];

module('Integration | Component | EuiSheet editing polish', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    // elementFromPoint and the scroll checks need the grid on screen
    document.getElementById('ember-testing-container')?.scrollIntoView();
  });

  async function renderSheet(
    fields: EuiSheetField<Row>[],
    records: Row[],
    options: {
      width?: number;
      height?: number;
      readOnly?: boolean;
      frozenFields?: number;
    } = {}
  ) {
    const store = localRecords<Row>(records, { getRecordId: getId, fields });
    const style = htmlSafe(`width:${options.width ?? 1100}px`);
    const height = options.height;
    const readOnly = options.readOnly;
    const frozenFields = options.frozenFields;
    await render(
      <template>
        <div style={{style}}>
          <EuiSheet
            @records={{store.records}}
            @fields={{store.fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @height={{height}}
            @readOnly={{readOnly}}
            @frozenFields={{frozenFields}}
          />
        </div>
      </template>
    );
    return store;
  }

  function handle(): HTMLElement | null {
    const element = document.querySelector<HTMLElement>(
      '[data-test-subj=euiSheetFillHandle]'
    );
    return element && element.style.display !== 'none' ? element : null;
  }

  test('P1 the fill handle: a drag down fills a series, one undo', async function (assert) {
    const store = await renderSheet(numberFields(), numberRows());
    await focusCell(0, 0);
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowRight', { shiftKey: true });
    assert.deepEqual(selected(), ['0:0', '0:1', '1:0', '1:1']);
    const square = handle();
    assert.ok(square, 'the handle shows');
    const corner = cell(1, 1).getBoundingClientRect();
    const box = square!.getBoundingClientRect();
    assert.true(
      Math.abs(box.left + box.width / 2 - corner.right) < 3 &&
        Math.abs(box.top + box.height / 2 - corner.bottom) < 3,
      'at the bottom-right corner of the range'
    );
    const start = center(square!);
    await triggerEvent(square!, 'mousedown', {
      button: 0,
      clientX: start.x,
      clientY: start.y
    });
    // the active cell is the range's anchor (V03 batch 1)
    assert.strictEqual(focusedAt(), '0:0', 'the press keeps focus');
    const to = center(cell(3, 1));
    await mouseAt('mousemove', to.x, to.y);
    assert.deepEqual(
      Array.from(document.querySelectorAll('.euiSheet__cell--fillPreview'))
        .map((element) => {
          const e = element as HTMLElement;
          return `${e.dataset['gridcellVisibleRowIndex']}:${Number(e.dataset['gridcellColumnIndex']) - 1}`;
        })
        .sort(),
      ['2:0', '2:1', '3:0', '3:1'],
      'the target is previewed'
    );
    await mouseAt('mouseup', to.x, to.y);
    assert.dom('.euiSheet__cell--fillPreview').doesNotExist();
    assert.strictEqual(store.log.length, 1, 'one change set');
    assert.strictEqual(store.log[0]!.source, 'fill');
    assert.deepEqual(
      store.log[0]!.patches.map((p) => [p.recordId, p.fieldId, p.to]),
      [
        ['r2', 'n', 3],
        ['r3', 'n', 4],
        ['r2', 'd', '2026-01-15'],
        ['r3', 'd', '2026-01-22']
      ]
    );
    assert.deepEqual(
      selected(),
      ['0:0', '0:1', '1:0', '1:1', '2:0', '2:1', '3:0', '3:1'],
      'the union is selected'
    );
    assert.strictEqual(text(3, 0), '4');
    assert.true(await pressed('z', { ctrlKey: true }), 'undo');
    assert.strictEqual(text(2, 0), '', 'one undo');
    assert.strictEqual(text(3, 1), '');
    // Ctrl held at release copies instead
    await focusCell(0, 0);
    await press('ArrowDown', { shiftKey: true });
    const again = center(handle()!);
    await triggerEvent(handle()!, 'mousedown', {
      button: 0,
      clientX: again.x,
      clientY: again.y
    });
    const row3 = center(cell(3, 0));
    await mouseAt('mousemove', row3.x, row3.y);
    await mouseAt('mouseup', row3.x, row3.y, { ctrlKey: true });
    assert.deepEqual(
      store.log[store.log.length - 1]!.patches.map((p) => [p.recordId, p.to]),
      [
        ['r2', 1],
        ['r3', 2]
      ],
      'Ctrl: the samples repeat'
    );
    // Escape cancels a drag
    await focusCell(4, 0);
    const third = center(handle()!);
    await triggerEvent(handle()!, 'mousedown', {
      button: 0,
      clientX: third.x,
      clientY: third.y
    });
    const up = center(cell(2, 0));
    await mouseAt('mousemove', up.x, up.y);
    assert.dom('.euiSheet__cell--fillPreview').exists({ count: 2 });
    document.dispatchEvent(
      new KeyboardEvent('keydown', {
        key: 'Escape',
        bubbles: true,
        cancelable: true
      })
    );
    await settled();
    await mouseAt('mouseup', up.x, up.y);
    assert.dom('.euiSheet__cell--fillPreview').doesNotExist();
    assert.strictEqual(store.log.length, 3, 'Escape: no change set');
  });

  test('P2 the handle hides while editing, on a column range and with @readOnly', async function (assert) {
    await renderSheet(numberFields(), numberRows());
    await focusCell(0, 2);
    assert.ok(handle());
    await press('Enter');
    assert.dom(editorFrame()).exists();
    assert.dom('[data-test-subj=euiSheetFillHandle]').doesNotExist();
    await press('Escape');
    assert.ok(handle(), 'back after the edit');
    // a column selected by its title: no handle
    await click(
      el(
        '[role=columnheader][data-gridcell-column-index="2"] .euiDataGridHeaderCell__content'
      )
    );
    assert.strictEqual(selected().length, 5, 'the column is selected');
    assert.dom('[data-test-subj=euiSheetFillHandle]').doesNotExist();
    await renderSheet(numberFields(), numberRows(), { readOnly: true });
    await focusCell(0, 2);
    assert.dom('[data-test-subj=euiSheetFillHandle]').doesNotExist();
  });

  test('P3 cut puts TSV on the clipboard and clears, source cut; read-only copies only', async function (assert) {
    const store = await renderSheet(numberFields(), numberRows());
    await focusCell(0, 0);
    await press('ArrowRight', { shiftKey: true });
    await press('ArrowRight', { shiftKey: true });
    const result = await cut();
    assert.true(result.prevented, 'the sheet’s');
    assert.strictEqual(result.text, '1\t2026-01-01\ta');
    assert.strictEqual(store.log.length, 1);
    assert.strictEqual(store.log[0]!.source, 'cut');
    assert.deepEqual(
      store.log[0]!.patches.map((p) => [p.fieldId, p.to]),
      [
        ['n', null],
        ['d', null],
        ['t', '']
      ]
    );
    assert.true(await pressed('z', { ctrlKey: true }), 'undo');
    assert.strictEqual(text(0, 2), 'a', 'one undo');
    const readOnly = await renderSheet(numberFields(), numberRows(), {
      readOnly: true
    });
    await focusCell(1, 2);
    const copied = await cut();
    assert.strictEqual(copied.text, 'b');
    assert.strictEqual(readOnly.log.length, 0, 'nothing cleared');
  });

  test('P4 Ctrl+R fills right', async function (assert) {
    const store = await renderSheet(tallFields(), tallRows(3, 3));
    await focusCell(0, 0);
    await press('ArrowRight', { shiftKey: true });
    await press('ArrowDown', { shiftKey: true });
    assert.true(await pressed('r', { ctrlKey: true }), 'Ctrl+R is the sheet’s');
    assert.deepEqual(
      store.log[0]!.patches.map((p) => [p.recordId, p.fieldId, p.to]),
      [
        ['r0', 'b', 'a0'],
        ['r1', 'b', 'a1']
      ]
    );
    // one cell: from the cell to its left
    await focusCell(2, 1);
    assert.true(await pressed('r', { metaKey: true }), 'Cmd+R too');
    assert.strictEqual(text(2, 1), 'a2');
  });

  test('P5 Ctrl+ArrowDown jumps past the rendered rows; with Shift it extends', async function (assert) {
    await renderSheet(tallFields(), tallRows(200, 150), { height: 300 });
    await focusCell(0, 0);
    await press('ArrowDown', { ctrlKey: true });
    await waitUntil(() => focusedAt() === '149:0', { timeout: 2000 });
    assert.deepEqual(selected(), ['149:0'], 'the last value of the block');
    assert.strictEqual(
      el('.euiDataGrid__virtualized').querySelector(
        '[data-gridcell-visible-row-index="0"]'
      ),
      null,
      'row 0 is not rendered'
    );
    await press('ArrowDown', { ctrlKey: true, shiftKey: true });
    // the head is scrolled into view; focus stays on the anchor (V03 batch
    // 1), held by the grid's body while row 149 is not rendered
    await waitUntil(() => selected().includes('199:0'), { timeout: 2000 });
    const copied = await clipboard('copy');
    assert.strictEqual(
      copied.text.split('\n').length,
      51,
      'rows 149 to 199: the anchor stayed'
    );
    // without Shift: from the active cell (149), as in Excel
    await press('ArrowUp', { ctrlKey: true });
    await waitUntil(() => focusedAt() === '0:0', { timeout: 2000 });
    assert.deepEqual(
      selected(),
      ['0:0'],
      'without Shift the range collapses, from the active cell'
    );
    assert.true(await pressed('ArrowLeft', { ctrlKey: true }), 'stopped');
    assert.strictEqual(focusedAt(), '0:0', 'at the edge: stays');
  });

  test('P6 Shift+End and Ctrl+Shift+End extend', async function (assert) {
    await renderSheet(numberFields(), numberRows());
    await focusCell(1, 0);
    assert.true(await pressed('End', { shiftKey: true }));
    assert.deepEqual(selected(), ['1:0', '1:1', '1:2']);
    // focus stays on the active cell, the anchor (V03 batch 1)
    assert.strictEqual(focusedAt(), '1:0');
    await press('Home', { shiftKey: true });
    assert.deepEqual(selected(), ['1:0'], 'Shift+Home back to the first field');
    assert.strictEqual(focusedAt(), '1:0', 'not the row number');
    await press('End', { shiftKey: true, ctrlKey: true });
    await waitUntil(() => selected().length === 12);
    assert.strictEqual(selected().length, 12, 'rows 1 to 4 (not the add row)');
    assert.strictEqual(focusedAt(), '1:0');
    await press('Home', { shiftKey: true, ctrlKey: true });
    await waitUntil(() => selected().length === 2);
    assert.deepEqual(
      selected(),
      ['0:0', '1:0'],
      'to the first cell, from the anchor'
    );
  });

  test('P7 PageDown moves by the rows in view; Shift extends', async function (assert) {
    await renderSheet(tallFields(), tallRows(200, 200), { height: 300 });
    await focusCell(0, 0);
    assert.true(await pressed('PageDown'), 'the sheet’s');
    await waitUntil(() => focusedAt() !== '0:0');
    const page = Number(focusedAt().split(':')[0]);
    assert.true(page >= 3, `moved ${page} rows`);
    assert.deepEqual(selected(), [`${page}:0`]);
    await press('PageDown', { shiftKey: true });
    // the head moves; focus stays on the active cell (V03 batch 1)
    await waitUntil(() => selected().includes(`${page * 2}:0`));
    // the scroll may re-create the active cell's row: focus comes back to it
    await waitUntil(() => focusedAt() === `${page}:0`);
    const copied = await clipboard('copy');
    assert.strictEqual(copied.text.split('\n').length, page + 1);
    // from the active cell (row `page`): one PageUp reaches row 0
    await press('PageUp');
    await waitUntil(() => focusedAt() === '0:0');
    assert.deepEqual(selected(), ['0:0']);
  });

  module('auto-scroll', function (hooks) {
    let queue: Array<FrameRequestCallback | null> = [];
    let cancelled: number[] = [];
    const original = { ...autoScrollFrames };

    hooks.beforeEach(function () {
      queue = [];
      cancelled = [];
      autoScrollFrames.request = (callback) => {
        queue.push(callback);
        return queue.length;
      };
      autoScrollFrames.cancel = (id) => {
        cancelled.push(id);
        queue[id - 1] = null;
      };
    });

    hooks.afterEach(function () {
      autoScrollFrames.request = original.request;
      autoScrollFrames.cancel = original.cancel;
    });

    /** Runs the frames queued so far. */
    async function tick(): Promise<void> {
      const now = queue.splice(0, queue.length);
      queue.push(...now.map(() => null));
      for (const callback of now) callback?.(performance.now());
      await settled();
    }

    const pending = () => queue.filter(Boolean).length;

    async function startDrag(): Promise<{ x: number; y: number }> {
      const from = center(cell(1, 1));
      await triggerEvent(cell(1, 1), 'mousedown', {
        button: 0,
        clientX: from.x,
        clientY: from.y
      });
      await triggerEvent(cell(2, 1), 'mouseover');
      const outer = el('.euiDataGrid__virtualized').getBoundingClientRect();
      // under the grid
      const point = { x: from.x, y: outer.bottom + 30 };
      await mouseAt('mousemove', point.x, point.y);
      return point;
    }

    test('P8 a drag held under the grid scrolls, and the head follows', async function (assert) {
      await renderSheet(tallFields(), tallRows(200, 200), { height: 300 });
      const outer = el('.euiDataGrid__virtualized');
      const point = await startDrag();
      assert.strictEqual(pending(), 1, 'the loop started');
      const lastBefore = Math.max(
        ...selected().map((pos) => Number(pos.split(':')[0]))
      );
      for (let i = 0; i < 10; i++) await tick();
      assert.true(outer.scrollTop > 50, `scrolled to ${outer.scrollTop}`);
      const last = Math.max(
        ...selected().map((pos) => Number(pos.split(':')[0]))
      );
      assert.true(last > lastBefore + 2, `the head followed to row ${last}`);
      assert.dom('.euiSheet').hasClass('euiSheet--dragging');
      // P9: the release stops the loop
      await mouseAt('mouseup', point.x, point.y);
      assert.strictEqual(pending(), 0, 'no frame left after the release');
      const top = outer.scrollTop;
      await tick();
      assert.strictEqual(outer.scrollTop, top, 'no more scrolling');
    });

    test('P9 the loop stops on destroy, and when the edge is reached', async function (assert) {
      await renderSheet(tallFields(), tallRows(200, 200), { height: 300 });
      await startDrag();
      assert.strictEqual(pending(), 1);
      await render(<template>gone</template>);
      assert.strictEqual(pending(), 0, 'destroy cancelled the frame');
      assert.true(cancelled.length > 0);
      // the edge: a short sheet cannot scroll, so the loop ends by itself
      await renderSheet(tallFields(), tallRows(3, 3), { height: 300 });
      await startDrag();
      await tick();
      assert.strictEqual(pending(), 0, 'nothing to scroll: no next frame');
    });

    test('P10 a real release after auto-scroll keeps the range (the grid scrolls back to the pressed cell on pointerup)', async function (assert) {
      await renderSheet(tallFields(), tallRows(200, 200), { height: 300 });
      const from = center(cell(1, 1));
      cell(1, 1).dispatchEvent(
        new PointerEvent('pointerdown', {
          bubbles: true,
          pointerType: 'mouse',
          isPrimary: true,
          button: 0,
          clientX: from.x,
          clientY: from.y
        })
      );
      await triggerEvent(cell(1, 1), 'mousedown', {
        button: 0,
        clientX: from.x,
        clientY: from.y
      });
      await focus(cell(1, 1));
      await triggerEvent(cell(2, 1), 'mouseover');
      const outer = el('.euiDataGrid__virtualized').getBoundingClientRect();
      const point = { x: from.x, y: outer.bottom + 30 };
      await mouseAt('mousemove', point.x, point.y);
      for (let i = 0; i < 60; i++) await tick();
      const last = Math.max(
        ...selected().map((pos) => Number(pos.split(':')[0]))
      );
      assert.true(last > 20, `dragged to row ${last}`);
      document.dispatchEvent(
        new PointerEvent('pointerup', {
          bubbles: true,
          pointerType: 'mouse',
          isPrimary: true,
          button: 0,
          clientX: point.x,
          clientY: point.y
        })
      );
      // a browser renders between pointerup and mouseup (microtasks): the
      // grid's scroll back to the pressed cell unmounts the head
      await settled();
      assert.strictEqual(
        document.querySelector(`[data-gridcell-visible-row-index="${last}"]`),
        null,
        'the head is not rendered at the release'
      );
      await mouseAt('mouseup', point.x, point.y);
      // focus stays on the anchor, the pressed cell (V03 batch 1)
      await waitUntil(() => focusedAt() === '1:1', { timeout: 2000 });
      const copied = await clipboard('copy');
      assert.strictEqual(
        copied.text.split('\n').length,
        last,
        `rows 1 to ${last} are still selected`
      );
    });

    test('P11 a plain press near an edge does not scroll', async function (assert) {
      await renderSheet(tallFields(), tallRows(200, 200), { height: 300 });
      await scrollGridTo(300);
      const outer = el('.euiDataGrid__virtualized');
      const header = el(
        '[data-test-subj=dataGridHeader]'
      ).getBoundingClientRect();
      const x = center(cell(10, 1)).x;
      const target = document
        .elementFromPoint(x, header.bottom + 3)
        ?.closest<HTMLElement>('[role=gridcell]');
      assert.ok(target, 'the top visible row');
      await triggerEvent(target!, 'mousedown', {
        button: 0,
        clientX: x,
        clientY: header.bottom + 3
      });
      await mouseAt('mousemove', x + 1, header.bottom + 3);
      assert.strictEqual(pending(), 0, 'no frame requested');
      await tick();
      assert.strictEqual(outer.scrollTop, 300, 'not scrolled');
      await mouseAt('mouseup', x + 1, header.bottom + 3);
    });
  });

  test('ED1 an editor opened on a far column right after its focus stays open', async function (assert) {
    // frozen: the far cell is in the DOM before it is scrolled into view
    await renderSheet(wideFields(14), wideRows(5, 14), {
      width: 600,
      frozenFields: 1
    });
    const outer = el('.euiDataGrid__virtualized');
    await focusCell(0, 12);
    assert.true(outer.scrollLeft > 0, 'the grid scrolled to the column');
    // no frame waited: the focus's scroll event has not come yet
    await press('Enter');
    assert.dom(editorFrame()).exists('the editor opened');
    await frames(2);
    assert.dom(editorFrame()).exists('still open after the scroll event');
    // the late scroll event of LT1/LK1, dispatched on purpose
    await triggerEvent(outer, 'scroll');
    assert.dom(editorFrame()).exists('a scroll that keeps the cell in view');
    const frame = editorFrame()!.getBoundingClientRect();
    const box = cell(0, 12).getBoundingClientRect();
    assert.true(
      Math.abs(frame.left - box.left) < 2 && Math.abs(frame.top - box.top) < 2,
      'the editor is over its cell'
    );
  });

  test('ED1b columns virtualized (the default): End, then Enter at once, keeps the editor open', async function (assert) {
    await renderSheet(wideFields(14), wideRows(5, 14), { width: 600 });
    const outer = el('.euiDataGrid__virtualized');
    await focusCell(0, 0);
    assert
      .dom(
        '[role=gridcell][data-gridcell-visible-row-index="0"][data-gridcell-column-index="14"]'
      )
      .doesNotExist('the last column is not rendered yet');
    await press('End');
    assert.true(outer.scrollLeft > 0, 'the grid scrolled to the last column');
    // no frame waited: the focus's scroll event has not come yet
    await press('Enter');
    assert.dom(editorFrame()).exists('the editor opened');
    await frames(2);
    assert.dom(editorFrame()).exists('still open after the scroll event');
    await triggerEvent(outer, 'scroll');
    assert.dom(editorFrame()).exists('a scroll that keeps the cell in view');
    const frame = editorFrame()!.getBoundingClientRect();
    const box = cell(0, 13).getBoundingClientRect();
    assert.true(
      Math.abs(frame.left - box.left) < 2 && Math.abs(frame.top - box.top) < 2,
      'the editor is over its cell'
    );
  });

  test('ED2 a scroll that takes the cell out of view saves the editor', async function (assert) {
    const store = await renderSheet(wideFields(14), wideRows(5, 14), {
      width: 600
    });
    const outer = el('.euiDataGrid__virtualized');
    await focusCell(0, 3);
    await frames(2);
    await press('Enter');
    const input = el(
      '[data-test-subj=euiSheetEditor] input'
    ) as HTMLInputElement;
    input.value = 'moved';
    await triggerEvent(input, 'input');
    // the cell leaves the view (and, columns being virtualized, the DOM)
    outer.scrollLeft = 1200;
    await triggerEvent(outer, 'scroll');
    assert.strictEqual(editorFrame(), null, 'saved and closed');
    assert.strictEqual(store.log[0]?.patches[0]?.to, 'moved');
  });
  /* Range feedback (V03 batch 1): the outline, and the tint over the row hover */

  function outline(): HTMLElement | null {
    const clip = document.querySelector<HTMLElement>(
      '[data-test-subj=euiSheetRangeOutline]'
    );
    return clip && clip.style.display !== 'none'
      ? (clip.firstElementChild as HTMLElement)
      : null;
  }

  /** The union of the boxes of row `row`'s cells `from`..`to`. */
  function union(row: number, from: number, to: number): DOMRect {
    const first = cell(row, from).getBoundingClientRect();
    const last = cell(row, to).getBoundingClientRect();
    return new DOMRect(
      Math.min(first.left, last.left),
      first.top,
      Math.max(first.right, last.right) - Math.min(first.left, last.left),
      first.height
    );
  }

  function assertBox(assert: Assert, box: DOMRect, label: string): void {
    const drawn = outline()!.getBoundingClientRect();
    const off = Math.max(
      Math.abs(drawn.left - box.left),
      Math.abs(drawn.top - box.top),
      Math.abs(drawn.right - box.right),
      Math.abs(drawn.bottom - box.bottom)
    );
    assert.true(
      off <= 1,
      `${label}: the outline is the cells' box (${off.toFixed(1)} px off)`
    );
  }

  for (const frozenFields of [0, 1]) {
    test(`RF1 a 1×3 range has an outline around its cells, after a scroll too (frozen ${frozenFields})`, async function (assert) {
      await renderSheet(wideFields(14), wideRows(5, 14), {
        width: 600,
        frozenFields
      });
      await focusCell(1, 2);
      await frames(2);
      assert.strictEqual(outline(), null, 'none for one cell');
      await press('ArrowRight', { shiftKey: true });
      await press('ArrowRight', { shiftKey: true });
      await frames(2);
      assert.deepEqual(selected(), ['1:2', '1:3', '1:4']);
      assert.ok(outline(), 'an outline');
      assert.strictEqual(
        getComputedStyle(outline()!).borderTopWidth,
        '3px',
        '3 px, inside the box'
      );
      assert.strictEqual(getComputedStyle(outline()!).boxSizing, 'border-box');
      // the active cell: its 3 px ring inside the cell (on the range's
      // edge it is under the outline's 3 px), the plain background
      const active = document.activeElement as HTMLElement;
      const activeStyle = getComputedStyle(active);
      assert.strictEqual(activeStyle.outlineWidth, '3px', 'the ring: 3 px');
      assert.strictEqual(activeStyle.outlineOffset, '-3px', 'inside the cell');
      const probe = document.createElement('span');
      probe.style.color = 'var(--euiSheet-plain)';
      el('[data-test-subj=euiSheet]').appendChild(probe);
      const plain = getComputedStyle(probe).color;
      probe.remove();
      assert.strictEqual(
        activeStyle.backgroundColor,
        plain,
        'the active cell is plain in the range'
      );
      assert.strictEqual(activeStyle.backgroundImage, 'none');
      assert.notStrictEqual(
        getComputedStyle(cell(1, 3)).backgroundColor,
        plain,
        'the other cells are tinted'
      );
      assert.strictEqual(
        getComputedStyle(outline()!.parentElement!).pointerEvents,
        'none',
        'no pointer events'
      );
      assertBox(assert, union(1, 2, 4), 'in place');
      const outer = el('.euiDataGrid__virtualized');
      outer.scrollLeft = 120;
      await triggerEvent(outer, 'scroll');
      await frames(2);
      assertBox(assert, union(1, 2, 4), 'after a horizontal scroll');
      // clipped to the body: never over the header
      const clip = outline()!.parentElement!.getBoundingClientRect();
      const header = el(
        '[data-test-subj=dataGridHeader]'
      ).getBoundingClientRect();
      assert.true(clip.top >= header.bottom - 1, 'below the header');
      if (frozenFields) {
        const frozen = cell(1, 0).getBoundingClientRect();
        assert.true(
          clip.left >= frozen.right - 1,
          'not over the frozen field (the range has none of it)'
        );
      }
      // out of view: hidden
      outer.scrollLeft = 1500;
      await triggerEvent(outer, 'scroll');
      await frames(2);
      assert.strictEqual(
        outline(),
        null,
        'hidden while the range is out of view'
      );
      // a single cell again: none
      outer.scrollLeft = 0;
      await triggerEvent(outer, 'scroll');
      await frames(2);
      await click(cell(0, 1));
      await frames(1);
      assert.deepEqual(selected(), ['0:1'], 'one cell again');
      assert.strictEqual(outline(), null, 'none for one cell, again');
    });
  }

  test('FH1 the fill handle: 10 px in a 2 px ring, centred on the corner and the outline, a 16 px hit area, above the outline', async function (assert) {
    for (const frozenFields of [0, 1]) {
      await renderSheet(wideFields(8), wideRows(5, 8), {
        width: 600,
        frozenFields
      });
      await focusCell(1, 1);
      await press('ArrowRight', { shiftKey: true });
      await frames(2);
      const square = handle()!;
      assert.ok(square, `frozen ${frozenFields}: shown`);
      // offsetWidth: CSS px (the test container is scaled)
      assert.strictEqual(square.offsetWidth, 14, '14 px drawn');
      const style = getComputedStyle(square);
      assert.strictEqual(style.width, '10px', 'a 10 px square');
      assert.strictEqual(style.borderTopWidth, '2px', 'in a 2 px ring');
      assert.strictEqual(style.cursor, 'crosshair');
      const hit = getComputedStyle(square, '::before');
      assert.strictEqual(`${hit.width} ${hit.height}`, '16px 16px', 'hit area');
      const corner = cell(1, 2).getBoundingClientRect();
      const box = square.getBoundingClientRect();
      assert.true(
        Math.abs(box.left + box.width / 2 - corner.right) <= 1 &&
          Math.abs(box.top + box.height / 2 - corner.bottom) <= 1,
        'centred on the corner'
      );
      const drawn = outline()!.getBoundingClientRect();
      assert.true(
        Math.abs(drawn.right - corner.right) <= 1 &&
          Math.abs(drawn.bottom - corner.bottom) <= 1,
        'on the outline’s corner'
      );
      assert.true(
        Number(style.zIndex) >
          Number(getComputedStyle(outline()!.parentElement!).zIndex),
        'above the outline'
      );
      assert.strictEqual(
        document.elementFromPoint(
          box.left + box.width / 2,
          box.top + box.height / 2
        ),
        square,
        'nothing over it'
      );
    }
  });

  test('AN5 Shift+Ctrl+ArrowDown in a long column scrolls the head into view; focus stays on the anchor', async function (assert) {
    await renderSheet(tallFields(), tallRows(200, 200), { height: 300 });
    await focusCell(0, 1);
    assert.true(await pressed('ArrowDown', { ctrlKey: true, shiftKey: true }));
    await waitUntil(() => selected().includes('199:1'), { timeout: 2000 });
    const bounds = el('.euiDataGrid__virtualized').getBoundingClientRect();
    const head = cell(199, 1).getBoundingClientRect();
    assert.true(
      head.bottom <= bounds.bottom + 1 && head.top >= bounds.top - 1,
      `the head is in view (${head.top}-${head.bottom} in ${bounds.top}-${bounds.bottom})`
    );
    // row 0 is not rendered: the grid's body holds focus for it
    await waitUntil(() => document.activeElement === el('[role=grid]'), {
      timeout: 2000
    });
    assert.strictEqual(document.activeElement, el('[role=grid]'), 'held');
    // keys still act on the range
    await press('ArrowUp', { shiftKey: true });
    await waitUntil(() => !selected().includes('199:1'));
    const copied = await clipboard('copy');
    assert.strictEqual(copied.text.split('\n').length, 199, 'rows 0 to 198');
    // Escape collapses and brings the active cell back
    await press('Escape');
    await waitUntil(() => document.activeElement === cell(0, 1), {
      timeout: 2000
    });
    assert.deepEqual(selected(), ['0:1'], 'collapsed to the anchor');
  });

  test('AC1 the active cell’s ring: 3 px inside; an invalid cell keeps its error line; a frozen one its background', async function (assert) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'a', label: 'A', required: true },
      { id: 'b', label: 'B' }
    ];
    await renderSheet(fields, [{ id: 'r0', a: '', b: 'x' }], {
      frozenFields: 1
    });
    await focusCell(0, 0);
    const style = getComputedStyle(cell(0, 0));
    assert.dom(cell(0, 0)).hasClass('euiSheet__cell--invalid');
    assert.strictEqual(style.outlineWidth, '3px');
    assert.strictEqual(style.outlineOffset, '-3px');
    assert.true(
      style.boxShadow.includes('inset') && style.boxShadow.includes('4px'),
      `the error line inside the ring (${style.boxShadow})`
    );
    assert.true(/^rgb\(/.test(style.backgroundColor), 'frozen: opaque');
    assert.strictEqual(
      getComputedStyle(cell(0, 0), '::after').borderTopColor,
      'rgba(0, 0, 0, 0)',
      'no second ring from the grid'
    );
  });

  test('VP2 copy and cut mark the range dashed until Escape or a change; a paste and a fill flash their cells', async function (assert) {
    await renderSheet(numberFields(), numberRows());
    const copiedMark = () =>
      document.querySelector<HTMLElement>(
        '[data-test-subj=euiSheetCopiedOutline]'
      );
    await focusCell(0, 2);
    await press('ArrowDown', { shiftKey: true });
    await clipboard('copy');
    assert.ok(copiedMark(), 'copied: marked');
    assert.strictEqual(
      getComputedStyle(copiedMark()!.firstElementChild!).outlineStyle,
      'dashed'
    );
    assert.true(await pressed('Escape'), 'Escape is the sheet’s');
    assert.strictEqual(copiedMark(), null, 'Escape ends the mark');
    await clipboard('copy');
    assert.ok(copiedMark(), 'copied again');
    await click(cell(3, 2));
    await clipboard('paste', 'p\nq');
    assert.strictEqual(copiedMark(), null, 'a change ends it');
    const flash = document.querySelector<HTMLElement>(
      '[data-test-subj=euiSheetFlash]'
    );
    assert.ok(flash, 'the pasted cells flash');
    await waitUntil(
      () => !document.querySelector('[data-test-subj=euiSheetFlash]'),
      { timeout: 2000 }
    );
    assert.ok(true, 'and the flash ends');
    // cut: marked too; an edit ends the mark
    await focusCell(0, 0);
    await cut();
    assert.ok(copiedMark(), 'cut: marked');
    await focusCell(1, 2);
    await press('Enter');
    assert.ok(editorFrame(), 'editing');
    assert.strictEqual(copiedMark(), null, 'an edit ends it');
    await press('Escape');
  });

  test('VP3 a fill drag outlines its target area dashed', async function (assert) {
    await renderSheet(numberFields(), numberRows());
    await focusCell(0, 0);
    await press('ArrowDown', { shiftKey: true });
    const square = handle()!;
    const start = center(square);
    await triggerEvent(square, 'mousedown', {
      button: 0,
      clientX: start.x,
      clientY: start.y
    });
    const to = center(cell(3, 0));
    await mouseAt('mousemove', to.x, to.y);
    const target = document.querySelector<HTMLElement>(
      '[data-test-subj=euiSheetFillOutline]'
    );
    assert.ok(target, 'the target area is outlined');
    const drawn = target!.firstElementChild!.getBoundingClientRect();
    const top = cell(0, 0).getBoundingClientRect();
    const bottom = cell(3, 0).getBoundingClientRect();
    assert.true(
      Math.abs(drawn.top - top.top) <= 1 &&
        Math.abs(drawn.bottom - bottom.bottom) <= 1,
      'around rows 0 to 3'
    );
    await mouseAt('mouseup', to.x, to.y);
    assert.strictEqual(
      document.querySelector('[data-test-subj=euiSheetFillOutline]'),
      null,
      'gone at the release'
    );
    assert.ok(
      document.querySelector('[data-test-subj=euiSheetFlash]'),
      'the filled cells flash'
    );
  });

  test('RF2 the selected tint wins over the row hover (a range dragged in one row shows)', async function (assert) {
    // hover cannot be forced in a test: check the rules
    await renderSheet(tallFields(), tallRows(2, 2));
    const style = document.querySelector('style[data-eui-sheet]');
    const selectors = Array.from(
      (style as HTMLStyleElement | null)?.sheet?.cssRules ?? []
    ).map((rule) => (rule as CSSStyleRule).selectorText ?? '');
    for (const selected of [
      '.euiSheet__cell--selected',
      '.euiSheet__rowCell--selected'
    ]) {
      assert.true(
        selectors.some((text) =>
          text
            .split(',')
            .some(
              (part) =>
                part.includes('.euiDataGridRow:hover') &&
                part.includes(selected) &&
                !part.includes('--frozen')
            )
        ),
        `a rule with .euiDataGridRow:hover and ${selected}`
      );
      assert.true(
        selectors.some((text) =>
          text
            .split(',')
            .some(
              (part) =>
                part.includes('.euiDataGridRow:hover') &&
                part.includes(selected) &&
                part.includes('--frozen')
            )
        ),
        `and its frozen variant`
      );
    }
  });
  /* The shortcut list (V03 5.5) */

  async function renderWithList(
    options: {
      canInsert?: boolean;
      readOnly?: boolean;
      messages?: Record<string, () => string>;
    } = {}
  ): Promise<{ api: SheetApi | null }> {
    const store = localRecords<Row>(tallRows(3, 3), {
      getRecordId: getId,
      fields: tallFields()
    });
    const holder: { api: SheetApi | null } = { api: null };
    const register = (api: SheetApi) => (holder.api = api);
    const canInsert = options.canInsert;
    const readOnly = options.readOnly;
    const messages = options.messages;
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @records={{store.records}}
            @fields={{store.fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @canInsert={{canInsert}}
            @readOnly={{readOnly}}
            @messages={{messages}}
            @registerApi={{register}}
          >
            <:toolbar as |sheet|>
              <button
                type="button"
                data-test-shortcuts
                {{on "click" sheet.showShortcuts}}
              >Shortcuts</button>
            </:toolbar>
          </EuiSheet>
        </div>
      </template>
    );
    return holder;
  }

  const list = () =>
    document.querySelector<HTMLElement>('[data-test-subj=euiSheetShortcuts]');
  const rowTexts = () =>
    Array.from(
      document.querySelectorAll<HTMLElement>(
        '[data-test-subj=euiSheetShortcutText]'
      )
    ).map((element) => element.textContent?.trim() ?? '');

  test('KH1 Ctrl+/ on a cell opens the list; Escape closes it and the cell has focus again', async function (assert) {
    await renderWithList();
    await focusCell(1, 1);
    assert.true(await pressed('/', { ctrlKey: true }), 'the sheet’s key');
    await waitUntil(() => list());
    assert.dom(list()).includesText('Keyboard shortcuts');
    assert.true(rowTexts().includes('Fill down'), 'lists the keyboard docs');
    assert.true(rowTexts().includes('Add a record below'));
    assert.dom(list()!.querySelector('kbd')).exists('keys drawn as kbd');
    assert.true(
      list()!.classList.toString().includes('euiSheetTheme'),
      'the sheet’s theme class (portaled)'
    );
    await triggerEvent(document.activeElement!, 'keydown', { key: 'Escape' });
    await waitUntil(() => !list());
    await waitUntil(() => document.activeElement === cell(1, 1));
    assert.strictEqual(document.activeElement, cell(1, 1), 'focus is back');
    // Cmd+/ and a Shift+7 layout (key "/") too; on a header as well
    assert.true(await pressed('/', { metaKey: true, shiftKey: true }));
    await waitUntil(() => list());
    await click(el('.euiModal__closeIcon'));
    await waitUntil(() => !list());
    await focus(el('[role=columnheader][data-gridcell-column-index="1"]'));
    assert.true(await pressed('/', { ctrlKey: true }), 'on a header');
    await waitUntil(() => list());
    assert.ok(list());
  });

  test('KH2 rows of features that are off are left out; @messages overrides a text', async function (assert) {
    await renderWithList({
      canInsert: false,
      messages: { shortcutFillDown: () => 'Rellenar hacia abajo' }
    });
    await focusCell(0, 0);
    await pressed('/', { ctrlKey: true });
    await waitUntil(() => list());
    const texts = rowTexts();
    assert.false(texts.includes('Add a record below'), 'no insert rows');
    assert.false(texts.includes('Add a record (on the add row)'));
    assert.true(texts.includes('Rellenar hacia abajo'), '@messages');
    assert.true(texts.includes('Copy'));
    await click(el('.euiModal__closeIcon'));

    await renderWithList({ readOnly: true });
    await focusCell(0, 0);
    await pressed('/', { ctrlKey: true });
    await waitUntil(() => list());
    assert.false(rowTexts().includes('Edit the cell'), '@readOnly: no editing');
    assert.false(rowTexts().includes('Paste'));
    assert.true(rowTexts().includes('Copy'));
  });

  test('KH3 api.showShortcuts() and the block’s showShortcuts open the list', async function (assert) {
    const holder = await renderWithList();
    holder.api!.showShortcuts();
    await waitUntil(() => list());
    assert.ok(list(), 'the API');
    await click(el('.euiModal__closeIcon'));
    await waitUntil(() => !list());
    await click(el('[data-test-shortcuts]'));
    await waitUntil(() => list());
    assert.ok(list(), 'the block');
  });

  test('KH4 "/" and "?" typed on a text cell still open the editor', async function (assert) {
    await renderWithList();
    for (const key of ['/', '?']) {
      await focusCell(0, 1);
      assert.true(await pressed(key), `${key} is the sheet’s`);
      assert.ok(editorFrame(), `${key} opens the editor`);
      assert.strictEqual(list(), null, 'not the list');
      await press('Escape');
    }
  });
});
