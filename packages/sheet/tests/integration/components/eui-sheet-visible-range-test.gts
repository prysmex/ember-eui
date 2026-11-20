/**
 * The records on screen (v0.4 09, VR1-VR5): `@onVisibleRangeChange`,
 * called after render with positions in `@records`, for loading more as
 * the user scrolls.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled, triggerEvent } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { cell, el, focusCell, press } from '../../helpers/sheet.ts';

import type { EuiSheetField, SheetGroup } from '#src/core/index.ts';
import type { SheetVisibleRange } from '#src/types.ts';

type Row = Record<string, string | number>;

const fieldsOf = (count: number, width = 150): EuiSheetField<Row>[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `f${i}`,
    label: `Field ${i}`,
    width
  }));

const rowsOf = (count: number, from = 0): Row[] =>
  Array.from({ length: count }, (_, i) => {
    const r = from + i;
    return { id: r, f0: `r${r}c0`, f1: `r${r}c1`, f2: `r${r}c2` };
  });

const getId = (row: Row) => row['id']!;

const line = (range: SheetVisibleRange) =>
  `${range.first}-${range.last}/${range.count}`;

class State {
  @tracked records: Row[] = rowsOf(200);
  @tracked fields = fieldsOf(3);
  @tracked groups: SheetGroup[] | undefined = undefined;
  @tracked frozenFields = 0;
  @tracked canInsert = true;
  calls: SheetVisibleRange[] = [];
  /** Called inside the handler, as an owner that loads more would. */
  then: ((range: SheetVisibleRange) => void) | null = null;
  onChange = () => {};
  onVisibleRangeChange = (range: SheetVisibleRange) => {
    this.calls.push(range);
    this.then?.(range);
  };
  get lines(): string[] {
    return this.calls.map(line);
  }
}

function outer(): HTMLElement {
  return el('.euiDataGrid__virtualized');
}

async function scrollGrid(top: number, left?: number): Promise<void> {
  const element = outer();
  element.scrollTop = top;
  if (left !== undefined) element.scrollLeft = left;
  await triggerEvent(element, 'scroll');
}

/** The grid's rows in the DOM, by row-number cell. */
function rowNumberCell(row: number): HTMLElement | null {
  return document.querySelector<HTMLElement>(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
  );
}

/** The height of one grid row in layout px (the test container is scaled). */
function rowHeight(): number {
  return rowNumberCell(0)?.offsetHeight ?? 0;
}

/**
 * The grid rows in view, from the layout: the rows that start in the body
 * (below the sticky header, above the scroller's bottom edge), as the grid
 * counts them (a row partly in view counts).
 */
function rowsInView(): { start: number; stop: number } {
  const scroller = outer();
  const box = scroller.getBoundingClientRect();
  const scale = box.height / scroller.offsetHeight;
  const header = el('.euiDataGridHeader').getBoundingClientRect();
  const top = header.bottom;
  const bottom = box.top + scroller.clientHeight * scale;
  const rows = Array.from(
    document.querySelectorAll<HTMLElement>(
      '[role=gridcell][data-gridcell-column-index="0"]'
    )
  )
    .filter((element) => {
      const rect = element.getBoundingClientRect();
      return rect.bottom > top + 0.5 && rect.top < bottom - 0.5;
    })
    .map((element) => Number(element.dataset['gridcellVisibleRowIndex']));
  return { start: Math.min(...rows), stop: Math.max(...rows) };
}

/** Waits a frame: the grid measures after it. */
async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await settled();
}

