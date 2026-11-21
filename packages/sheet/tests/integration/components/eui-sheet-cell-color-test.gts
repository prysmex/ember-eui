/**
 * Cell colour (v0.4 08, CC1-CC11, CC-perf): `@cellColor(record, field)`
 * draws a 3 px bar along the cell's bottom edge, an element of its own
 * (`span.euiSheet__cellMark`): both pseudo-elements and the box-shadows of
 * a data cell are taken. Named colours are batch 4's row-colour tokens, a
 * CSS colour is used as given. The bar sits inside the cell's inner frames,
 * so it shows together with each of them: the error border, the match
 * ring, the upload bar, the row bar, a frozen cell, the selection and the
 * focus ring. Geometry is read in layout px (`offset*`, `client*`) and
 * computed styles: the test container is scaled.
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
import { localRecords } from '#src/local-records.ts';
import { cell, el, focusCell, selected } from '../../helpers/sheet.ts';

import type {
  EuiSheetField,
  RecordId,
  SheetAttachment
} from '#src/core/index.ts';
import type { SheetRowColor } from '#src/types.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';

interface Row {
  id: string;
  name: string;
  due: string | null;
  qty: number | null;
  [key: string]: unknown;
}

type CellColor = (
  record: Row,
  field: EuiSheetField<Row>
) => SheetRowColor | undefined;

const TODAY = '2026-11-21';
const getId = (row: Row) => row.id;
const noop = () => {};

function rows(): Row[] {
  const dues = ['2026-11-01', '2026-12-24', '2026-11-20', null];
  return dues.map((due, i) => {
    const row: Row = { id: `r${i}`, name: `N${i}`, due, qty: i };
    for (let f = 0; f < 9; f++) row[`f${f}`] = `${i}-${f}`;
    return row;
  });
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name', width: 150 },
  { id: 'due', label: 'Due', type: 'date', width: 150 },
  { id: 'qty', label: 'Qty', type: 'number', width: 150 },
  ...Array.from({ length: 9 }, (_, f) => ({
    id: `f${f}`,
    label: `F${f}`,
    width: 150
  }))
];

/** The design's example: an overdue date in red. */
const overdue: CellColor = (record, field) =>
  field.id === 'due' && record.due && record.due < TODAY ? 'danger' : undefined;

const DUE = 1;

function markOf(element: HTMLElement): HTMLElement | null {
  return element.querySelector<HTMLElement>('.euiSheet__cellMark');
}

function mark(row: number, col: number): HTMLElement {
  const found = markOf(cell(row, col));
  if (!found) throw new Error(`no mark in ${row}:${col}`);
  return found;
}

/** `#rrggbb` → `rgb(r, g, b)`, as computed styles report it. */
function rgb(hex: string): string {
  const parts = /^#([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i.exec(hex.trim());
  if (!parts) return hex.trim();
  return `rgb(${parts
    .slice(1)
    .map((pair) => parseInt(pair, 16))
    .join(', ')})`;
}

function token(name: string): string {
  return getComputedStyle(el('[data-test-subj=euiSheet]'))
    .getPropertyValue(name)
    .trim();
}

function background(element: Element): string {
  return getComputedStyle(element).backgroundColor;
}

/**
 * Where the bar sits in its cell, in layout px: the gaps to the cell's
 * padding box on the left, the right and the bottom, and its height.
 */
function gaps(row: number, col: number) {
  const target = cell(row, col);
  const bar = mark(row, col);
  return {
    parent: bar.offsetParent === target,
    left: bar.offsetLeft,
    right: target.clientWidth - bar.offsetLeft - bar.offsetWidth,
    bottom: target.clientHeight - bar.offsetTop - bar.offsetHeight,
    height: bar.offsetHeight
  };
}

function placed(
  assert: Assert,
  row: number,
  col: number,
  expected: { left: number; right: number; bottom: number },
  message: string
): void {
  const actual = gaps(row, col);
  assert.deepEqual(
    actual,
    { parent: true, height: 3, ...expected },
    `${message}: ${JSON.stringify(actual)}`
  );
}

async function scrollGrid(top: number): Promise<void> {
  const element = el('.euiDataGrid__virtualized');
  element.scrollLeft = 0;
  element.scrollTop = top;
  await triggerEvent(element, 'scroll');
}

/** Waits a frame: the sheet's focus correction runs after the grid's own scroll. */
async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await settled();
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

