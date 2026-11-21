/**
 * The frozen primary field (V02-DESIGN.md 9.3): sticky cells through
 * `setCellProps`, no grid change. 12 fields of 150 px at a 600 px width,
 * 200 records. Positions are compared in screen px (the test container is
 * scaled), so no scale is applied.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  focus,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import {
  cell,
  editorFrame,
  el,
  focusCell,
  press,
  resizerOf,
  selected,
  type
} from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  SheetGroup,
  SheetGroupBy
} from '#src/core/index.ts';

type Row = Record<string, string | number>;

const fieldsOf = (count: number, width?: number): EuiSheetField<Row>[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `f${i}`,
    label: `Field ${i}`,
    ...(width ? { width } : {})
  }));

const rowsOf = (count: number, fields: number): Row[] =>
  Array.from({ length: count }, (_, r) => {
    const row: Row = { id: r };
    for (let f = 0; f < fields; f++) row[`f${f}`] = `r${r}c${f}`;
    return row;
  });

const getId = (row: Row) => row['id']!;

class State {
  @tracked frozenFields: number | undefined = 1;
  @tracked summary: Record<string, string> | undefined = undefined;
  @tracked records: Row[] = rowsOf(200, 12);
  @tracked fields = fieldsOf(12, 150);
  changes: ChangeSet[] = [];
  onChange = (changeSet: ChangeSet) => this.changes.push(changeSet);
}

/** FZ13: the groups passed to the sheet, or none. */
class GroupView {
  @tracked groups: SheetGroup[] | undefined = undefined;
}

type Measured = { ms: number; cells: number; headers: number };

function outer(): HTMLElement {
  return el('.euiDataGrid__virtualized');
}

async function scrollGrid(left: number, top?: number): Promise<void> {
  const element = outer();
  element.scrollLeft = left;
  if (top !== undefined) element.scrollTop = top;
  await triggerEvent(element, 'scroll');
}

function rowNumberCell(row: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
  );
}

