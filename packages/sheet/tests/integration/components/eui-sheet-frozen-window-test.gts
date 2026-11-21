/**
 * The frozen grid's columns (READINESS-RESULTS.md, "Performance: the frozen
 * grid and more"): while a field is frozen the grid renders the leading
 * columns (the row numbers and the frozen fields) and the columns in view,
 * not every column. 12 fields of 150 px at a 600 px width, 200 records,
 * as in the frozen field's tests (FZ). Positions are compared in screen px.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import {
  click,
  focus,
  render,
  settled,
  triggerEvent
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import {
  clipboard,
  editor,
  editorFrame,
  el,
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
import type { SheetApi } from '#src/types.ts';

type Row = Record<string, string | number>;

const fieldsOf = (count: number): EuiSheetField<Row>[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `f${i}`,
    label: `Field ${i}`,
    width: 150
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
  @tracked rowNumbers = true;
  @tracked summary: Record<string, string> | undefined = undefined;
  @tracked groups: SheetGroup[] | undefined = undefined;
  @tracked records: Row[] = rowsOf(200, 12);
  @tracked fields = fieldsOf(12);
  @tracked fieldWidths: Record<string, number> | undefined = undefined;
  @tracked fullScreen: boolean | undefined = undefined;
  @tracked expandedId: string | number | null = null;
  groupBy: SheetGroupBy[] | undefined = undefined;
  api: SheetApi | null = null;
  changes: ChangeSet[] = [];
  onChange = (changeSet: ChangeSet) => this.changes.push(changeSet);
  onFieldOrderChange = (ids: string[]) => {
    const byId = new Map(this.fields.map((field) => [field.id, field]));
    this.fields = ids.map((id) => byId.get(id)!);
  };
  onFieldWidthChange = (id: string, width: number) => {
    this.fieldWidths = { ...this.fieldWidths, [id]: width };
  };
  registerApi = (api: SheetApi) => (this.api = api);
}

function outer(): HTMLElement {
  return el('.euiDataGrid__virtualized');
}

/** Waits a frame: the grid renders the new column window after the scroll. */
async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await settled();
}

async function frames(count: number): Promise<void> {
  for (let i = 0; i < count; i++) await frame();
}

async function scrollGrid(left: number, top?: number): Promise<void> {
  const element = outer();
  element.scrollLeft = left;
  if (top !== undefined) element.scrollTop = top;
  await triggerEvent(element, 'scroll');
  await frame();
}

/** The scrolled far right: the last column in view. */
async function scrollFarRight(): Promise<void> {
  await scrollGrid(outer().scrollWidth);
}

const rect = (element: Element) => element.getBoundingClientRect();

/** A body cell by the grid's column index (row numbers included), or null when not rendered. */
function at(row: number, gridCol: number): HTMLElement | null {
  return document.querySelector<HTMLElement>(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${gridCol}"]:not(.euiDataGridFooterCell)`
  );
}

function must(row: number, gridCol: number): HTMLElement {
  const found = at(row, gridCol);
  if (!found) throw new Error(`cell ${row}:${gridCol} is not rendered`);
  return found;
}

/** The grid column indices of a row's cells, in DOM order. */
function columnsOf(row: number): number[] {
  const element = el(`.euiDataGridRow[data-grid-visible-row-index="${row}"]`);
  return [...element.querySelectorAll<HTMLElement>('[role=gridcell]')].map(
    (child) => Number(child.dataset['gridcellColumnIndex'])
  );
}