module('Integration | Component | EuiSheet visible range', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state: State, handler = true): Promise<void> {
    const onVisibleRangeChange = handler
      ? state.onVisibleRangeChange
      : undefined;
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @fields={{state.fields}}
            @records={{state.records}}
            @groups={{state.groups}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @canInsert={{state.canInsert}}
            @frozenFields={{state.frozenFields}}
            @onVisibleRangeChange={{onVisibleRangeChange}}
            @height={{400}}
          />
        </div>
      </template>
    );
    await frame();
  }

  test('VR1 the first render reports first 0 and the last record in view', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert.strictEqual(
      state.calls.length,
      1,
      `one call: ${state.lines.join(' ')}`
    );
    const view = rowsInView();
    assert.true(view.stop > 3 && view.stop < 100, `rows in view ${view.stop}`);
    assert.deepEqual(
      state.calls[0],
      { first: 0, last: view.stop, count: 200 },
      `${state.lines.join(' ')} against rows 0-${view.stop} in view`
    );
    assert.ok(rowNumberCell(view.stop + 1), 'the overscan row is rendered');
    // nothing changed: no call
    await frame();
    assert.strictEqual(state.calls.length, 1, 'still one call');
  });

  test('VR2 a scroll to the bottom reports last: count - 1, by a jump and by small steps', async function (assert) {
    for (const canInsert of [true, false]) {
      const state = new State();
      state.canInsert = canInsert;
      state.fields = fieldsOf(12);
      await renderSheet(state);
      const label = canInsert ? 'with the add row' : 'without the add row';
      const height = rowHeight();
      const max = () => outer().scrollHeight - outer().clientHeight;

      await scrollGrid(max());
      await frame();
      let last = state.calls[state.calls.length - 1]!;
      assert.strictEqual(last.last, 199, `${label}, a jump: ${line(last)}`);
      assert.strictEqual(last.count, 200, `${label}: count`);

      // a horizontal scroll only: the records on screen did not change
      const calls = state.calls.length;
      await scrollGrid(outer().scrollTop, 700);
      await frame();
      assert.strictEqual(outer().scrollLeft, 700, `${label}: scrolled right`);
      assert.strictEqual(
        state.calls.length,
        calls,
        `${label}: no call on a horizontal scroll`
      );

      // back up, then down to the end by 3 px steps
      await scrollGrid(max() - 30 * height, 0);
      await frame();
      const before = state.calls.length;
      for (let top = outer().scrollTop; top < max(); top += 3) {
        await scrollGrid(Math.min(top + 3, max()));
      }
      await frame();
      last = state.calls[state.calls.length - 1]!;
      assert.strictEqual(outer().scrollTop, max(), `${label}: at the end`);
      assert.strictEqual(last.last, 199, `${label}, steps: ${line(last)}`);
      const view = rowsInView();
      assert.true(
        state.calls.length > before,
        `${label}: the steps reported (${state.calls.length - before} calls)`
      );
      // no two calls in a row the same
      const lines = state.lines;
      assert.true(
        lines.every((each, i) => i === 0 || each !== lines[i - 1]),
        `${label}: each call is a change: ${lines.join(' ')}`
      );
      assert.strictEqual(
        last.first,
        view.start,
        `${label}: first is the top row in view (${view.start})`
      );
    }
  });

  test('VR3 an owner that appends from the handler gets the new count; focus and scroll stay', async function (assert) {
    const state = new State();
    state.records = rowsOf(100);
    let loads = 0;
    // loads more synchronously inside the handler, as soon as the last
    // three records are in view: this must not run in a render
    state.then = ({ last, count }) => {
      if (count < 200 && last >= count - 3) {
        loads++;
        state.records = [...state.records, ...rowsOf(50, count)];
      }
    };
    await renderSheet(state);
    assert.strictEqual(
      state.calls.length,
      1,
      `first render: ${state.lines.join(' ')}`
    );
    const height = rowHeight();
    const max = () => outer().scrollHeight - outer().clientHeight;

    // near the end, nothing loaded yet; focus a cell in view
    await scrollGrid(max() - 6 * height);
    await frame();
    assert.strictEqual(loads, 0, `nothing loaded: ${state.lines.join(' ')}`);
    let row = state.calls[state.calls.length - 1]!.last - 1;
    await focusCell(row, 1);
    assert.strictEqual(document.activeElement, cell(row, 1), 'focused');

    // ArrowDown to the end: 50 more, once, and the focus stays
    for (let i = 0; i < 10 && !loads; i++) {
      await press('ArrowDown');
      row++;
    }
    await frame();
    assert.strictEqual(loads, 1, `one load: ${state.lines.join(' ')}`);
    assert.strictEqual(state.records.length, 150, '150 records');
    const last = state.calls[state.calls.length - 1]!;
    assert.strictEqual(last.count, 150, `the new count: ${line(last)}`);
    assert.true(last.last >= 97, `last ${last.last}`);
    assert.strictEqual(
      document.activeElement,
      cell(row, 1),
      `the focused cell stayed (row ${row})`
    );
    const top = outer().scrollTop;
    await frame();
    assert.strictEqual(outer().scrollTop, top, 'the scroll stayed');
    assert.strictEqual(loads, 1, 'no second load while nothing changed');

    // an append from outside that keeps the window: one call, new count
    const calls = state.calls.length;
    state.then = null;
    state.records = [...state.records, ...rowsOf(50, 150)];
    await frame();
    assert.strictEqual(
      state.calls.length,
      calls + 1,
      `one call: ${state.lines.slice(calls).join(' ')}`
    );
    assert.strictEqual(state.calls[state.calls.length - 1]!.count, 200);
    assert.strictEqual(document.activeElement, cell(row, 1), 'focus stays');
    assert.strictEqual(outer().scrollTop, top, 'the scroll stays');
  });

  test('VR4 with groups, header and add rows are not counted', async function (assert) {
    // three groups of 10: header, 10 records, add row (12 grid rows each)
    const state = new State();
    state.records = rowsOf(30);
    state.groups = [0, 1, 2].map((i) => ({
      key: `g${i}`,
      depth: 0,
      value: `Group ${i}`,
      count: 10,
      loaded: 10
    }));
    await renderSheet(state);
    const recordOf = (row: number): number => {
      const offset = row % 12;
      return offset >= 1 && offset <= 10
        ? Math.floor(row / 12) * 10 + offset - 1
        : -1;
    };
    let view = rowsInView();
    let expectedLast = view.stop;
    while (recordOf(expectedLast) < 0) expectedLast--;
    assert.deepEqual(
      state.calls[state.calls.length - 1],
      { first: 0, last: recordOf(expectedLast), count: 30 },
      `top: ${state.lines.join(' ')} (rows 0-${view.stop})`
    );

    // the second group's header at the top: its first record is first
    await scrollGrid(12 * rowHeight());
    await frame();
    view = rowsInView();
    assert.strictEqual(view.start, 12, 'header row 12 at the top');
    expectedLast = view.stop;
    while (recordOf(expectedLast) < 0) expectedLast--;
    assert.deepEqual(
      state.calls[state.calls.length - 1],
      { first: 10, last: recordOf(expectedLast), count: 30 },
      `group 2: ${state.lines[state.lines.length - 1]} (rows 12-${view.stop})`
    );

    // the end: the last record, not the add row
    await scrollGrid(outer().scrollHeight);
    await frame();
    assert.strictEqual(
      state.calls[state.calls.length - 1]!.last,
      29,
      `the end: ${state.lines[state.lines.length - 1]}`
    );
  });

  test('VR4b only collapsed group headers on screen: no call until a record is', async function (assert) {
    // 30 collapsed groups (nothing loaded), then one expanded group of 10
    const state = new State();
    state.records = rowsOf(10);
    state.groups = [
      ...Array.from({ length: 30 }, (_, i) => ({
        key: `c${i}`,
        depth: 0,
        value: `Collapsed ${i}`,
        count: 5,
        loaded: 0,
        collapsed: true
      })),
      { key: 'open', depth: 0, value: 'Open', count: 10, loaded: 10 }
    ];
    await renderSheet(state);
    assert.true(rowsInView().stop < 30, 'only headers in view');
    assert.strictEqual(
      state.calls.length,
      0,
      `no call: ${state.lines.join(' ')}`
    );

    // rows: 0-29 the collapsed headers, 30 the open one, 31-40 its records
    await scrollGrid(outer().scrollHeight);
    await frame();
    const view = rowsInView();
    assert.strictEqual(
      state.lines.join(' '),
      `${Math.max(0, view.start - 31)}-9/10`,
      `one call, positions in @records (rows ${view.start}-${view.stop})`
    );
  });

  test('VR5 with a frozen field: the call happens and every column of a rendered row is still rendered', async function (assert) {
    const cellsOfRow = () =>
      document.querySelectorAll(
        '[role=gridcell][data-gridcell-visible-row-index="3"]'
      ).length;

    const without = new State();
    without.fields = fieldsOf(12);
    without.frozenFields = 1;
    await renderSheet(without, false);
    const frozenCells = cellsOfRow();

    const state = new State();
    state.fields = fieldsOf(12);
    state.frozenFields = 1;
    await renderSheet(state);
    assert.strictEqual(
      state.calls.length,
      1,
      `one call: ${state.lines.join(' ')}`
    );
    assert.strictEqual(state.calls[0]!.first, 0, 'first 0');
    assert.strictEqual(
      cellsOfRow(),
      frozenCells,
      `the same cells per row as without the handler (${frozenCells})`
    );
    // 12 fields, the row numbers and the add-field column
    assert.true(frozenCells >= 13, 'every column rendered');

    await scrollGrid(0, 700);
    await frame();
    assert.strictEqual(cellsOfRow(), frozenCells, 'after a scroll right');
    assert.ok(cell(3, 0), 'the frozen cell stays');

    // and without a frozen field the columns are virtualized again
    state.frozenFields = 0;
    await frame();
    assert.true(
      cellsOfRow() < frozenCells,
      `virtualized without frozen fields (${cellsOfRow()})`
    );
  });
});