function headerCell(colIndex: number): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-index="${colIndex}"]`);
}

function footerCell(colIndex: number): HTMLElement {
  return el(`.euiDataGridFooterCell[data-gridcell-column-index="${colIndex}"]`);
}

const rect = (element: Element) => element.getBoundingClientRect();

/** The element painted at an element's centre. */
function atCentre(element: Element): Element | null {
  const box = rect(element);
  return document.elementFromPoint(
    box.left + box.width / 2,
    box.top + box.height / 2
  );
}

function close(
  assert: Assert,
  actual: number,
  expected: number,
  message: string
): void {
  assert.ok(
    Math.abs(actual - expected) < 1,
    `${message} (${actual.toFixed(1)} vs ${expected.toFixed(1)})`
  );
}

/**
 * A measurement. The TAP log prints only failed assertions, so a run with
 * `report` in the page's query (`tests/index.html?report`) pushes it as a
 * failure to get it into the log; a normal run only checks it is a number.
 */
function report(assert: Assert, text: string): void {
  if (new URLSearchParams(location.search).has('report')) {
    assert.pushResult({
      result: false,
      actual: text,
      expected: 'reported',
      message: text
    });
  }
}

/** Waits a frame: the sheet's focus correction runs after the grid's own scroll. */
async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await settled();
}

module('Integration | Component | EuiSheet frozen field', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    // elementFromPoint needs the container on screen
    document.getElementById('ember-testing-container')?.scrollIntoView();
  });

  async function renderSheet(state: State): Promise<void> {
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @fields={{state.fields}}
            @records={{state.records}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @frozenFields={{state.frozenFields}}
            @summary={{state.summary}}
            @height={{400}}
          />
        </div>
      </template>
    );
  }

  test('FZ1 the row number and the first field stay in place on horizontal scroll', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const number = rect(rowNumberCell(3));
    const first = rect(cell(3, 0));
    await scrollGrid(700);
    assert.strictEqual(outer().scrollLeft, 700, 'scrolled');
    close(assert, rect(rowNumberCell(3)).left, number.left, 'row number left');
    close(assert, rect(cell(3, 0)).left, first.left, 'first field left');
    const other = rect(cell(3, 6));
    close(assert, rect(rowNumberCell(3)).top, other.top, 'row number top');
    close(assert, rect(cell(3, 0)).top, other.top, 'first field top');
    assert.strictEqual(
      cell(3, 0).style.position,
      'sticky',
      'the first field is sticky'
    );
    assert.notOk(
      cell(3, 6).style.position === 'sticky',
      'a scrolled field is not'
    );
  });

  test('FZ2 the frozen cell paints over the scrolled cells', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await scrollGrid(700);
    const frozen = cell(3, 0);
    const number = rowNumberCell(3);
    assert.true(
      frozen.contains(atCentre(frozen)),
      'elementFromPoint over the first field is in it'
    );
    assert.true(
      number.contains(atCentre(number)),
      'elementFromPoint over the row number is in it'
    );
    assert.notStrictEqual(
      getComputedStyle(frozen).backgroundColor,
      'rgba(0, 0, 0, 0)',
      'the frozen cell has an opaque background'
    );
  });

  test('FZ3 the frozen header cells stay, and stay above the body on vertical scroll', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const numberHeader = rect(headerCell(0));
    const firstHeader = rect(headerCell(1));
    await scrollGrid(700);
    close(
      assert,
      rect(headerCell(0)).left,
      numberHeader.left,
      'row-number header left'
    );
    close(
      assert,
      rect(headerCell(1)).left,
      firstHeader.left,
      'first header left'
    );
    close(assert, rect(headerCell(1)).top, firstHeader.top, 'first header top');
    await scrollGrid(700, 2000);
    close(
      assert,
      rect(headerCell(1)).top,
      firstHeader.top,
      'first header top after a vertical scroll'
    );
    close(
      assert,
      rect(headerCell(1)).left,
      firstHeader.left,
      'first header left after a vertical scroll'
    );
    assert.true(
      headerCell(1).contains(atCentre(headerCell(1))),
      'the first field header paints over the body'
    );
    assert.true(
      headerCell(0).contains(atCentre(headerCell(0))),
      'the row-number header paints over the body'
    );
    // a header right of the frozen ones (f7: 64 + 7 * 150 - 700 = 414 px in)
    assert.true(
      headerCell(8).contains(atCentre(headerCell(8))),
      'a scrolled header is in view'
    );
  });

  test('CD6 gate (V03 5.3): with column drag on, the frozen headers stick through their draggable wrappers', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert
      .dom('[data-test-subj=euiDataGridHeaderDroppable]')
      .exists('column drag is on');
    const wrapper = headerCell(1).closest<HTMLElement>(
      '.euiDataGridHeaderCellDraggable'
    )!;
    assert.ok(wrapper, 'the frozen header is in a draggable wrapper');
    assert.strictEqual(getComputedStyle(wrapper).position, 'sticky');
    const before = rect(headerCell(1));
    await scrollGrid(700);
    close(assert, rect(headerCell(1)).left, before.left, 'its left is kept');
    assert.true(
      headerCell(1).contains(atCentre(headerCell(1))),
      'it paints over the scrolled headers'
    );
    const background = getComputedStyle(headerCell(1)).backgroundColor;
    assert.true(
      /^rgb\(/.test(background),
      `its background is opaque (${background})`
    );
    assert.false(
      wrapper.contains(atCentre(headerCell(2))),
      'the next header is not frozen'
    );
  });

  test('FZ4 ArrowLeft never leaves the focused cell under the frozen columns', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await scrollGrid(outer().scrollWidth);
    await frame();
    await focusCell(3, 11);
    await frame();
    for (let col = 10; col >= 1; col--) {
      await press('ArrowLeft');
      await frame();
      const focused = document.activeElement as HTMLElement;
      assert.strictEqual(focused, cell(3, col), `focus is on column ${col}`);
      assert.ok(
        rect(focused).left >= rect(cell(3, 0)).right - 0.5,
        `column ${col}: left ${rect(focused).left.toFixed(1)} is right of the frozen edge ${rect(cell(3, 0)).right.toFixed(1)}`
      );
    }
    // scrolled while column 1 keeps focus: ArrowLeft into the frozen field
    // must not scroll back to its column's edge
    await scrollGrid(400);
    const scrolled = outer().scrollLeft;
    assert.strictEqual(scrolled, 400, 'scrolled');
    await press('ArrowLeft');
    await frame();
    assert.strictEqual(
      document.activeElement,
      cell(3, 0),
      'then the frozen field'
    );
    assert.strictEqual(
      outer().scrollLeft,
      scrolled,
      'moving into the frozen field keeps the scroll'
    );
    await press('ArrowRight');
    await frame();
    await press('Home');
    await frame();
    assert.strictEqual(
      document.activeElement,
      cell(3, 0),
      'Home: the first field'
    );
    assert.strictEqual(outer().scrollLeft, 0, 'Home scrolls to the left edge');
  });

  test('FZ5 resizing the frozen field moves the next cells and keeps it frozen', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const before = rect(cell(3, 1)).left;
    const width = rect(cell(3, 0)).width;
    const resizer = resizerOf(headerCell(1));
    // pageX is not an event init field: it follows clientX
    await triggerEvent(resizer, 'mousedown', { clientX: 300 });
    await triggerEvent(window as unknown as Element, 'mousemove', {
      clientX: 350
    });
    await triggerEvent(window as unknown as Element, 'mouseup');
    const grown = rect(cell(3, 0)).width - width;
    assert.ok(grown > 10, `the first field is wider (${grown.toFixed(1)})`);
    close(assert, rect(cell(3, 1)).left, before + grown, 'the next cell moved');
    const number = rect(rowNumberCell(3)).left;
    const first = rect(cell(3, 0)).left;
    await scrollGrid(700);
    close(assert, rect(rowNumberCell(3)).left, number, 'row number left');
    close(assert, rect(cell(3, 0)).left, first, 'first field left');
    close(
      assert,
      rect(cell(3, 0)).top,
      rect(cell(3, 6)).top,
      'first field top'
    );
    close(
      assert,
      rect(headerCell(1)).width,
      rect(cell(3, 0)).width,
      'the header has the same width'
    );
  });

  test('FZ6 type-to-edit on the frozen cell while scrolled: the editor covers it', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await scrollGrid(700);
    // a click (pointerup scrolls the focused cell into view; the sheet keeps the scroll)
    await click(cell(3, 0));
    await frame();
    const scrolled = outer().scrollLeft;
    await type('x');
    const frame_ = editorFrame();
    assert.ok(frame_, 'the editor is open');
    const box = rect(cell(3, 0));
    const editorBox = rect(frame_!);
    // V03 batch 1: the editor is lifted up to 2 px past the cell on each side
    const grows = (outerEdge: number, label: string) =>
      assert.true(
        outerEdge >= -0.5 && outerEdge <= 2.5,
        `${label} (${outerEdge.toFixed(1)} px past the cell)`
      );
    grows(box.left - editorBox.left, 'editor left');
    grows(box.top - editorBox.top, 'editor top');
    grows(editorBox.right - box.right, 'editor right');
    assert.true(
      frame_!.contains(atCentre(cell(3, 0))),
      'the editor is painted over the frozen cell'
    );
    assert.strictEqual(
      scrolled,
      700,
      'clicking the frozen cell keeps the horizontal scroll'
    );
    await press('Enter');
    assert.strictEqual(state.changes.length, 1, 'Enter saves');
    assert.deepEqual(
      state.changes[0]!.patches.map((p) => [p.recordId, p.fieldId, p.to]),
      [[3, 'f0', 'x']]
    );
  });

  test('FZ7 a range over frozen and scrolled cells is drawn selected on both', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await click(cell(3, 0));
    await click(cell(5, 2), { shiftKey: true });
    assert.deepEqual(selected(), [
      '3:0',
      '3:1',
      '3:2',
      '4:0',
      '4:1',
      '4:2',
      '5:0',
      '5:1',
      '5:2'
    ]);
    const frozen = getComputedStyle(cell(4, 0));
    assert.notStrictEqual(
      frozen.backgroundImage,
      'none',
      'the frozen cell draws the selection over its opaque background'
    );
    assert.notStrictEqual(
      getComputedStyle(cell(4, 1)).backgroundColor,
      'rgba(0, 0, 0, 0)',
      'a scrolled cell is drawn selected'
    );
  });

  test('FZ8 without @frozenFields (the default) or with 0: cells are absolute, columns virtualized again', async function (assert) {
    const state = new State();
    state.frozenFields = undefined;
    await renderSheet(state);
    assert.strictEqual(cell(3, 0).style.position, 'absolute');
    assert.strictEqual(rowNumberCell(3).style.position, 'absolute');
    assert.dom(cell(3, 0)).doesNotHaveClass('euiSheet__cell--frozen');
    assert
      .dom(
        `[role=gridcell][data-gridcell-visible-row-index="3"][data-gridcell-column-index="12"]`
      )
      .doesNotExist('the last column is not rendered (column window)');
    assert.dom(headerCell(1)).doesNotHaveClass('euiSheet__frozenHeader');

    state.frozenFields = 1;
    await settled();
    assert.strictEqual(cell(3, 0).style.position, 'sticky');
    assert
      .dom(
        `[role=gridcell][data-gridcell-visible-row-index="3"][data-gridcell-column-index="12"]`
      )
      .doesNotExist(
        'frozen: the last column is not rendered either (column window)'
      );
    await scrollGrid(outer().scrollWidth);
    assert
      .dom(
        `[role=gridcell][data-gridcell-visible-row-index="3"][data-gridcell-column-index="12"]`
      )
      .exists('frozen, scrolled to the end: the last column is rendered');
  });

  test('FZ9 vertical scroll over 10,000 rows with 30 fields, frozen on (time logged)', async function (assert) {
    const state = new State();
    state.fields = fieldsOf(30, 150);
    state.records = rowsOf(10_000, 30);
    await renderSheet(state);
    const on = await measure();
    assert.dom(cell(firstRenderedRow(), 0)).hasClass('euiSheet__cell--frozen');
    // the same with frozen fields off (column virtualization on), to compare
    state.frozenFields = 0;
    await settled();
    await scrollGrid(0, 0);
    await frame();
    const off = await measure();
    assert
      .dom(cell(firstRenderedRow(), 0))
      .doesNotHaveClass('euiSheet__cell--frozen');
    report(
      assert,
      `FZ9: frozen on ${on.ms.toFixed(1)} ms per scroll step, ${on.cells} cells rendered; off ${off.ms.toFixed(1)} ms, ${off.cells} cells`
    );
    assert.ok(on.ms > 0 && off.ms > 0);
    assert.strictEqual(
      on.cells,
      off.cells,
      'at the left edge the frozen columns are in the column window anyway: the same cells'
    );

    async function measure(): Promise<{ ms: number; cells: number }> {
      const steps = 20;
      const start = performance.now();
      for (let i = 1; i <= steps; i++) {
        await scrollGrid(0, i * 600);
        await frame();
      }
      return {
        ms: (performance.now() - start) / steps,
        cells: document.querySelectorAll('.euiDataGridRow [role=gridcell]')
          .length
      };
    }

    function firstRenderedRow(): number {
      const first = document.querySelector<HTMLElement>(
        '.euiDataGridRow [role=gridcell][data-gridcell-column-index="1"]'
      );
      return Number(first?.dataset['gridcellVisibleRowIndex']);
    }
  });

  test('FZ13 vertical scroll over 10,000 records in 200 groups with 30 fields: grouped against ungrouped, frozen off and on (time logged)', async function (assert) {
    // four variants, interleaved over rounds, the fastest round of each:
    // a loaded machine slows a round, not a variant
    assert.timeout(300_000);
    const state = new State();
    state.fields = fieldsOf(30, 150);
    state.records = rowsOf(10_000, 30);
    const groups: SheetGroup[] = Array.from({ length: 200 }, (_, g) => ({
      key: `g${g}`,
      depth: 0,
      value: `G${g}`,
      count: 50,
      loaded: 50
    }));
    const groupBy: SheetGroupBy[] = [{ field: 'f1', direction: 'asc' }];
    const view = new GroupView();
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @fields={{state.fields}}
            @records={{state.records}}
            @groups={{view.groups}}
            @groupBy={{groupBy}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @frozenFields={{state.frozenFields}}
            @height={{400}}
          />
        </div>
      </template>
    );
    type Variant = { grouped: boolean; frozen: number };
    const variants: Variant[] = [
      { grouped: false, frozen: 0 },
      { grouped: true, frozen: 0 },
      { grouped: false, frozen: 1 },
      { grouped: true, frozen: 1 }
    ];
    const best = variants.map(() => ({ ms: Infinity, cells: 0, headers: 0 }));
    for (let round = 0; round < 2; round++) {
      for (const [i, variant] of variants.entries()) {
        view.groups = variant.grouped ? groups : undefined;
        state.frozenFields = variant.frozen;
        await settled();
        await scrollGrid(0, 0);
        await frame();
        const result = await measure();
        if (result.ms < best[i]!.ms) best[i] = result;
      }
    }
    const [plainOff, groupedOff, plainOn, groupedOn] = best as [
      Measured,
      Measured,
      Measured,
      Measured
    ];
    const line = (name: string, m: Measured) =>
      `${name} ${m.ms.toFixed(1)} ms, ${m.cells} cells, ${m.headers} header rows`;
    report(
      assert,
      `FZ13 per scroll step: ${line('frozen off, ungrouped', plainOff)}; ${line('grouped', groupedOff)}; ${line('frozen on, ungrouped', plainOn)}; ${line('grouped', groupedOn)}`
    );
    // logged, not asserted (V03 8.10), like FZ9: a timing ratio fails on a
    // loaded machine (1.8-2x seen with another browser busy, 0.75-1.26x
    // quiet)
    assert.ok(groupedOff.headers > 0, 'header rows were rendered');
    assert.ok(groupedOn.headers > 0, 'and with frozen fields');
    assert.ok(
      [plainOff, groupedOff, plainOn, groupedOn].every(
        (m) => Number.isFinite(m.ms) && m.ms > 0
      ),
      'every variant was measured'
    );

    async function measure(): Promise<Measured> {
      const steps = 20;
      let headers = 0;
      const start = performance.now();
      for (let i = 1; i <= steps; i++) {
        await scrollGrid(0, i * 600);
        await frame();
        headers += document.querySelectorAll('.euiSheet__groupRow').length;
      }
      return {
        ms: (performance.now() - start) / steps,
        cells: document.querySelectorAll('.euiDataGridRow [role=gridcell]')
          .length,
        headers
      };
    }
  });

  test('FZ10 the summary bar: frozen footer cells keep their left and paint over the scrolled ones', async function (assert) {
    const state = new State();
    state.summary = { '': '200', f0: 'first', f6: 'sixth' };
    await renderSheet(state);
    await waitUntil(() => document.querySelector('.euiDataGridFooterCell'));
    const number = rect(footerCell(0));
    const first = rect(footerCell(1));
    await scrollGrid(700);
    close(
      assert,
      rect(footerCell(0)).left,
      number.left,
      'row-number footer left'
    );
    close(assert, rect(footerCell(1)).left, first.left, 'first footer left');
    close(
      assert,
      rect(footerCell(1)).top,
      rect(footerCell(7)).top,
      'same row as a scrolled footer cell'
    );
    assert.true(
      footerCell(1).contains(atCentre(footerCell(1))),
      'the first field footer paints over the scrolled ones'
    );
    assert.true(
      footerCell(0).contains(atCentre(footerCell(0))),
      'the row-number footer paints over the scrolled ones'
    );
    assert.dom('.euiSheet__summary', footerCell(1)).hasText('first');
    assert.dom('.euiSheet__summary', footerCell(0)).hasText('200');
  });

  test('FZ11 above 50 visible fields the sheet does not freeze', async function (assert) {
    const state = new State();
    state.fields = fieldsOf(51, 100);
    state.records = rowsOf(20, 51);
    await renderSheet(state);
    assert.dom(cell(3, 0)).doesNotHaveClass('euiSheet__cell--frozen');
    assert.strictEqual(cell(3, 0).style.position, 'absolute');
    state.fields = fieldsOf(50, 100);
    await settled();
    assert.dom(cell(3, 0)).hasClass('euiSheet__cell--frozen', '50 is fine');
  });

  test('FZ12 two frozen fields without row numbers; a drag from a frozen cell keeps the scroll', async function (assert) {
    const state = new State();
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @fields={{state.fields}}
            @records={{state.records}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @frozenFields={{2}}
            @rowNumbers={{false}}
            @height={{400}}
          />
        </div>
      </template>
    );
    // no row-number column: the grid's column index is the field's
    const at = (row: number, col: number) =>
      el(
        `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${col}"]`
      );
    const first = rect(at(3, 0)).left;
    const second = rect(at(3, 1)).left;
    assert.ok(second > first, 'side by side');
    await scrollGrid(700);
    close(assert, rect(at(3, 0)).left, first, 'first field left');
    close(assert, rect(at(3, 1)).left, second, 'second field left');
    close(assert, rect(at(3, 1)).top, rect(at(3, 6)).top, 'same row');
    assert.true(at(3, 1).contains(atCentre(at(3, 1))), 'painted over');
    assert.dom(at(3, 1)).hasClass('euiSheet__frozenEdge');
    assert.dom(at(3, 0)).doesNotHaveClass('euiSheet__frozenEdge');
    close(
      assert,
      rect(headerCell(1)).left,
      rect(at(3, 1)).left,
      'the second header stays with its cells'
    );

    // ArrowLeft from the last field to the third: never under the frozen two
    await scrollGrid(outer().scrollWidth);
    await frame();
    await focus(at(3, 11));
    await frame();
    for (let col = 10; col >= 2; col--) {
      await press('ArrowLeft');
      await frame();
      assert.ok(
        rect(document.activeElement!).left >= rect(at(3, 1)).right - 0.5,
        `column ${col} is right of the frozen edge`
      );
    }

    // a drag that starts on a frozen cell while scrolled: the grid scrolls
    // the pressed cell into view on pointerup, the sheet scrolls back
    await scrollGrid(500);
    const outerElement = outer();
    await triggerEvent(at(5, 0), 'pointerdown', { button: 0 });
    await triggerEvent(at(5, 0), 'mousedown', { button: 0 });
    await focus(at(5, 0));
    // f6 is at 900-1050 px: in view right of the frozen 300 px at scroll 500
    await triggerEvent(at(5, 6), 'mouseover');
    await triggerEvent(document.body, 'pointerup', { button: 0 });
    await triggerEvent(document.body, 'mouseup', { button: 0 });
    await triggerEvent(at(5, 6), 'click', { button: 0 });
    await frame();
    assert.strictEqual(outerElement.scrollLeft, 500, 'the scroll is kept');
    assert.strictEqual(
      document.activeElement,
      at(5, 0),
      'focus stays on the anchor (V03 batch 1)'
    );
  });
});