function headerCell(gridCol: number): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-index="${gridCol}"]`);
}

/** The scroll element's visible area in screen px (inside its scroll bars). */
function viewArea(): { left: number; right: number } {
  const element = outer();
  const box = rect(element);
  const scale = element.offsetWidth ? box.width / element.offsetWidth : 1;
  const left = box.left + element.clientLeft * scale;
  return { left, right: left + element.clientWidth * scale };
}

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
 * Every column whose header is in view right of `from` has its body cell
 * in `row` at the header's left, and the leading `leading` columns come
 * first in the row.
 */
function assertWindow(
  assert: Assert,
  row: number,
  leading: number,
  from: number,
  label: string
): void {
  const columns = columnsOf(row);
  assert.deepEqual(
    columns.slice(0, leading),
    Array.from({ length: leading }, (_, i) => i),
    `${label}: the leading columns first`
  );
  assert.deepEqual(
    columns,
    [...columns].sort((a, b) => a - b),
    `${label}: ascending, each once`
  );
  const view = viewArea();
  const headers = [
    ...document.querySelectorAll<HTMLElement>('[role=columnheader]')
  ];
  let checked = 0;
  for (const header of headers) {
    const gridCol = Number(header.dataset['gridcellColumnIndex']);
    if (gridCol < leading) continue;
    const box = rect(header);
    if (box.right <= from + 1 || box.left >= view.right - 1) continue;
    const body = at(row, gridCol);
    assert.ok(body, `${label}: column ${gridCol} in view is rendered`);
    if (body) close(assert, rect(body).left, box.left, `${label}: ${gridCol}`);
    checked++;
  }
  assert.true(checked >= 2, `${label}: ${checked} columns in view checked`);
}

module(
  'Integration | Component | EuiSheet frozen columns window',
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      // elementFromPoint needs the container on screen
      document.getElementById('ember-testing-container')?.scrollIntoView();
    });

    async function renderSheet(state: State, width = 600): Promise<void> {
      const style = htmlSafe(`width:${width}px`);
      await render(
        <template>
          <div style={{style}}>
            <EuiSheet
              @fields={{state.fields}}
              @records={{state.records}}
              @groups={{state.groups}}
              @groupBy={{state.groupBy}}
              @getRecordId={{getId}}
              @onChange={{state.onChange}}
              @frozenFields={{state.frozenFields}}
              @rowNumbers={{state.rowNumbers}}
              @summary={{state.summary}}
              @fieldWidths={{state.fieldWidths}}
              @onFieldWidthChange={{state.onFieldWidthChange}}
              @onFieldOrderChange={{state.onFieldOrderChange}}
              @fullScreen={{state.fullScreen}}
              @expandedRecordId={{state.expandedId}}
              @registerApi={{state.registerApi}}
              @height={{400}}
            />
          </div>
        </template>
      );
    }

    for (const [frozen, rowNumbers] of [
      [1, true],
      [2, true],
      [1, false],
      [2, false]
    ] as const) {
      test(`FV1 ${frozen} frozen, row numbers ${rowNumbers ? 'on' : 'off'}: scrolled far right, the frozen cells stay at the left edge, side by side, and every column in view is rendered`, async function (assert) {
        const state = new State();
        state.frozenFields = frozen;
        state.rowNumbers = rowNumbers;
        await renderSheet(state);
        const leading = frozen + (rowNumbers ? 1 : 0);
        const lefts = Array.from(
          { length: leading },
          (_, i) => rect(must(3, i)).left
        );
        await scrollFarRight();
        assert.true(outer().scrollLeft > 1000, 'scrolled far right');
        for (let i = 0; i < leading; i++) {
          close(assert, rect(must(3, i)).left, lefts[i]!, `column ${i} stays`);
          assert.true(
            must(3, i).contains(atCentre(must(3, i))),
            `column ${i} paints over the scrolled cells`
          );
          if (i > 0) {
            close(
              assert,
              rect(must(3, i)).left,
              rect(must(3, i - 1)).right,
              `column ${i} right of column ${i - 1}`
            );
          }
          close(
            assert,
            rect(headerCell(i)).left,
            rect(must(3, i)).left,
            `header ${i} with its cells`
          );
        }
        const edge = rect(must(3, leading - 1)).right;
        assertWindow(assert, 3, leading, edge, 'far right');
        assert.strictEqual(
          at(3, leading + 1),
          null,
          'a column scrolled out to the left is not rendered'
        );
        // and back: every column of the start is there again
        await scrollGrid(0);
        assertWindow(assert, 3, leading, edge, 'back at the start');
      });
    }

    test('FV2 freezing while scrolled right, and from one to two frozen fields', async function (assert) {
      const state = new State();
      state.frozenFields = 0;
      await renderSheet(state);
      const number = rect(must(3, 0)).left;
      await scrollGrid(900);
      assert.strictEqual(
        at(3, 0),
        null,
        'not frozen: the row numbers are virtualized'
      );
      state.frozenFields = 1;
      await frames(2);
      close(
        assert,
        rect(must(3, 0)).left,
        number,
        'the row numbers at the edge'
      );
      close(
        assert,
        rect(must(3, 1)).left,
        rect(must(3, 0)).right,
        'the first field'
      );
      assertWindow(assert, 3, 2, rect(must(3, 1)).right, 'one frozen');
      state.frozenFields = 2;
      await frames(2);
      close(
        assert,
        rect(must(3, 2)).left,
        rect(must(3, 1)).right,
        'the second field'
      );
      assert.true(must(3, 2).contains(atCentre(must(3, 2))), 'painted over');
      assertWindow(assert, 3, 3, rect(must(3, 2)).right, 'two frozen');
      state.frozenFields = 0;
      await frames(2);
      assert.strictEqual(at(3, 0), null, 'unfrozen: virtualized again');
    });

    test('FV3 groups: the header rows and the records while scrolled far right', async function (assert) {
      const state = new State();
      state.groupBy = [{ field: 'f1', direction: 'asc' }];
      state.records = rowsOf(40, 12);
      state.groups = [0, 1].map((g) => ({
        key: `g${g}`,
        depth: 0,
        value: `G${g}`,
        label: `Group ${g}`,
        count: 20,
        loaded: 20
      }));
      await renderSheet(state);
      await scrollFarRight();
      // grid rows: header 0, records 1-20, header 21, records 22-41
      assertWindow(assert, 2, 2, rect(must(2, 1)).right, 'a record row');
      const header = el('.euiDataGridRow[data-grid-row-index="0"]');
      const labels = [
        ...header.querySelectorAll<HTMLElement>(
          '[data-test-subj=euiSheetGroupLabel]'
        )
      ].filter(
        (label) =>
          getComputedStyle(label).display !== 'none' && rect(label).width > 0
      );
      assert.strictEqual(labels.length, 1, 'one label shown');
      const label = labels[0]!;
      assert.true(label.textContent!.includes('Group 0'), 'its text');
      const box = rect(label);
      const view = viewArea();
      assert.true(
        box.left >= view.left - 1 && box.right <= view.right + 1,
        'in view'
      );
      assert.true(
        label.contains(
          document.elementFromPoint(box.left + 4, box.top + box.height / 2)
        ),
        'painted, not covered'
      );
      assert.strictEqual(
        (header.firstElementChild as HTMLElement).dataset[
          'gridcellColumnIndex'
        ],
        '0',
        'the row-number cell is the header row’s first cell'
      );
    });

    test('FV4 the summary footer and the add row while scrolled far right', async function (assert) {
      const state = new State();
      state.records = rowsOf(5, 12);
      state.summary = { '': '5', f0: 'first', f11: 'last' };
      await renderSheet(state);
      await frame();
      const footer = (gridCol: number) =>
        el(`.euiDataGridFooterCell[data-gridcell-column-index="${gridCol}"]`);
      const first = rect(footer(1)).left;
      await scrollFarRight();
      close(
        assert,
        rect(footer(1)).left,
        first,
        'the frozen footer cell stays'
      );
      assert.true(footer(1).contains(atCentre(footer(1))), 'painted over');
      assert.dom('.euiSheet__summary', footer(12)).hasText('last');
      const view = viewArea();
      assert.true(rect(footer(12)).right <= view.right + 1, 'the last in view');
      // the add row (grid row 5): its text in the frozen first field
      const add = el('[data-test-subj=euiSheetAddRecord]');
      const box = rect(add);
      assert.true(box.width > 0 && box.left >= view.left - 1, 'the add text');
      assert.true(add.contains(atCentre(add)), 'painted');
      assertWindow(assert, 5, 2, rect(must(5, 1)).right, 'the add row');
    });

    test('FV5 a range across the frozen edge, scrolled far right: the outline ends at the edge, copy gets every cell', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focus(must(2, 1));
      for (let i = 0; i < 3; i++) await press('ArrowRight', { shiftKey: true });
      await press('ArrowDown', { shiftKey: true });
      await press('ArrowDown', { shiftKey: true });
      await frames(2);
      const outline = () => {
        const clip = el('[data-test-subj=euiSheetRangeOutline]');
        return clip.style.display === 'none'
          ? null
          : (clip.firstElementChild as HTMLElement);
      };
      const near = must(2, 4);
      close(assert, rect(outline()!).right, rect(near).right, 'at the start');
      await scrollFarRight();
      await frames(2);
      const frozenCell = must(3, 1);
      assert.ok(outline(), 'still drawn over the frozen cells');
      close(
        assert,
        rect(outline()!).right,
        rect(frozenCell).right,
        'its right side at the frozen edge'
      );
      close(
        assert,
        rect(outline()!).left,
        rect(must(2, 1)).left,
        'its left side'
      );
      close(assert, rect(outline()!).top, rect(must(2, 1)).top, 'its top');
      close(
        assert,
        rect(outline()!).bottom,
        rect(must(4, 1)).bottom,
        'its bottom'
      );
      assert.dom(frozenCell).hasClass('euiSheet__cell--selected');
      // the focus moved with the arrows: it is on 4:3 (the grid's column 4)
      assert.deepEqual(
        selected().filter((pos) => pos.endsWith(':0')),
        ['2:0', '3:0', '4:0'],
        'the frozen column drawn selected'
      );
      await scrollGrid(0);
      await frames(2);
      close(assert, rect(outline()!).right, rect(must(2, 4)).right, 'back');
      const { text } = await clipboard('copy', '', document.activeElement!);
      assert.strictEqual(
        text,
        [2, 3, 4]
          .map((r) => [0, 1, 2, 3].map((c) => `r${r}c${c}`).join('\t'))
          .join('\n'),
        'copy: every cell of the range'
      );
    });

    test('FV6 the focused cell scrolled out sideways: the frozen grid does what the unfrozen one does', async function (assert) {
      // what happens while the focused cell (a scrolled one) is out of view:
      // where focus is, whether typing opens an editor and what a copy gives
      const observe = async (frozen: number) => {
        const state = new State();
        state.frozenFields = frozen;
        await renderSheet(state);
        await focus(must(2, 4));
        await frame();
        await scrollFarRight();
        await frames(2);
        const active = document.activeElement;
        const where =
          !active || active === document.body
            ? 'body'
            : active.closest('[role=gridcell]')
              ? `cell ${(active.closest('[role=gridcell]') as HTMLElement).dataset['gridcellColumnIndex']}`
              : active.closest('.euiSheet')
                ? 'in the sheet'
                : 'elsewhere';
        const { text } = await clipboard(
          'copy',
          '',
          document.activeElement ?? document.body
        );
        await type('z');
        const editing = !!editorFrame();
        if (editing) await press('Escape');
        await scrollGrid(0);
        await frames(2);
        return {
          where,
          copy: text,
          editing,
          back: document.activeElement === must(2, 4),
          selection: selected().join(' ')
        };
      };
      const plain = await observe(0);
      const frozen = await observe(1);
      assert.deepEqual(
        frozen,
        plain,
        `the same as unfrozen: ${JSON.stringify(plain)}`
      );
    });

    for (const frozen of [0, 1] as const) {
      test(`FV7 a focused cell scrolled out sideways and back (frozen ${frozen}): focus comes back to it, typing edits it`, async function (assert) {
        const state = new State();
        state.frozenFields = frozen;
        await renderSheet(state);
        await focus(must(2, 4));
        await frame();
        assert.strictEqual(document.activeElement, must(2, 4), 'focused');
        await scrollFarRight();
        await frames(2);
        // (the selected cell is not rendered now: no cell is drawn selected)
        await scrollGrid(0);
        await frames(2);
        assert.strictEqual(
          document.activeElement,
          must(2, 4),
          'focus is on the cell again'
        );
        await type('x');
        assert.ok(editor(), 'typing opens its editor');
        assert.strictEqual(editor()!.value, 'x');
        await press('Enter');
        assert.deepEqual(state.changes[0]?.patches, [
          { recordId: 2, fieldId: 'f3', from: 'r2c3', to: 'x' }
        ]);
      });

      test(`FV8 an open editor and a sideways scroll (frozen ${frozen})`, async function (assert) {
        const state = new State();
        state.frozenFields = frozen;
        await renderSheet(state);
        await focus(must(2, 4));
        await frame();
        await type('y');
        assert.ok(editorFrame(), 'editing');
        await scrollFarRight();
        await frames(2);
        assert.strictEqual(editorFrame(), null, 'a scroll closes it');
        assert.deepEqual(
          state.changes.map((change) => change.patches),
          [[{ recordId: 2, fieldId: 'f3', from: 'r2c3', to: 'y' }]],
          'and saves it'
        );
      });
    }

    test('FV9 ArrowRight from the frozen field into the first scrolled column while scrolled far right', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await scrollFarRight();
      const before = outer().scrollLeft;
      await click(must(5, 1));
      await frames(2);
      assert.strictEqual(
        outer().scrollLeft,
        before,
        'a click on the frozen cell keeps the scroll'
      );
      await press('ArrowRight');
      await frames(3);
      const next = must(5, 2);
      assert.strictEqual(
        document.activeElement,
        next,
        'the second field has focus'
      );
      assert.true(
        rect(next).left >= rect(must(5, 1)).right - 0.5,
        'right of the frozen edge, not under it'
      );
      assert.deepEqual(selected(), ['5:1']);
      await press('ArrowLeft');
      await frames(2);
      assert.strictEqual(
        document.activeElement,
        must(5, 1),
        'back on the frozen field'
      );
      await press('End');
      await frames(3);
      assert.strictEqual(
        document.activeElement,
        must(5, 12),
        'End: the last field'
      );
      assertWindow(assert, 5, 2, rect(must(5, 1)).right, 'after End');
    });

    test('FV10 resize the frozen field and move a field while scrolled right', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await scrollGrid(600);
      const width = rect(must(3, 1)).width;
      const resizer = resizerOf(headerCell(1));
      // pageX is not an event init field: it follows clientX (as in FZ5)
      await triggerEvent(resizer, 'mousedown', { clientX: 300 });
      await triggerEvent(window as unknown as Element, 'mousemove', {
        clientX: 350
      });
      await triggerEvent(window as unknown as Element, 'mouseup');
      await frames(2);
      const grown = rect(must(3, 1)).width - width;
      assert.ok(grown > 10, `the frozen field is wider (${grown.toFixed(1)})`);
      close(
        assert,
        rect(must(3, 1)).width,
        rect(headerCell(1)).width,
        'the cells follow'
      );
      assertWindow(assert, 3, 2, rect(must(3, 1)).right, 'after the resize');
      // a move (as the field menu's "Move right" does): the order changes
      state.onFieldOrderChange([
        'f0',
        'f2',
        'f1',
        ...state.fields.slice(3).map((f) => f.id)
      ]);
      await frames(2);
      assertWindow(assert, 3, 2, rect(must(3, 1)).right, 'after the move');
      await scrollGrid(0);
      assert
        .dom('[data-datagrid-cellcontent]', must(3, 2))
        .hasText('r3c2', 'the moved field');
      assert.dom('[data-datagrid-cellcontent]', must(3, 3)).hasText('r3c1');
    });

    test('FV11 full screen while scrolled right: the wider grid renders the columns in view', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await scrollGrid(600);
      state.fullScreen = true;
      await frames(3);
      assert.dom('.euiSheet').exists();
      assertWindow(assert, 3, 2, rect(must(3, 1)).right, 'full screen');
      await scrollFarRight();
      assertWindow(
        assert,
        3,
        2,
        rect(must(3, 1)).right,
        'full screen, far right'
      );
      state.fullScreen = false;
      await frames(3);
      assertWindow(assert, 3, 2, rect(must(3, 1)).right, 'back');
    });

    test('FV12 the expanded record shows every field while the grid is scrolled far right', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await scrollFarRight();
      state.api!.expandRecord(3);
      await settled();
      const shell = el('[data-test-subj=euiSheetRecord]', document.body);
      for (const id of ['f0', 'f1', 'f6', 'f11']) {
        assert.ok(
          shell.querySelector(`[data-eui-sheet-record-box="${id}"]`),
          `the box of ${id}`
        );
      }
    });

    test('FV13 the fill handle on a scrolled cell and on the frozen cell, far right', async function (assert) {
      const state = new State();
      await renderSheet(state);
      const handle = () => {
        const element = document.querySelector<HTMLElement>(
          '[data-test-subj=euiSheetFillHandle]'
        );
        return element && element.style.display !== 'none' ? element : null;
      };
      const onCorner = (target: HTMLElement, label: string) => {
        const box = rect(target);
        const h = rect(handle()!);
        close(assert, h.left + h.width / 2, box.right, `${label}: x`);
        close(assert, h.top + h.height / 2, box.bottom, `${label}: y`);
      };
      await scrollFarRight();
      await click(must(3, 11));
      await frames(2);
      assert.ok(handle(), 'shown on the scrolled cell');
      onCorner(must(3, 11), 'scrolled cell');
      await click(must(4, 1));
      await frames(2);
      assert.ok(handle(), 'shown on the frozen cell');
      onCorner(must(4, 1), 'frozen cell');
      // a scrolled cell out of view: hidden; back in view: on its corner
      await click(must(5, 11));
      await scrollGrid(0);
      await frames(2);
      assert.strictEqual(
        handle(),
        null,
        'hidden while its cell is out of view'
      );
      await scrollFarRight();
      await frames(2);
      onCorner(must(5, 11), 'back');
    });

    test('FV14 the touch handles on a cell scrolled far right, and out of view', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await scrollFarRight();
      const tapCell = async (target: HTMLElement) => {
        const box = rect(target);
        const init = {
          bubbles: true,
          cancelable: true,
          pointerType: 'touch',
          isPrimary: true,
          pointerId: 7,
          clientX: box.left + box.width / 2,
          clientY: box.top + box.height / 2
        };
        target.dispatchEvent(new PointerEvent('pointerdown', init));
        target.dispatchEvent(new PointerEvent('pointerup', init));
        await focus(target);
      };
      const handles = () =>
        [
          ...document.querySelectorAll<HTMLElement>(
            '[data-test-subj=euiSheetSelectionHandle]'
          )
        ].filter((h) => h.style.display !== 'none');
      const target = must(3, 11);
      await tapCell(target);
      await frames(2);
      assert.strictEqual(handles().length, 2, 'two handles');
      const end = rect(el('[data-eui-sheet-handle=end]'));
      close(assert, end.left + end.width / 2, rect(target).right, 'end x');
      close(assert, end.top + end.height / 2, rect(target).bottom, 'end y');
      await scrollGrid(0);
      await frames(2);
      assert.strictEqual(handles().length, 0, 'hidden while out of view');
    });
  }
);