/** CC-perf: the variant shown. */
class PerfView<F> {
  @tracked cellColor: F | undefined = undefined;
  @tracked frozenFields = 1;
}

class State {
  @tracked records: Row[] = rows();
  @tracked fields: EuiSheetField<Row>[] = FIELDS;
  @tracked cellColor: CellColor | undefined = overdue;
  @tracked rowColor: ((record: Row) => SheetRowColor | undefined) | undefined =
    undefined;
  @tracked rowNumbers = true;
  @tracked frozenFields = 0;
  @tracked cellErrors: Record<string, Record<string, string>> | undefined =
    undefined;
  @tracked currentMatch: { recordId: RecordId; fieldId: string } | null = null;
}

module('Integration | Component | EuiSheet cell colour', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
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
            @onChange={{noop}}
            @cellColor={{state.cellColor}}
            @rowColor={{state.rowColor}}
            @rowNumbers={{state.rowNumbers}}
            @frozenFields={{state.frozenFields}}
            @cellErrors={{state.cellErrors}}
            @currentMatch={{state.currentMatch}}
            @height={{300}}
          />
        </div>
      </template>
    );
  }

  test('CC1 a named colour draws a 3 px bar along the bottom edge in the theme’s token', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const danger = token('--euiSheet-rowDanger');
    assert.ok(danger, `--euiSheet-rowDanger is defined (${danger})`);
    const bar = mark(0, DUE);
    assert.dom(bar).hasClass('euiSheet__rowColor--danger');
    assert.dom(bar).hasAttribute('aria-hidden', 'true');
    assert.strictEqual(bar.getAttribute('style'), null, 'no inline style');
    assert.strictEqual(background(bar), rgb(danger), 'in the token');
    const style = getComputedStyle(bar);
    assert.strictEqual(style.position, 'absolute');
    assert.strictEqual(style.pointerEvents, 'none');
    placed(assert, 0, DUE, { left: 0, right: 0, bottom: 0 }, 'along the edge');
    assert.true(
      cell(0, DUE).getBoundingClientRect().bottom -
        bar.getBoundingClientRect().bottom <
        1,
      'on screen at the cell’s bottom'
    );
    // only the overdue dates: r0 and r2; not the future one, the empty one
    // or the other fields
    assert.deepEqual(
      [...document.querySelectorAll<HTMLElement>('.euiSheet__cellMark')].map(
        (found) => {
          const host = found.closest<HTMLElement>('[role=gridcell]')!;
          return `${host.dataset['gridcellVisibleRowIndex']}:${
            Number(host.dataset['gridcellColumnIndex']) - 1
          }`;
        }
      ),
      ['0:1', '2:1']
    );
    // the cell itself: its text, title and label as without a colour
    assert.dom(cell(0, DUE)).includesText('01/11/2026');
    assert.strictEqual(cell(0, DUE).getAttribute('aria-label'), null);
    assert.strictEqual(cell(0, DUE).getAttribute('title'), null);
  });

  test('CC2 a CSS colour is used as given; one that could leave the property is dropped', async function (assert) {
    const state = new State();
    state.cellColor = (record, field) =>
      field.id === 'qty' && record.id === 'r0'
        ? 'url(https://example.invalid/x.png)'
        : field.id !== 'name'
          ? undefined
          : (
              {
                r0: 'rgb(1, 2, 3)',
                r1: '#123456',
                r2: 'red; background: blue',
                r3: 'oklch(70% 0.1 200)'
              } as Record<string, string>
            )[record.id];
    await renderSheet(state);
    assert.strictEqual(background(mark(0, 0)), 'rgb(1, 2, 3)');
    assert.strictEqual(
      mark(0, 0).getAttribute('style'),
      '--euiSheetRowColor: rgb(1, 2, 3)'
    );
    assert.strictEqual(
      mark(0, 0).className,
      'euiSheet__cellMark ',
      'no named class'
    );
    assert.strictEqual(background(mark(1, 0)), 'rgb(18, 52, 86)', '#123456');
    assert.strictEqual(markOf(cell(2, 0)), null, 'dropped: no bar');
    // not a colour: the bar paints nothing (background-color, so no image
    // is fetched)
    const image = getComputedStyle(mark(0, 2));
    assert.strictEqual(image.backgroundImage, 'none', 'no image');
    assert.strictEqual(image.backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.ok(
      background(mark(3, 0)).startsWith('oklch'),
      `any CSS colour: ${background(mark(3, 0))}`
    );
  });

  test('CC3 undefined, and no @cellColor, leave the cell as in v0.3', async function (assert) {
    const state = new State();
    state.cellColor = undefined;
    await renderSheet(state);
    const snapshot = (row: number, col: number) => {
      const target = cell(row, col);
      return {
        className: target.className,
        style: target.getAttribute('style'),
        title: target.getAttribute('title'),
        label: target.getAttribute('aria-label'),
        html: target.querySelector('[data-datagrid-cellcontent]')!.innerHTML
      };
    };
    const before = [snapshot(1, DUE), snapshot(0, 0), snapshot(3, DUE)];
    assert.strictEqual(
      document.querySelectorAll('.euiSheet__cellMark').length,
      0,
      'no @cellColor: no bar'
    );
    state.cellColor = overdue;
    await settled();
    assert.strictEqual(
      document.querySelectorAll('.euiSheet__cellMark').length,
      2,
      'the overdue cells'
    );
    assert.deepEqual(
      [snapshot(1, DUE), snapshot(0, 0), snapshot(3, DUE)],
      before,
      'cells whose colour is undefined: the same classes, style, title, label and content'
    );
    // a coloured cell's own class and style are unchanged too
    state.cellColor = undefined;
    await settled();
    const plain = { className: cell(0, DUE).className };
    state.cellColor = overdue;
    await settled();
    assert.strictEqual(cell(0, DUE).className, plain.className);
  });

  test('CC4 a new @records with a changed value, and a new @cellColor, update the bar', async function (assert) {
    const state = new State();
    const calls: Array<[string, string]> = [];
    state.cellColor = (record, field) => {
      calls.push([record.id, field.id]);
      return overdue(record, field);
    };
    await renderSheet(state);
    assert.ok(
      calls.some(([id, fieldId]) => id === 'r0' && fieldId === 'due'),
      'called with the record and its field'
    );
    assert.ok(markOf(cell(0, DUE)));
    assert.strictEqual(markOf(cell(1, DUE)), null);
    state.records = state.records.map((row) =>
      row.id === 'r0'
        ? { ...row, due: '2027-01-01' }
        : row.id === 'r1'
          ? { ...row, due: '2026-01-01' }
          : row
    );
    await settled();
    assert.strictEqual(markOf(cell(0, DUE)), null, 'no longer overdue');
    assert.ok(markOf(cell(1, DUE)), 'now overdue');
    state.cellColor = (record, field) =>
      field.id === 'qty' && (record.qty ?? 0) >= 2 ? 'success' : undefined;
    await settled();
    assert.strictEqual(markOf(cell(1, DUE)), null, 'the old rule is gone');
    assert.dom(mark(2, 2)).hasClass('euiSheet__rowColor--success');
    assert.dom(mark(3, 2)).hasClass('euiSheet__rowColor--success');
    assert.strictEqual(markOf(cell(1, 2)), null);
  });

  test('CC5 dark theme: a named colour follows the token; a CSS colour stays', async function (assert) {
    const state = new State();
    state.cellColor = (record, field) =>
      field.id === 'due'
        ? 'danger'
        : field.id === 'qty'
          ? '#123456'
          : undefined;
    await renderSheet(state);
    const light = background(mark(0, DUE));
    const lightToken = token('--euiSheet-rowDanger');
    const emotion = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    emotion.colorMode = 'dark';
    await settled();
    try {
      const darkToken = token('--euiSheet-rowDanger');
      assert.notStrictEqual(darkToken, lightToken, 'the token changes');
      const dark = background(mark(0, DUE));
      assert.notStrictEqual(dark, light, `the bar: ${light} → ${dark}`);
      assert.strictEqual(dark, rgb(darkToken), 'in the dark token');
      assert.strictEqual(background(mark(0, 2)), 'rgb(18, 52, 86)');
    } finally {
      emotion.colorMode = 'light';
      await settled();
    }
  });

  test('CC6 an invalid cell keeps its red border and the bar, also focused', async function (assert) {
    const state = new State();
    state.cellErrors = { r0: { due: 'Overdue' } };
    await renderSheet(state);
    const danger = rgb(token('--euiSheet-danger') || '#BD271E');
    const target = cell(0, DUE);
    assert.dom(target).hasClass('euiSheet__cell--invalid');
    const shadow = getComputedStyle(target).boxShadow;
    assert.ok(
      shadow.includes('1px inset') && shadow.includes(danger),
      `the 1 px red border: ${shadow}`
    );
    assert.strictEqual(target.getAttribute('title'), 'Overdue');
    placed(assert, 0, DUE, { left: 1, right: 1, bottom: 1 }, 'inside it');
    await focusCell(0, DUE);
    const focused = getComputedStyle(target).boxShadow;
    assert.ok(
      focused.includes('5px inset') && focused.includes(danger),
      `focused: the 5 px band: ${focused}`
    );
    assert.strictEqual(getComputedStyle(target).outlineWidth, '3px');
    placed(assert, 0, DUE, { left: 5, right: 5, bottom: 5 }, 'inside the band');
  });

  test('CC7 the row bar on the first field (no row numbers) and the cell’s bar: both drawn', async function (assert) {
    const state = new State();
    state.rowNumbers = false;
    state.rowColor = (record) => (record.id === 'r0' ? 'success' : undefined);
    state.cellColor = (record, field) =>
      field.id === 'name' && record.id !== 'r3' ? 'danger' : undefined;
    await renderSheet(state);
    const first = el(
      '[role=gridcell][data-gridcell-visible-row-index="0"][data-gridcell-column-index="0"]'
    );
    assert.dom(first).hasClass('euiSheet__rowColor');
    const shadow = getComputedStyle(first).boxShadow;
    const success = rgb(token('--euiSheet-rowSuccess'));
    assert.ok(
      shadow.includes(success) && shadow.includes('4px 0px 0px 0px inset'),
      `the row bar: ${shadow}`
    );
    const bar = markOf(first)!;
    assert.strictEqual(
      background(bar),
      rgb(token('--euiSheet-rowDanger')),
      'the cell’s own colour, not the row’s'
    );
    assert.strictEqual(bar.offsetParent, first);
    assert.strictEqual(bar.offsetLeft, 4, 'right of the row bar');
    assert.strictEqual(
      first.clientHeight - bar.offsetTop - bar.offsetHeight,
      0,
      'at the bottom'
    );
    // a row with a CSS row colour: the cell keeps its named colour
    state.rowColor = () => 'rgb(1, 2, 3)';
    await settled();
    assert.strictEqual(
      background(markOf(first)!),
      rgb(token('--euiSheet-rowDanger'))
    );
    // a row without a bar: the cell's bar from the left edge
    const second = el(
      '[role=gridcell][data-gridcell-visible-row-index="1"][data-gridcell-column-index="0"]'
    );
    state.rowColor = undefined;
    await settled();
    assert.strictEqual(markOf(second)!.offsetLeft, 0);
  });

  test('CC8 the current match: its ring and the bar inside it', async function (assert) {
    const state = new State();
    await renderSheet(state);
    state.currentMatch = { recordId: 'r0', fieldId: 'due' };
    await settled();
    const target = cell(0, DUE);
    assert.dom(target).hasClass('euiSheet__cell--match');
    const ring = getComputedStyle(target, '::after');
    assert.ok(
      ring.boxShadow.includes('2px inset'),
      `the 2 px ring: ${ring.boxShadow}`
    );
    placed(assert, 0, DUE, { left: 2, right: 2, bottom: 2 }, 'inside the ring');
  });

  test('CC9 a frozen cell scrolled sideways keeps its bar', async function (assert) {
    const state = new State();
    state.frozenFields = 1;
    state.cellColor = (record, field) =>
      field.id === 'name' && record.id === 'r1' ? 'warning' : undefined;
    await renderSheet(state);
    const outer = el('.euiDataGrid__virtualized');
    outer.scrollLeft = 700;
    await triggerEvent(outer, 'scroll');
    assert.strictEqual(outer.scrollLeft, 700, 'scrolled');
    const target = cell(1, 0);
    assert.strictEqual(target.style.position, 'sticky');
    placed(assert, 1, 0, { left: 0, right: 0, bottom: 0 }, 'frozen');
    const box = target.getBoundingClientRect();
    const barBox = mark(1, 0).getBoundingClientRect();
    assert.true(
      Math.abs(barBox.left - box.left) < 1 &&
        Math.abs(barBox.right - box.right) < 1,
      'moves with the sticky cell'
    );
    assert.strictEqual(
      background(mark(1, 0)),
      rgb(token('--euiSheet-rowWarning'))
    );
    // the scrolled cells under the frozen one do not cover it: the frozen
    // cell is what is painted on the bar's row (the bar itself lets the
    // pointer through)
    const hit = document.elementFromPoint(
      barBox.left + barBox.width / 2,
      barBox.bottom - 1
    );
    assert.true(!!hit && target.contains(hit), 'the frozen cell is on top');
  });

  test('CC10 selected and focused: the bar inside the focus ring and a range’s edge', async function (assert) {
    const state = new State();
    state.cellColor = (record, field) =>
      field.id === 'due' || field.id === 'qty' ? 'primary' : undefined;
    await renderSheet(state);
    await click(cell(0, DUE));
    const target = cell(0, DUE);
    assert.dom(target).hasClass('euiSheet__cell--selected');
    assert.strictEqual(document.activeElement, target);
    assert.strictEqual(getComputedStyle(target).outlineWidth, '3px');
    assert.strictEqual(getComputedStyle(target).outlineOffset, '-3px');
    placed(assert, 0, DUE, { left: 3, right: 3, bottom: 3 }, 'focused');
    // a range of four cells: its 3 px outline; the bottom row's bars above it
    await click(cell(1, 2), { shiftKey: true });
    assert.deepEqual(selected(), ['0:1', '0:2', '1:1', '1:2']);
    assert.dom('[data-test-subj=euiSheetRangeOutline]').exists();
    assert.notStrictEqual(
      background(cell(1, 2)),
      'rgba(0, 0, 0, 0)',
      'drawn selected'
    );
    placed(assert, 1, 2, { left: 0, right: 0, bottom: 3 }, 'range bottom');
    placed(assert, 0, 2, { left: 0, right: 0, bottom: 3 }, 'range top');
    placed(assert, 0, DUE, { left: 3, right: 3, bottom: 3 }, 'the active cell');
    // off the range: back to the edge
    await click(cell(3, 0));
    placed(assert, 1, 2, { left: 0, right: 0, bottom: 0 }, 'not selected');
  });

  test('CC11 an upload’s progress bar and the cell’s bar: the bar above it', async function (assert) {
    const calls: Array<{
      onProgress: (fraction: number) => void;
      resolve: (files: SheetAttachment[]) => void;
    }> = [];
    type FileRow = { id: string; files: SheetAttachment[] };
    const fileId = (row: FileRow) => row.id;
    const fields: EuiSheetField<{ id: string; files: SheetAttachment[] }>[] = [
      { id: 'name', label: 'Name' },
      {
        id: 'files',
        label: 'Files',
        type: 'attachment',
        width: 240,
        upload: (
          _files: File[],
          context: { onProgress: (fraction: number) => void }
        ) =>
          new Promise<SheetAttachment[]>((resolve) =>
            calls.push({ onProgress: context.onProgress, resolve })
          )
      } as EuiSheetField<{ id: string; files: SheetAttachment[] }>
    ];
    const store = localRecords(
      [
        { id: 'r0', files: [] as SheetAttachment[] },
        { id: 'r1', files: [] as SheetAttachment[] }
      ],
      { getRecordId: fileId, fields }
    );
    const colorFiles = (_record: unknown, field: { id: string }) =>
      field.id === 'files' ? 'accent' : undefined;
    await render(
      <template>
        <EuiSheet
          @records={{store.records}}
          @fields={{store.fields}}
          @getRecordId={{fileId}}
          @onChange={{store.apply}}
          @cellColor={{colorFiles}}
        />
      </template>
    );
    await focus(cell(0, 1));
    const data = new DataTransfer();
    data.items.add(new File(['x'], 'photo.png'));
    cell(0, 1).dispatchEvent(
      new ClipboardEvent('paste', {
        clipboardData: data,
        bubbles: true,
        cancelable: true
      })
    );
    await waitUntil(() => calls.length === 1);
    calls[0]!.onProgress(0.5);
    await waitUntil(() =>
      cell(0, 1).classList.contains('euiSheet__cellProgress')
    );
    // focus elsewhere, so only the upload frames the cell (not `focus()`:
    // settled() waits for the pending upload)
    cell(1, 0).focus();
    await waitUntil(
      () => !cell(0, 1).classList.contains('euiSheet__cell--selected')
    );
    const progress = getComputedStyle(cell(0, 1), '::before');
    assert.strictEqual(progress.bottom, '0px', 'the upload bar at the edge');
    assert.strictEqual(progress.height, '2px');
    placed(assert, 0, 1, { left: 0, right: 0, bottom: 2 }, 'above it');
    assert.strictEqual(
      background(mark(0, 1)),
      rgb(token('--euiSheet-rowAccent'))
    );
    // the other row's cell, not uploading: at the edge
    placed(assert, 1, 1, { left: 0, right: 0, bottom: 0 }, 'not uploading');
    calls[0]!.resolve([]);
    await settled();
    placed(assert, 0, 1, { left: 0, right: 0, bottom: 0 }, 'done: at the edge');
  });

  test('CC-perf vertical scroll over 10,000 rows with 30 fields: with and without @cellColor (time logged)', async function (assert) {
    // FZ9's case and steps; FZ13's method: the variants interleaved over
    // rounds, the fastest round of each (a loaded machine slows a round,
    // not a variant)
    assert.timeout(300_000);
    type Big = Record<string, string | number>;
    const fields: EuiSheetField<Big>[] = Array.from({ length: 30 }, (_, i) => ({
      id: `f${i}`,
      label: `Field ${i}`,
      width: 150
    }));
    const index = new Map(fields.map((field, i) => [field.id, i]));
    const records: Big[] = Array.from({ length: 10_000 }, (_, r) => {
      const row: Big = { id: r };
      for (let f = 0; f < 30; f++) row[`f${f}`] = `r${r}c${f}`;
      return row;
    });
    // every third cell, in O(1)
    const everyThird = (record: Big, field: EuiSheetField<Big>) =>
      (Number(record['id']) + index.get(field.id)!) % 3 === 0
        ? 'danger'
        : undefined;
    const view = new PerfView<typeof everyThird>();
    const bigId = (row: Big) => row['id']!;
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @fields={{fields}}
            @records={{records}}
            @getRecordId={{bigId}}
            @onChange={{noop}}
            @frozenFields={{view.frozenFields}}
            @cellColor={{view.cellColor}}
            @height={{400}}
          />
        </div>
      </template>
    );
    type Measured = { ms: number; cells: number; marks: number };
    const variants = [
      { color: false, frozen: 1 },
      { color: true, frozen: 1 },
      { color: false, frozen: 0 },
      { color: true, frozen: 0 }
    ];
    const best: Measured[] = variants.map(() => ({
      ms: Infinity,
      cells: 0,
      marks: 0
    }));
    for (let round = 0; round < 3; round++) {
      for (const [i, variant] of variants.entries()) {
        view.cellColor = variant.color ? everyThird : undefined;
        view.frozenFields = variant.frozen;
        await settled();
        await scrollGrid(0);
        await frame();
        const result = await measure();
        if (result.ms < best[i]!.ms) best[i] = result;
      }
    }
    const [offOn, colorOn, offOff, colorOff] = best as [
      Measured,
      Measured,
      Measured,
      Measured
    ];
    const ratio = (a: Measured, b: Measured) => (a.ms / b.ms).toFixed(2);
    const line = (name: string, m: Measured) =>
      `${name} ${m.ms.toFixed(1)} ms, ${m.cells} cells, ${m.marks} bars`;
    report(
      assert,
      `CC-perf per scroll step: frozen on: ${line('without', offOn)}; ${line('with', colorOn)} (x${ratio(colorOn, offOn)}); frozen off: ${line('without', offOff)}; ${line('with', colorOff)} (x${ratio(colorOff, offOff)})`
    );
    // logged, not asserted, like FZ9 and FZ13: a timing ratio fails on a
    // loaded machine; the gate's numbers are in V04-RESULTS.md
    assert.ok(
      best.every((m) => Number.isFinite(m.ms) && m.ms > 0),
      'every variant was measured'
    );
    assert.ok(colorOn.marks > 0 && colorOff.marks > 0, 'bars were drawn');
    assert.strictEqual(offOn.marks + offOff.marks, 0, 'none without it');

    async function measure(): Promise<Measured> {
      const steps = 20;
      const start = performance.now();
      for (let i = 1; i <= steps; i++) {
        await scrollGrid(i * 600);
        await frame();
      }
      return {
        ms: (performance.now() - start) / steps,
        cells: document.querySelectorAll('.euiDataGridRow [role=gridcell]')
          .length,
        marks: document.querySelectorAll('.euiSheet__cellMark').length
      };
    }
  });
});
