/**
 * The group header row gate (V03-DESIGN.md 9.3): a header row is a normal
 * grid row whose first rendered cell carries the label, sticky and wide by
 * CSS (`:first-child`, `!important`, 9.1). 12 fields of 150 px at a 600 px
 * width, 60 records in 3 groups, no add rows (inserting off, so a header
 * follows the previous group's last record). Positions are compared in
 * screen px (the test container is scaled), as in the frozen field's tests.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  doubleClick,
  render,
  settled,
  triggerEvent
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import {
  cell,
  clipboard,
  editor,
  el,
  focusCell,
  press,
  pressed,
  selected,
  type
} from '../../helpers/sheet.ts';

import type { ChangeSet, EuiSheetField, SheetGroup } from '#src/core/index.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';

type Row = Record<string, string | number>;

const FIELDS: EuiSheetField<Row>[] = Array.from({ length: 12 }, (_, i) => ({
  id: `f${i}`,
  label: `Field ${i}`,
  width: 150
}));

const RECORDS: Row[] = Array.from({ length: 60 }, (_, r) => {
  const row: Row = { id: r };
  for (let f = 0; f < 12; f++) row[`f${f}`] = `r${r}c${f}`;
  return row;
});

/**
 * Labels of three widths (9.2, `width: max-content`): narrower than the
 * minimum (row numbers + first field), between the minimum and the
 * visible width, and wider than the visible width.
 */
const LABELS = [
  'Status: Open',
  'Status: In progress, a label wider than the first two columns',
  `Status: Done, ${'a label wider than the grid itself '.repeat(4)}`
];

const GROUPS: SheetGroup[] = ['Open', 'In progress', 'Done'].map(
  (value, i) => ({
    key: `status-${i}`,
    depth: 0,
    value,
    label: LABELS[i],
    count: 20,
    loaded: 20,
    summary: { f6: `sum ${i}` }
  })
);

/** Grid rows: header 0, records 1-20, header 21, records 22-41, header 42, records 43-62. */
const HEADER_ROWS = [0, 21, 42];

const getId = (row: Row) => row['id']!;

class State {
  @tracked frozenFields: number | undefined = undefined;
  changes: ChangeSet[] = [];
  onChange = (changeSet: ChangeSet) => this.changes.push(changeSet);
}

function outer(): HTMLElement {
  return el('.euiDataGrid__virtualized');
}

async function scrollGrid(left: number, top?: number): Promise<void> {
  const element = outer();
  element.scrollLeft = left;
  if (top !== undefined) element.scrollTop = top;
  await triggerEvent(element, 'scroll');
  await frame();
}

/** Waits a frame: the grid renders the new column window after the scroll. */
async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await settled();
}

const rect = (element: Element) => element.getBoundingClientRect();

/** The scroll element's inner left edge, in screen px. */
function scrollLeftEdge(): number {
  const element = outer();
  const box = rect(element);
  const scale = element.offsetWidth ? box.width / element.offsetWidth : 1;
  return box.left + element.clientLeft * scale;
}

function groupRow(row: number): HTMLElement {
  return el(`.euiDataGridRow[data-grid-row-index="${row}"]`);
}

/** The labels of a header row that are displayed (the others are `display: none`). */
function displayedLabels(row: HTMLElement): HTMLElement[] {
  return [
    ...row.querySelectorAll<HTMLElement>('[data-test-subj=euiSheetGroupLabel]')
  ].filter(
    (label) =>
      getComputedStyle(label).display !== 'none' && rect(label).width > 0
  );
}

function cellOf(element: Element): HTMLElement {
  return element.closest<HTMLElement>('[role=gridcell]')!;
}

function at(x: number, y: number): Element | null {
  return document.elementFromPoint(x, y);
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

/** The measurements of the running test, for `report`. */
let notes: string[] = [];

/**
 * A measurement. The TAP log prints only a test's first failed assertion,
 * so a run with `report` in the page's query (`tests/index.html?report`)
 * pushes all of a test's measurements as one failure after it; a normal
 * run does nothing with them.
 */
function report(_assert: Assert, text: string): void {
  notes.push(text);
}

/** Where a header row's label cell is, for `report`. */
function describe(row: HTMLElement, label: HTMLElement): string {
  const holder = cellOf(label);
  const box = rect(holder);
  return `row ${row.dataset['gridRowIndex']}: first cell column ${holder.dataset['gridcellColumnIndex']}, left ${box.left.toFixed(1)} (edge ${scrollLeftEdge().toFixed(1)}), top ${box.top.toFixed(1)} (row ${rect(row).top.toFixed(1)}), width ${box.width.toFixed(1)}, label width ${rect(label).width.toFixed(1)}, position ${getComputedStyle(holder).position}, z-index ${getComputedStyle(holder).zIndex}`;
}

/**
 * `width: max-content` through the cell's wrappers (9.2): the label cell
 * of header `n` (short, longer, wider than the grid, `LABELS`) is the
 * minimum, its label's width, or the visible width with an ellipsis.
 */
function checkWidth(
  assert: Assert,
  n: number,
  index: number,
  label: HTMLElement,
  min: number,
  max: number
): void {
  const width = rect(cellOf(label)).width;
  const title = el('.euiSheet__groupTitle', label);
  const clipped = title.scrollWidth > title.clientWidth + 1;
  if (n === 0) {
    close(assert, width, min, `row ${index}: a short label: the minimum`);
    assert.false(clipped, `row ${index}: not clipped`);
  } else if (n === 1) {
    assert.ok(
      width > min + 1 && width < max - 1,
      `row ${index}: a longer label widens its cell (${width.toFixed(1)} between ${min.toFixed(1)} and ${max.toFixed(1)})`
    );
    assert.false(clipped, `row ${index}: not clipped`);
  } else {
    close(
      assert,
      width,
      max,
      `row ${index}: a label wider than the grid: the visible width`
    );
    assert.true(clipped, `row ${index}: clipped (with an ellipsis)`);
  }
}

/** The label cell's bounds, in screen px: row numbers + first field, the visible width. */
function labelBounds(): { min: number; max: number } {
  const element = outer();
  const scale = rect(element).width / element.offsetWidth;
  return {
    min:
      rect(el('[role=columnheader][data-gridcell-column-index="0"]')).width +
      rect(el('[role=columnheader][data-gridcell-column-index="1"]')).width,
    max: element.clientWidth * scale
  };
}

/** A border side that draws something. */
function visibleBorder(style: CSSStyleDeclaration, side: string): boolean {
  const width = parseFloat(style.getPropertyValue(`border-${side}-width`));
  const kind = style.getPropertyValue(`border-${side}-style`);
  const colour = style.getPropertyValue(`border-${side}-color`);
  return (
    width > 0 &&
    kind !== 'none' &&
    kind !== 'hidden' &&
    colour !== 'transparent' &&
    !/rgba\([^)]*,\s*0\)$/.test(colour)
  );
}

/** The checks of GH2 and GH4 on the label of a header row, at the scroll element's left edge. */
function checkLabelAtEdge(
  assert: Assert,
  row: HTMLElement
): HTMLElement | null {
  const labels = displayedLabels(row);
  assert.strictEqual(labels.length, 1, 'exactly one label is displayed');
  const label = labels[0];
  if (!label) return null;
  const holder = cellOf(label);
  assert.strictEqual(
    holder,
    row.firstElementChild,
    'it is in the first rendered cell'
  );
  close(
    assert,
    rect(holder).left,
    scrollLeftEdge(),
    "its cell's left edge is the scroll element's left edge"
  );
  close(assert, rect(holder).top, rect(row).top, "it is at the row's top");
  const box = rect(label);
  const hit = at(box.left + box.width / 2, box.top + box.height / 2);
  assert.true(
    !!hit && label.contains(hit),
    `elementFromPoint at its centre is inside it (${hit?.className})`
  );
  report(assert, `${describe(row, label)}; hit ${hit?.className}`);
  return label;
}

module('Integration | Component | EuiSheet group headers', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    notes = [];
    // elementFromPoint needs the container on screen
    document.getElementById('ember-testing-container')?.scrollIntoView();
  });

  hooks.afterEach(function (assert) {
    if (!new URLSearchParams(location.search).has('report')) return;
    const text = notes.join(' || ');
    assert.pushResult({
      result: false,
      actual: text,
      expected: 'reported',
      message: text
    });
  });

  async function renderSheet(state: State): Promise<void> {
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            style="--euiSheet-primary: rgb(1, 2, 3)"
            @fields={{FIELDS}}
            @records={{RECORDS}}
            @groups={{GROUPS}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @canInsert={{false}}
            @frozenFields={{state.frozenFields}}
            @height={{400}}
          />
        </div>
      </template>
    );
    await frame();
  }

  test('GH1 at scrollLeft 0 each header row shows one label, in its first cell, at the left edge', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const rendered = [
      ...document.querySelectorAll<HTMLElement>('.euiSheet__groupRow')
    ].map((row) => Number(row.dataset['gridRowIndex']));
    assert.deepEqual(rendered, [0], 'in view at the top: the first header');
    assert.dom(groupRow(0)).hasClass('euiSheet__groupRow--depth0');
    assert
      .dom('[data-test-subj=euiSheetGroupLabel]', groupRow(0))
      .includesText('Status: Open');
    assert
      .dom('.euiDataGridRow[data-grid-row-index="1"]')
      .doesNotHaveClass('euiSheet__groupRow', 'a record row has no class');
    const height = rect(groupRow(0)).height;
    const scale = rect(outer()).height / outer().offsetHeight;
    const { min, max } = labelBounds();
    for (const [n, index] of HEADER_ROWS.entries()) {
      // each header in view in turn, the scroll still at the left
      await scrollGrid(0, Math.max(0, (index * height) / scale - 100));
      const row = groupRow(index);
      const labels = displayedLabels(row);
      assert.strictEqual(
        labels.length,
        1,
        `row ${index}: exactly one label displayed`
      );
      const label = labels[0];
      if (!label) continue;
      assert.strictEqual(
        cellOf(label),
        row.firstElementChild,
        `row ${index}: in the row's first cell`
      );
      assert.strictEqual(
        cellOf(label).dataset['gridcellColumnIndex'],
        '0',
        `row ${index}: the first cell is column 0`
      );
      close(
        assert,
        rect(cellOf(label)).left,
        scrollLeftEdge(),
        `row ${index}: its left edge is the scroll element's left edge`
      );
      report(assert, `${describe(row, label)}; min ${min}, max ${max}`);
      checkWidth(assert, n, index, label, min, max);
    }
  });

  test('GH2 scrolled to 700: column 0 is unmounted and the label is still at the left edge, on top', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await scrollGrid(700);
    assert.strictEqual(outer().scrollLeft, 700, 'scrolled');
    const row = groupRow(0);
    assert.strictEqual(
      row.querySelector('[data-gridcell-column-index="0"]'),
      null,
      'the row has no row-number cell (column 0 is unmounted)'
    );
    const first = row.firstElementChild as HTMLElement;
    assert.notStrictEqual(
      first.dataset['gridcellColumnIndex'],
      '0',
      `the first rendered cell is column ${first.dataset['gridcellColumnIndex']}`
    );
    checkLabelAtEdge(assert, row);
    // a field's cell shows its summary; the label's cell hides its own
    const summaryCell = cell(0, 6);
    const summary = el('[data-test-subj=euiSheetGroupSummary]', summaryCell);
    assert.strictEqual(summary.textContent?.trim(), 'sum 0', 'f6: its summary');
    const box = rect(summary);
    const hit = at(box.left + box.width / 2, box.top + box.height / 2);
    assert.true(
      !!hit && summary.contains(hit),
      `the summary is displayed and on top (${hit?.className})`
    );
    assert.deepEqual(
      [
        ...row.querySelectorAll<HTMLElement>(
          '[data-test-subj=euiSheetGroupSummary]'
        )
      ]
        .filter((s) => getComputedStyle(s).display !== 'none')
        .map((s) => cellOf(s).dataset['gridcellColumnIndex']),
      ['7'],
      'only f6 has a summary, and it is displayed'
    );
    // the three label widths with a data cell carrying the label (9.2)
    const { min, max } = labelBounds();
    const height =
      rect(row).height / (rect(outer()).height / outer().offsetHeight);
    for (const [n, index] of HEADER_ROWS.entries()) {
      await scrollGrid(700, Math.max(0, index * height - 100));
      const scrolled = groupRow(index);
      const label = displayedLabels(scrolled)[0];
      assert.ok(label, `row ${index}: a label`);
      if (!label) continue;
      assert.notStrictEqual(
        cellOf(label).dataset['gridcellColumnIndex'],
        '0',
        `row ${index}: carried by column ${cellOf(label).dataset['gridcellColumnIndex']}`
      );
      close(
        assert,
        rect(cellOf(label)).left,
        scrollLeftEdge(),
        `row ${index}: at the left edge`
      );
      report(assert, `${describe(scrolled, label)}; min ${min}, max ${max}`);
      checkWidth(assert, n, index, label, min, max);
    }
  });

  test('GH3 a header row under the column header does not paint over it', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const header = el('[data-test-subj=dataGridHeader]');
    const headerBox = rect(header);
    const element = outer();
    const scale = rect(element).height / element.offsetHeight;
    const height = rect(groupRow(0)).height / scale;
    // first in view, to read its offset in the scrolled content
    await scrollGrid(0, 21 * height - 100);
    const contentTop =
      (rect(groupRow(21)).top - rect(element).top) / scale + element.scrollTop;
    // then its top a quarter of the header's height below the scroll element's top
    const top = contentTop - (headerBox.height / scale) * 0.25;
    for (const left of [0, 700]) {
      await scrollGrid(left, top);
      const scrolled = groupRow(21);
      const label = displayedLabels(scrolled)[0]!;
      const holder = cellOf(label);
      const rowBox = rect(scrolled);
      const headerNow = rect(header);
      assert.ok(
        rowBox.top < headerNow.bottom && rowBox.bottom > headerNow.top,
        `left ${left}: the header row (${rowBox.top.toFixed(1)}-${rowBox.bottom.toFixed(1)}) is under the column header (${headerNow.top.toFixed(1)}-${headerNow.bottom.toFixed(1)})`
      );
      const y = headerNow.top + headerNow.height / 2;
      const holderBox = rect(holder);
      // over the label's cell, and over a cell to its right
      for (const x of [
        holderBox.left + holderBox.width / 2,
        holderBox.right + 40
      ]) {
        const hit = at(x, y);
        report(
          assert,
          `GH3 left ${left}: row ${rect(scrolled).top.toFixed(1)}-${rect(scrolled).bottom.toFixed(1)}, header ${headerNow.top.toFixed(1)}-${headerNow.bottom.toFixed(1)}, label cell z-index ${getComputedStyle(holder).zIndex}, point (${x.toFixed(0)}, ${y.toFixed(0)}) hit ${hit?.className}`
        );
        assert.true(
          !!hit && header.contains(hit),
          `left ${left}, x ${x.toFixed(0)}: elementFromPoint on the column header is the column header (${hit?.className})`
        );
      }
    }
  });

  test('GH4 with a frozen field at scrollLeft 700 the label paints over the frozen first field', async function (assert) {
    const state = new State();
    state.frozenFields = 1;
    await renderSheet(state);
    await scrollGrid(700);
    assert.strictEqual(outer().scrollLeft, 700, 'scrolled');
    const row = groupRow(0);
    // with a frozen field every column is rendered (9.1): the row-number
    // cell stays and is the first cell
    assert.strictEqual(
      (row.firstElementChild as HTMLElement).dataset['gridcellColumnIndex'],
      '0',
      'every column is rendered: the first cell is column 0'
    );
    const label = checkLabelAtEdge(assert, row);
    if (!label) return;
    const holder = cellOf(label);
    const firstField = cell(0, 0);
    const box = rect(label);
    const holderBox = rect(holder);
    const y = box.top + box.height / 2;
    for (const x of [
      box.left + box.width * 0.75,
      box.right - 1,
      holderBox.left + holderBox.width * 0.75
    ]) {
      const hit = at(x, y);
      report(
        assert,
        `GH4 x ${x.toFixed(0)}: hit ${hit?.className}; first field cell left ${rect(firstField).left.toFixed(1)}, position ${getComputedStyle(firstField).position}`
      );
      assert.true(
        !!hit && holder.contains(hit) && !firstField.contains(hit),
        `x ${x.toFixed(0)}: elementFromPoint is the label's cell, not the frozen first field (${hit?.className})`
      );
    }
    assert.true(
      label.contains(at(box.left + box.width * 0.75, y)),
      "the label's right half is the label"
    );
  });

  test('GH5 ArrowDown onto a header row at scrollLeft 700 focuses it, draws its ring, and ArrowDown leaves it in the same column', async function (assert) {
    const state = new State();
    await renderSheet(state);
    // rows 20 (last of the first group), 21 (header), 22 in view
    const scale = rect(outer()).height / outer().offsetHeight;
    const height = rect(groupRow(0)).height / scale;
    await scrollGrid(700, 20 * height - 150);
    await focusCell(20, 6);
    await frame();
    assert.strictEqual(document.activeElement, cell(20, 6), 'on a record');
    await press('ArrowDown');
    await frame();
    const row = groupRow(21);
    const focused = document.activeElement as HTMLElement;
    assert.true(
      row.contains(focused) && focused.matches('[role=gridcell]'),
      `a cell of the header row has focus (row ${focused.dataset['gridcellRowIndex']}, column ${focused.dataset['gridcellColumnIndex']})`
    );
    assert.strictEqual(
      focused.dataset['gridcellColumnIndex'],
      String(6 + 1),
      'in the same column'
    );
    assert.strictEqual(outer().scrollLeft, 700, 'the scroll is kept');
    const ring = getComputedStyle(row, '::after');
    report(
      assert,
      `GH5 focused row ${focused.dataset['gridcellRowIndex']} column ${focused.dataset['gridcellColumnIndex']}, ring content ${ring.content}, outline ${ring.outlineStyle} ${ring.outlineWidth} ${ring.outlineColor}, z-index ${ring.zIndex}, scrollLeft ${outer().scrollLeft}`
    );
    assert.notStrictEqual(
      ring.content,
      'none',
      `the ring is drawn (${ring.content})`
    );
    assert.strictEqual(ring.outlineStyle, 'solid', 'a solid outline');
    assert.strictEqual(
      ring.outlineColor,
      'rgb(1, 2, 3)',
      'in --euiSheet-primary'
    );
    await press('ArrowDown');
    await frame();
    assert.strictEqual(
      document.activeElement,
      cell(22, 6),
      'ArrowDown again: the next record, same column'
    );
    assert.strictEqual(
      getComputedStyle(groupRow(21), '::after').content,
      'none',
      'the ring is gone'
    );
    // and back up through the header
    await press('ArrowUp');
    await frame();
    assert.true(
      groupRow(21).contains(document.activeElement),
      'ArrowUp: the header row'
    );
    await press('ArrowUp');
    await frame();
    assert.strictEqual(
      document.activeElement,
      cell(20, 6),
      'ArrowUp again: the record above, same column'
    );
    // the header is inert: keys, clipboard, clicks
    await press('ArrowDown');
    await frame();
    const header = document.activeElement as HTMLElement;
    assert.true(groupRow(21).contains(header), 'on the header again');
    await type('x');
    await press('Enter');
    await press(' ');
    await press('Delete');
    await press('Backspace');
    // Ctrl+D (fill down) has no range to fill
    await pressed('d', { ctrlKey: true });
    assert.strictEqual(editor(), null, 'no editor opened');
    const pasted = await clipboard('paste', 'a\tb');
    assert.false(pasted.prevented, 'a paste on it is not taken');
    const copied = await clipboard('copy');
    assert.strictEqual(copied.text, '', 'a copy from it is empty');
    assert.true(
      copied.prevented,
      'and taken (not the grid’s copy of its text)'
    );
    assert.deepEqual(selected(), [], 'nothing is selected');
    assert.strictEqual(document.activeElement, header, 'focus stays');
    const label = displayedLabels(groupRow(21))[0]!;
    await click(label);
    await doubleClick(label);
    await frame();
    assert.strictEqual(editor(), null, 'a click or double-click edits nothing');
    assert.deepEqual(selected(), [], 'and selects nothing');
    assert.deepEqual(state.changes, [], 'nothing was changed');
  });

  test('GH6 every cell of a header row has one opaque background and no inline border, light and dark', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const check = (theme: string): string => {
      const row = groupRow(0);
      const cells = [...row.querySelectorAll<HTMLElement>('[role=gridcell]')];
      assert.true(cells.length > 2, `${theme}: ${cells.length} cells`);
      const colours = cells.map((c) => getComputedStyle(c).backgroundColor);
      const first = colours[0]!;
      assert.deepEqual(
        colours.filter((colour) => colour !== first),
        [],
        `${theme}: every cell is ${first}`
      );
      assert.true(/^rgb\(/.test(first), `${theme}: opaque (${first})`);
      const style = getComputedStyle(cells[1]!);
      report(
        assert,
        `GH6 ${theme}: ${cells.length} cells, background ${first}; cell 1 border-left ${style.borderLeftWidth} ${style.borderLeftStyle}, border-right ${style.borderRightWidth} ${style.borderRightStyle} ${style.borderRightColor}`
      );
      // stage 3.1: the inner dividers are gone; the grid frame's outer
      // edges (the first column's left, the last column's right) stay, as
      // on the add row
      const outerLeft = (c: HTMLElement) =>
        c.classList.contains('euiDataGridRowCell--firstColumn');
      const outerRight = (c: HTMLElement) =>
        c.classList.contains('euiDataGridRowCell--lastColumn');
      const bordered = cells.filter((c) => {
        const style = getComputedStyle(c);
        return (
          (visibleBorder(style, 'left') && !outerLeft(c)) ||
          (visibleBorder(style, 'right') && !outerRight(c))
        );
      });
      assert.deepEqual(
        bordered.map((c) => c.dataset['gridcellColumnIndex']),
        [],
        `${theme}: no cell has a visible inner divider`
      );
      const edge = cells.find(outerLeft);
      assert.true(
        !!edge && visibleBorder(getComputedStyle(edge), 'left'),
        `${theme}: the first column keeps the frame's left edge`
      );
      return first;
    };
    const light = check('light');
    const emotion = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    emotion.colorMode = 'dark';
    await settled();
    const dark = check('dark');
    assert.notStrictEqual(dark, light, `dark ${dark} is not light ${light}`);
  });
});
