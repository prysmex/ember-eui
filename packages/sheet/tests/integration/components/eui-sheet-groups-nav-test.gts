/**
 * Group by in the component, stage 3.2a (V03-DESIGN.md 8.5, 8.6, 8.10):
 * moving, selecting, copying, pasting and filling across group headers
 * and group add rows. GR5, GR6, GR7, GR8, GR10, GR11, GR17, and one test
 * per batch 3a site that no grouped test covered (the drawn range and its
 * marks, the range outline, the flash, the clamp of a lost head).
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
import {
  cell,
  clipboard,
  editor,
  editorFrame,
  el,
  focusCell,
  press,
  pressed,
  selected,
  text,
  type
} from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  SheetGroup,
  SheetGroupBy
} from '#src/core/index.ts';

type Row = {
  id: string;
  name: string;
  status: string | null;
  owner: string;
  qty: number;
};

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name', width: 120 },
  { id: 'status', label: 'Status', width: 120 },
  { id: 'owner', label: 'Owner', width: 120 },
  { id: 'qty', label: 'Qty', type: 'number', width: 120 }
];

const getId = (row: Row) => row.id;

/** Six records, two per status, in display order. */
function rows(owners = ['Ana', 'Bo', 'Ana', 'Ana', 'Bo', 'Bo']): Row[] {
  return (
    [
      ['r0', 'Open', 1],
      ['r1', 'Open', 2],
      ['r2', 'Doing', 3],
      ['r3', 'Doing', 4],
      ['r4', 'Done', 5],
      ['r5', 'Done', 6]
    ] as const
  ).map(([id, status, qty], i) => ({
    id,
    name: `Name ${id}`,
    status,
    owner: owners[i]!,
    qty
  }));
}

const BY_STATUS: SheetGroupBy[] = [{ field: 'status', direction: 'asc' }];

const group = (
  key: string,
  value: unknown,
  extra: Partial<SheetGroup> = {}
): SheetGroup => ({ key, depth: 0, value, count: 2, loaded: 2, ...extra });

const threeGroups = (): SheetGroup[] => [
  group('status:Open', 'Open'),
  group('status:Doing', 'Doing'),
  group('status:Done', 'Done')
];

/** Waits a frame: the outlines are placed after the grid's render. */
async function frames(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

class State {
  @tracked records: Row[] = rows();
  @tracked groups: SheetGroup[] = threeGroups();
  changes: ChangeSet[] = [];
  onChange = (changeSet: ChangeSet) => this.changes.push(changeSet);
}

/** The grid rows by kind, in order, short: `g` a header, `r` a record, `a` an add row. */
function kinds(): string {
  return [...document.querySelectorAll<HTMLElement>('.euiDataGridRow')]
    .sort(
      (a, b) =>
        Number(a.dataset['gridRowIndex']) - Number(b.dataset['gridRowIndex'])
    )
    .map((row) =>
      row.classList.contains('euiSheet__groupRow')
        ? 'g'
        : row.classList.contains('euiSheet__addRow')
          ? 'a'
          : 'r'
    )
    .join('');
}

function gridRow(row: number): HTMLElement {
  return el(`.euiDataGridRow[data-grid-row-index="${row}"]`);
}

/** The focused cell as `row:col` (data column; `offset` control columns before it). */
function focusedAt(offset = 1): string {
  const active = (document.activeElement as HTMLElement).closest<HTMLElement>(
    '[role=gridcell]'
  );
  if (!active) return 'none';
  return `${active.dataset['gridcellVisibleRowIndex']}:${Number(active.dataset['gridcellColumnIndex']) - offset}`;
}

/** A data cell when the sheet has no row-number column. */
function bareCell(row: number, col: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${col}"]`
  );
}

function sorted(list: string[]): string[] {
  return [...list].sort();
}

function rowNumberCell(row: number): HTMLElement {
  return el(':scope > .euiSheet__rowCell', gridRow(row));
}

/** The boxes of an outline (range, copied, flash, fill), when it shows. */
function boxes(subj: string): DOMRect[] {
  const clip = document.querySelector<HTMLElement>(`[data-test-subj=${subj}]`);
  if (!clip || clip.style.display === 'none') return [];
  return [...clip.children]
    .map((child) => child.getBoundingClientRect())
    .sort((a, b) => a.top - b.top);
}

/** The union of row `row`'s cells `from`..`to`. */
function union(row: number, from: number, to: number): DOMRect {
  const first = cell(row, from).getBoundingClientRect();
  const last = cell(row, to).getBoundingClientRect();
  return new DOMRect(
    first.left,
    first.top,
    last.right - first.left,
    first.height
  );
}

/** The union of rows `top`..`bottom`'s cells `from`..`to`. */
function block(top: number, bottom: number, from: number, to: number): DOMRect {
  const a = union(top, from, to);
  const b = union(bottom, from, to);
  return new DOMRect(a.left, a.top, b.right - a.left, b.bottom - a.top);
}

function off(a: DOMRect, b: DOMRect): number {
  return Math.max(
    Math.abs(a.left - b.left),
    Math.abs(a.top - b.top),
    Math.abs(a.right - b.right),
    Math.abs(a.bottom - b.bottom)
  );
}

/** Whether a box covers any part of a grid row (vertically, 1 px of slack). */
function overRow(box: DOMRect, row: number): boolean {
  const line = gridRow(row).getBoundingClientRect();
  return box.bottom > line.top + 1 && box.top < line.bottom - 1;
}

async function mouseAt(
  kind: 'mousemove' | 'mouseup',
  x: number,
  y: number
): Promise<void> {
  document.dispatchEvent(
    new MouseEvent(kind, {
      bubbles: true,
      cancelable: true,
      clientX: x,
      clientY: y,
      button: 0
    })
  );
  await settled();
}

function center(element: Element): { x: number; y: number } {
  const box = element.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
}

module(
  'Integration | Component | EuiSheet groups, moving and copying',
  function (hooks) {
    setupRenderingTest(hooks);

    async function renderSheet(
      state: State,
      options: {
        canInsert?: boolean;
        rowNumbers?: boolean;
        height?: number;
      } = {}
    ): Promise<void> {
      const canInsert = options.canInsert ?? true;
      const rowNumbers = options.rowNumbers ?? true;
      const height = options.height ?? 600;
      await render(
        <template>
          <EuiSheet
            @fields={{FIELDS}}
            @records={{state.records}}
            @groups={{state.groups}}
            @groupBy={{BY_STATUS}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @canInsert={{canInsert}}
            @rowNumbers={{rowNumbers}}
            @height={{height}}
          />
        </template>
      );
    }

    /** A `localRecords` store grouped by status (Doing, Done, Open): it applies the change sets. */
    async function renderStore(owners?: string[]) {
      const store = localRecords<Row>(rows(owners), {
        getRecordId: getId,
        fields: FIELDS,
        groupBy: BY_STATUS
      });
      await render(
        <template>
          <EuiSheet
            @fields={{FIELDS}}
            @records={{store.view.records}}
            @groups={{store.view.groups}}
            @groupBy={{store.groupBy}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @height={{600}}
          />
        </template>
      );
      return store;
    }

    /* Keys (V03 8.6) */

    test('GR5 ArrowDown from a record to the header to the next record keeps the column; ArrowUp back', async function (assert) {
      const state = new State();
      await renderSheet(state, { canInsert: false });
      assert.strictEqual(kinds(), 'grrgrrgrr');
      await focusCell(2, 2);
      await press('ArrowDown');
      assert.strictEqual(focusedAt(), '3:2', 'the header, in the same column');
      assert.deepEqual(selected(), [], 'nothing selected on the header');
      await press('ArrowDown');
      assert.strictEqual(focusedAt(), '4:2', 'the next group’s first record');
      assert.deepEqual(selected(), ['4:2']);
      await press('ArrowUp');
      assert.strictEqual(focusedAt(), '3:2');
      await press('ArrowUp');
      assert.strictEqual(focusedAt(), '2:2', 'back on the record');
      assert.deepEqual(selected(), ['2:2']);
    });

    test('GR11 Ctrl+A selects all records, Delete clears them; Ctrl+ArrowDown jumps by the records’ values across headers', async function (assert) {
      const state = new State();
      state.records = rows(['Ana', 'Bo', 'Ana', '', '', 'Bo']);
      await renderSheet(state);
      assert.strictEqual(kinds(), 'grragrragrra');
      await focusCell(1, 0);
      assert.true(
        await pressed('a', { ctrlKey: true }),
        'Ctrl+A is the sheet’s'
      );
      const all = [1, 2, 5, 6, 9, 10].flatMap((row) =>
        [0, 1, 2, 3].map((col) => `${row}:${col}`)
      );
      assert.deepEqual(
        selected(),
        sorted(all),
        'every record cell, no header or add row'
      );
      assert.strictEqual(focusedAt(), '1:0', 'focus stays');
      await press('Delete');
      assert.strictEqual(state.changes.length, 1, 'one change set');
      assert.deepEqual(
        [...new Set(state.changes[0]!.patches.map((p) => p.recordId))].sort(),
        ['r0', 'r1', 'r2', 'r3', 'r4', 'r5'],
        'it clears the six records'
      );

      // owners: Ana, Bo | Ana, '' | '', Bo
      await focusCell(1, 2);
      await press('ArrowDown', { ctrlKey: true });
      await waitUntil(() => focusedAt() !== '1:2');
      assert.strictEqual(
        focusedAt(),
        '5:2',
        'to the end of the block, over a header'
      );
      await press('ArrowDown', { ctrlKey: true });
      await waitUntil(() => focusedAt() !== '5:2');
      assert.strictEqual(
        focusedAt(),
        '10:2',
        'to the next value, over a header'
      );
      assert.true(await pressed('ArrowDown', { ctrlKey: true }), 'at the edge');
      assert.strictEqual(focusedAt(), '10:2', 'stays');
      await press('ArrowUp', { ctrlKey: true });
      await waitUntil(() => focusedAt() !== '10:2');
      assert.strictEqual(focusedAt(), '5:2', 'back up to the next value');
    });

    test('GR11 Ctrl+ArrowUp and Ctrl+ArrowDown from a group’s add row start from that group’s last record', async function (assert) {
      const state = new State();
      await renderSheet(state);
      // names are all filled: from a record, the jump goes to the block's end
      await focusCell(7, 0);
      assert.strictEqual(focusedAt(), '7:0', 'the Doing group’s add row');
      await press('ArrowUp', { ctrlKey: true });
      await waitUntil(() => focusedAt() !== '7:0');
      assert.strictEqual(
        focusedAt(),
        '6:0',
        'Ctrl+Up: the group’s last record'
      );
      await focusCell(7, 0);
      await press('ArrowDown', { ctrlKey: true });
      await waitUntil(() => focusedAt() !== '7:0');
      assert.strictEqual(
        focusedAt(),
        '9:0',
        'Ctrl+Down: the next group’s first record'
      );
      // the last group's add row: nothing below
      await focusCell(11, 0);
      assert.true(await pressed('ArrowDown', { ctrlKey: true }));
      assert.strictEqual(focusedAt(), '11:0', 'no record below: stays');
      // left and right do not move on an add row (v0.2)
      await focusCell(7, 1);
      assert.true(await pressed('ArrowRight', { ctrlKey: true }));
      assert.strictEqual(focusedAt(), '7:1', 'Ctrl+Right: stays');
      // a header too is a gap between two records
      await focus(cell(4, 0));
      await press('ArrowUp', { ctrlKey: true });
      await waitUntil(() => focusedAt() !== '4:0');
      assert.strictEqual(
        focusedAt(),
        '2:0',
        'Ctrl+Up from a header: the record above it'
      );
      assert.strictEqual(state.changes.length, 0, 'no change');
    });

    test('GR11 PageUp and PageDown, with Shift too, never land on a header', async function (assert) {
      // a group of one record, thirty collapsed groups, a group of five
      const state = new State();
      state.records = Array.from({ length: 6 }, (_, i) => ({
        id: `r${i}`,
        name: `Name r${i}`,
        status: i ? 'Last' : 'First',
        owner: 'Ana',
        qty: i
      }));
      state.groups = [
        group('status:First', 'First', { count: 1, loaded: 1 }),
        ...Array.from({ length: 30 }, (_, i) =>
          group(`status:C${i}`, `C${i}`, { collapsed: true, loaded: 0 })
        ),
        group('status:Last', 'Last', { count: 5, loaded: 5 })
      ];
      await renderSheet(state, { canInsert: false });
      // rows: 0 header, 1 r0, 2-31 headers, 32 header, 33-37 r1-r5
      await focusCell(1, 1);
      assert.true(await pressed('PageDown'), 'the sheet’s');
      await waitUntil(() => focusedAt() !== '1:1');
      assert.strictEqual(
        focusedAt(),
        '33:1',
        'over the headers to the next record'
      );
      assert.deepEqual(selected(), ['33:1']);
      await press('PageUp');
      await waitUntil(() => focusedAt() !== '33:1');
      assert.strictEqual(focusedAt(), '1:1', 'back over the headers');
      // PageUp near the top: row 0 is a header, the first record instead
      await press('PageUp');
      await settled();
      assert.strictEqual(focusedAt(), '1:1', 'not row 0');

      // Shift: the head moves, on records only; focus stays on the active cell
      await press('PageDown', { shiftKey: true });
      await waitUntil(() => selected().includes('33:1'));
      assert.false(
        selected().some((pos) => pos !== '1:1' && pos !== '33:1'),
        'the head is on r1, nothing between'
      );
      const copied = await clipboard('copy');
      assert.strictEqual(
        copied.text,
        'First\nLast',
        'two records, no header line'
      );
      await press('PageUp', { shiftKey: true });
      await waitUntil(() => !selected().includes('33:1'));
      assert.deepEqual(selected(), ['1:1'], 'the head back on r0');
      assert.strictEqual(state.changes.length, 0);
    });

    for (const rowNumbers of [true, false]) {
      test(`GR11 Ctrl+Home and Ctrl+End land on records when a header is first or last (row numbers ${rowNumbers})`, async function (assert) {
        const state = new State();
        state.records = rows().slice(0, 4);
        state.groups = [
          group('status:Open', 'Open'),
          group('status:Doing', 'Doing'),
          group('status:Done', 'Done', { collapsed: true, loaded: 0 })
        ];
        await renderSheet(state, { canInsert: false, rowNumbers });
        assert.strictEqual(kinds(), 'grrgrrg', 'a collapsed last group');
        const offset = rowNumbers ? 1 : 0;
        const at = (row: number, col: number) =>
          rowNumbers ? cell(row, col) : bareCell(row, col);
        await focus(at(2, 1));
        assert.true(
          await pressed('End', { ctrlKey: true }),
          'Ctrl+End is the sheet’s'
        );
        await waitUntil(() => focusedAt(offset) !== '2:1');
        assert.strictEqual(
          focusedAt(offset),
          '5:3',
          'the last record, last field'
        );
        assert.true(
          await pressed('Home', { ctrlKey: true }),
          'Ctrl+Home is the sheet’s'
        );
        await waitUntil(() => focusedAt(offset) !== '5:3');
        assert.strictEqual(
          focusedAt(offset),
          '1:0',
          'the first record, not the header'
        );
        assert.strictEqual(state.changes.length, 0);
      });
    }

    test('GR11 Shift+Ctrl+End and Shift+Ctrl+Home extend to the records’ corners', async function (assert) {
      const state = new State();
      state.records = rows().slice(0, 4);
      state.groups = [
        group('status:Open', 'Open'),
        group('status:Doing', 'Doing'),
        group('status:Done', 'Done', { collapsed: true, loaded: 0 })
      ];
      await renderSheet(state, { canInsert: false });
      await focusCell(2, 1);
      await press('End', { ctrlKey: true, shiftKey: true });
      assert.deepEqual(
        selected(),
        sorted(['2:1', '2:2', '2:3', '4:1', '4:2', '4:3', '5:1', '5:2', '5:3']),
        'to the last record, last field'
      );
      assert.strictEqual(focusedAt(), '2:1', 'focus stays');
      await press('Home', { ctrlKey: true, shiftKey: true });
      assert.deepEqual(
        selected(),
        sorted(['1:0', '1:1', '2:0', '2:1']),
        'to the first record, first field'
      );
    });

    test('GR11 the move after a commit skips headers and add rows', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focusCell(2, 0);
      await type('x');
      assert.ok(editor(), 'editing r1');
      await press('Enter');
      assert.strictEqual(editor(), null, 'saved');
      assert.strictEqual(state.changes[0]?.patches[0]?.recordId, 'r1');
      await waitUntil(() => focusedAt() !== '2:0');
      assert.strictEqual(focusedAt(), '5:0', 'over the add row and the header');
      assert.deepEqual(selected(), ['5:0']);
      // Tab and Shift+Tab stay on the row
      await type('y');
      await press('Tab');
      await waitUntil(() => focusedAt() === '5:1');
      await type('z');
      await press('Tab', { shiftKey: true });
      await waitUntil(() => focusedAt() === '5:0');
      assert.strictEqual(state.changes.length, 3);
      // the last record: nothing below but the add row, it stays
      await focusCell(10, 0);
      await type('w');
      await press('Enter');
      await settled();
      assert.strictEqual(focusedAt(), '10:0', 'stays on the last record');
    });

    test('GR11 without add rows, Enter commits and moves over the header', async function (assert) {
      const state = new State();
      await renderSheet(state, { canInsert: false });
      await focusCell(2, 2);
      await type('x');
      await press('Enter');
      await waitUntil(() => focusedAt() !== '2:2');
      assert.strictEqual(focusedAt(), '4:2', 'the next group’s first record');
    });

    test('GR17 typing on a header row opens no editor; typing on the record below it edits that record', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focus(cell(4, 2));
      assert.strictEqual(focusedAt(), '4:2', 'the Doing header');
      await type('x');
      assert.strictEqual(editorFrame(), null, 'no editor');
      assert
        .dom('[data-test-subj=euiSheetEditor]', document.body)
        .doesNotExist();
      await press('F2');
      await press('Delete');
      assert.strictEqual(editorFrame(), null, 'still none');
      assert.strictEqual(state.changes.length, 0, 'no change set');
      await press('ArrowDown');
      assert.strictEqual(focusedAt(), '5:2', 'the record below');
      await type('y');
      assert.strictEqual(editor()?.value, 'y', 'its editor, with the key');
      await press('Enter');
      assert.deepEqual(
        state.changes.map((c) =>
          c.patches.map((p) => [p.recordId, p.fieldId, p.to])
        ),
        [[['r2', 'owner', 'y']]],
        'that record is edited'
      );
    });

    test('GR17 a key that stays on a header leaves no range there: paste, Delete and Ctrl+D do nothing', async function (assert) {
      const state = new State();
      await renderSheet(state);
      // Ctrl+Right on a header does not move (an add row's rule)
      await focus(cell(4, 1));
      assert.true(await pressed('ArrowRight', { ctrlKey: true }));
      assert.strictEqual(focusedAt(), '4:1', 'stays on the header');
      let pasted = await clipboard('paste', 'Z');
      assert.false(pasted.prevented, 'the paste is not taken');
      await press('Delete');
      await pressed('d', { ctrlKey: true });
      // Ctrl+Up on the first header: nothing above
      await focus(cell(0, 1));
      assert.true(await pressed('ArrowUp', { ctrlKey: true }));
      assert.strictEqual(focusedAt(), '0:1', 'stays on the first header');
      pasted = await clipboard('paste', 'Z');
      assert.false(pasted.prevented);
      // Shift+Home on a header already in the first column
      await focus(cell(4, 0));
      await press('Home', { shiftKey: true });
      pasted = await clipboard('paste', 'Z');
      assert.false(pasted.prevented);
      assert.deepEqual(selected(), [], 'nothing selected');
      assert.strictEqual(state.changes.length, 0, 'no record written');
    });

    test('3a site flashCells: the flash of a paste across a header is boxed per group', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focusCell(1, 1);
      await clipboard('paste', 'a\nb\nc\nd');
      assert.deepEqual(
        state.changes[0]!.patches.map((p) => p.recordId),
        ['r0', 'r1', 'r2', 'r3']
      );
      await frames();
      const flash = boxes('euiSheetFlash');
      assert.strictEqual(flash.length, 2, 'two groups, two boxes');
      assert.true(off(flash[0]!, block(1, 2, 1, 1)) <= 1, 'r0 and r1');
      assert.true(off(flash[1]!, block(5, 6, 1, 1)) <= 1, 'r2 and r3');
      for (const row of [0, 3, 4, 7]) {
        assert.false(
          flash.some((box) => overRow(box, row)),
          `nothing over row ${row}`
        );
      }
    });

    /* Mouse and the drawn range (V03 8.5) */

    test('GR6 Shift+ArrowDown across a header selects the records on both sides; copy gives their lines only; the copy mark boxes each run', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focusCell(2, 0);
      await press('ArrowDown', { shiftKey: true });
      assert.deepEqual(
        selected(),
        ['2:0', '5:0'],
        'r1 and r2, not the add row or the header'
      );
      await press('ArrowRight', { shiftKey: true });
      const copied = await clipboard('copy');
      assert.true(copied.prevented);
      assert.strictEqual(
        copied.text,
        'Name r1\tOpen\nName r2\tDoing',
        'no header line'
      );
      await frames();
      const marks = boxes('euiSheetCopiedOutline');
      assert.strictEqual(marks.length, 2, 'the copy mark: one box per group');
      assert.false(
        marks.some((box) => overRow(box, 3) || overRow(box, 4)),
        'none over the add row or the header'
      );
      await press('ArrowUp', { shiftKey: true });
      assert.deepEqual(selected(), ['2:0', '2:1'], 'back over the header');
    });

    test('GR6 Shift+click and a drag across a header select the records on both sides', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focusCell(2, 0);
      await triggerEvent(cell(5, 1), 'mousedown', {
        button: 0,
        shiftKey: true
      });
      await triggerEvent(cell(5, 1), 'click', { button: 0, shiftKey: true });
      assert.deepEqual(selected(), ['2:0', '2:1', '5:0', '5:1'], 'Shift+click');
      assert.strictEqual(focusedAt(), '2:0', 'focus stays on the active cell');

      await focusCell(1, 2);
      await triggerEvent(cell(1, 2), 'mousedown', { button: 0 });
      for (const [row, col] of [
        [2, 2],
        [3, 2],
        [4, 2],
        [5, 3]
      ] as const) {
        await triggerEvent(cell(row, col), 'mouseover');
      }
      assert.deepEqual(
        selected(),
        sorted(['1:2', '1:3', '2:2', '2:3', '5:2', '5:3']),
        'a drag over the add row and the header to the next record'
      );
      await triggerEvent(cell(5, 3), 'mouseup', { button: 0 });
      await triggerEvent(cell(5, 3), 'click', { button: 0 });
      assert.deepEqual(
        selected(),
        sorted(['1:2', '1:3', '2:2', '2:3', '5:2', '5:3']),
        'kept after the release'
      );
      assert.strictEqual(editorFrame(), null, 'no editor');
      assert.strictEqual(
        (await clipboard('copy')).text,
        'Ana\t1\nBo\t2\nAna\t3'
      );
    });

    test('3a site isRowMarked and the column marks: across a header, the records’ row numbers and the range’s columns', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focusCell(2, 0);
      await press('ArrowDown', { shiftKey: true });
      await press('ArrowRight', { shiftKey: true });
      for (const row of [0, 1, 2, 3, 4, 5, 6]) {
        const marked = rowNumberCell(row).classList.contains(
          'euiSheet__rowCell--marked'
        );
        assert.strictEqual(
          marked,
          row === 2 || row === 5,
          `row ${row}: marked ${marked}`
        );
      }
      const headerOf = (col: number) =>
        el(`.euiDataGridHeaderCell[data-gridcell-column-index="${col + 1}"]`);
      assert.notStrictEqual(
        getComputedStyle(headerOf(0)).backgroundImage,
        'none',
        'Name is marked'
      );
      assert.notStrictEqual(
        getComputedStyle(headerOf(1)).backgroundImage,
        'none',
        'Status is marked'
      );
      assert.strictEqual(
        getComputedStyle(headerOf(2)).backgroundImage,
        'none',
        'Owner is not'
      );
      // the header row and the add row get no selection, no tint
      for (const row of [3, 4]) {
        assert
          .dom('.euiSheet__cell--selected', gridRow(row))
          .doesNotExist(`row ${row}: nothing selected`);
        assert.dom('[aria-selected=true]', gridRow(row)).doesNotExist();
      }
    });

    test('3a sites rangeOutline and placeRangeOutline: one box per run of records, none over a header or an add row', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focusCell(2, 0);
      await frames();
      assert.deepEqual(
        boxes('euiSheetRangeOutline'),
        [],
        'one cell: no outline'
      );
      await press('ArrowDown', { shiftKey: true });
      await frames();
      assert
        .dom('[data-test-subj=euiSheet]')
        .hasClass('euiSheet--ranged', 'two records in one column are a range');
      let drawn = boxes('euiSheetRangeOutline');
      assert.strictEqual(drawn.length, 2, 'two boxes');
      assert.true(
        off(drawn[0]!, block(2, 2, 0, 0)) <= 1,
        'the first around r1'
      );
      assert.true(
        off(drawn[1]!, block(5, 5, 0, 0)) <= 1,
        'the second around r2'
      );
      assert.false(
        drawn.some((box) => overRow(box, 3) || overRow(box, 4)),
        'neither over the add row or the header'
      );

      // Ctrl+A: one box per group
      await pressed('a', { ctrlKey: true });
      await frames();
      drawn = boxes('euiSheetRangeOutline');
      assert.strictEqual(drawn.length, 3, 'three groups, three boxes');
      assert.true(off(drawn[0]!, block(1, 2, 0, 3)) <= 1, 'Open’s records');
      assert.true(off(drawn[1]!, block(5, 6, 0, 3)) <= 1, 'Doing’s records');
      assert.true(off(drawn[2]!, block(9, 10, 0, 3)) <= 1, 'Done’s records');
      for (const row of [0, 3, 4, 7, 8, 11]) {
        assert.false(
          drawn.some((box) => overRow(box, row)),
          `nothing over row ${row}`
        );
      }

      // back to a range inside one group: one box again
      await focusCell(5, 1);
      await press('ArrowDown', { shiftKey: true });
      await frames();
      drawn = boxes('euiSheetRangeOutline');
      assert.strictEqual(drawn.length, 1, 'one group: one box');
      assert.true(off(drawn[0]!, block(5, 6, 1, 1)) <= 1);
    });

    test('3a site followRecords: grouped, a lost head is clamped onto a record, not a header', async function (assert) {
      const state = new State();
      await renderSheet(state, { canInsert: false });
      // 0 header, 1 r0, 2 r1, 3 header, 4 r2, 5 r3, 6 header, 7 r4, 8 r5
      await focusCell(5, 1);
      // the owner removes r3: its row (5) is now the Done header
      state.records = state.records.filter((row) => row.id !== 'r3');
      state.groups = [
        group('status:Open', 'Open'),
        group('status:Doing', 'Doing', { count: 1, loaded: 1 }),
        group('status:Done', 'Done')
      ];
      await settled();
      assert.strictEqual(kinds(), 'grrgrgrr');
      await waitUntil(() => focusedAt() !== '5:1');
      assert.strictEqual(focusedAt(), '4:1', 'the record above the header');
      assert.deepEqual(selected(), ['4:1']);
      assert.strictEqual(state.changes.length, 0);
    });

    /* Clipboard (V03 8.5, D14) */

    test('GR7 a paste of 3 lines on a group’s last record writes 1 line there and 2 into the next group’s first records; the head and the flash follow those rows', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focusCell(2, 2);
      const pasted = await clipboard('paste', 'X\nY\nZ');
      assert.true(pasted.prevented);
      assert.strictEqual(state.changes.length, 1);
      assert.deepEqual(
        state.changes[0]!.patches.map((p) => [p.recordId, p.fieldId, p.to]),
        [
          ['r1', 'owner', 'X'],
          ['r2', 'owner', 'Y'],
          ['r3', 'owner', 'Z']
        ],
        'r1, then r2 and r3 over the add row and the header'
      );
      assert.deepEqual(state.changes[0]!.inserts, [], 'no insert');
      assert.deepEqual(
        selected(),
        ['2:2', '5:2', '6:2'],
        'the range is the three records'
      );
      await frames();
      const flash = boxes('euiSheetFlash');
      assert.strictEqual(flash.length, 2, 'the flash: one box per group');
      assert.true(off(flash[0]!, block(2, 2, 2, 2)) <= 1, 'r1');
      assert.true(off(flash[1]!, block(5, 6, 2, 2)) <= 1, 'r2 and r3');
      assert.false(flash.some((box) => overRow(box, 3) || overRow(box, 4)));
    });

    test('GR7 a paste of 3 lines across a header into a 2-row selection tiles by the records', async function (assert) {
      const state = new State();
      await renderSheet(state);
      // r1 and r2 selected (a header and an add row between): a 2-line block fills it once
      await focusCell(2, 0);
      await press('ArrowDown', { shiftKey: true });
      await clipboard('paste', 'A\nB');
      assert.deepEqual(
        state.changes[0]!.patches.map((p) => [p.recordId, p.to]),
        [
          ['r1', 'A'],
          ['r2', 'B']
        ]
      );
      // one line into the 2-record selection: both records get it
      await clipboard('paste', 'C');
      assert.deepEqual(
        state.changes[1]!.patches.map((p) => [p.recordId, p.to]),
        [
          ['r1', 'C'],
          ['r2', 'C']
        ],
        'tiled over the two records, not three rows'
      );
    });

    test('GR7 lines past the last record are inserts in the last group: its values, groupKey, anchored after its last record', async function (assert) {
      const store = await renderStore();
      // Doing r2 r3 | Done r4 r5 | Open r0 r1
      assert.strictEqual(kinds(), 'grragrragrra');
      await focusCell(9, 2);
      await clipboard('paste', 'P\nQ\nR\nS');
      const set = store.log[0]!;
      assert.deepEqual(
        set.patches.map((p) => [p.recordId, p.to]),
        [
          ['r0', 'P'],
          ['r1', 'Q']
        ]
      );
      assert.deepEqual(
        set.inserts.map((insert) => ({
          values: insert.values,
          groupKey: insert.groupKey,
          anchor: insert.anchor?.recordId
        })),
        [
          {
            values: { owner: 'R', status: 'Open' },
            groupKey: 'status:Open',
            anchor: 'r1'
          },
          {
            values: { owner: 'S', status: 'Open' },
            groupKey: 'status:Open',
            anchor: set.inserts[0]!.tempId
          }
        ],
        'two inserts in Open'
      );
      assert.deepEqual(
        set.inserts.map((insert) => insert.index),
        [6, 7]
      );
      assert.strictEqual(
        kinds(),
        'grragrragrrrra',
        'the owner put them in Open'
      );
      assert.strictEqual(text(11, 2), 'R');
      assert.strictEqual(text(12, 2), 'S');
      assert.strictEqual(text(12, 1), 'Open');
      assert.deepEqual(
        selected(),
        sorted(['9:2', '10:2', '11:2', '12:2']),
        'the range is the four lines'
      );
    });

    test('GR8 a paste of 2 lines on a group’s add row: 2 inserts with the group’s value, groupKey and an anchor after its last record', async function (assert) {
      const store = await renderStore();
      await focusCell(3, 0);
      assert.strictEqual(focusedAt(), '3:0', 'Doing’s add row');
      const pasted = await clipboard('paste', 'New 1\tOpen\nNew 2');
      assert.true(pasted.prevented, 'taken');
      const set = store.log[0]!;
      assert.deepEqual(set.patches, [], 'nothing written over a record');
      assert.deepEqual(
        set.inserts.map((insert) => ({
          index: insert.index,
          values: insert.values,
          groupKey: insert.groupKey,
          anchor: insert.anchor
        })),
        [
          {
            index: 2,
            values: { name: 'New 1', status: 'Doing' },
            groupKey: 'status:Doing',
            anchor: { recordId: 'r3', position: 'after' }
          },
          {
            index: 3,
            values: { name: 'New 2', status: 'Doing' },
            groupKey: 'status:Doing',
            anchor: { recordId: set.inserts[0]!.tempId, position: 'after' }
          }
        ],
        'the group’s value wins over a pasted one'
      );
      assert.strictEqual(kinds(), 'grrrragrragrra', 'both in Doing');
      assert.strictEqual(text(3, 0), 'New 1');
      assert.strictEqual(text(4, 0), 'New 2');
      assert.strictEqual(text(3, 1), 'Doing');
      assert.strictEqual(text(7, 0), 'Name r4', 'Done’s records untouched');
      assert.deepEqual(
        selected(),
        sorted(['3:0', '3:1', '4:0', '4:1']),
        'the range is the new records'
      );
    });

    test('GR8 a paste on an empty group’s add row: inserts with no anchor', async function (assert) {
      const state = new State();
      state.groups = [
        group('status:Open', 'Open'),
        group('status:Doing', 'Doing'),
        group('status:Done', 'Done'),
        group('status:Later', 'Later', { count: 0, loaded: 0 })
      ];
      await renderSheet(state);
      assert.strictEqual(kinds(), 'grragrragrraga');
      await focusCell(13, 0);
      await clipboard('paste', 'L');
      assert.deepEqual(
        state.changes[0]!.inserts.map((insert) => [
          insert.index,
          insert.values,
          insert.groupKey,
          insert.anchor
        ]),
        [[6, { name: 'L', status: 'Later' }, 'status:Later', undefined]]
      );
    });

    /* Fill (V03 8.5) */

    test('GR10 the fill handle dragged over a header fills the records below it; the preview is not drawn on the header or the add row', async function (assert) {
      const state = new State();
      // qty 1, 2 | 30, 40: the series 3, 4 changes them
      state.records = state.records.map((row, k) =>
        k === 2 || k === 3 ? { ...row, qty: (k + 1) * 10 } : row
      );
      await renderSheet(state);
      await focusCell(1, 3);
      await press('ArrowDown', { shiftKey: true });
      assert.deepEqual(selected(), ['1:3', '2:3'], 'qty 1 and 2');
      const square = el('[data-test-subj=euiSheetFillHandle]');
      const start = center(square);
      await triggerEvent(square, 'mousedown', {
        button: 0,
        clientX: start.x,
        clientY: start.y
      });
      const previewed = () =>
        sorted(
          [
            ...document.querySelectorAll<HTMLElement>(
              '.euiSheet__cell--fillPreview'
            )
          ].map(
            (e) =>
              `${e.dataset['gridcellVisibleRowIndex']}:${Number(e.dataset['gridcellColumnIndex']) - 1}`
          )
        );
      // over the header: no record past the source yet
      let to = center(cell(4, 3));
      await mouseAt('mousemove', to.x, to.y);
      assert.deepEqual(previewed(), [], 'over the header: nothing to fill yet');
      to = center(cell(6, 3));
      await mouseAt('mousemove', to.x, to.y);
      assert.deepEqual(
        previewed(),
        ['5:3', '6:3'],
        'the two records below the header, not the add row'
      );
      const dashed = boxes('euiSheetFillOutline');
      assert.strictEqual(
        dashed.length,
        2,
        'the target’s dashed box: one per group'
      );
      assert.false(dashed.some((box) => overRow(box, 3) || overRow(box, 4)));
      await mouseAt('mouseup', to.x, to.y);
      assert.dom('.euiSheet__cell--fillPreview').doesNotExist();
      assert.strictEqual(state.changes.length, 1);
      assert.strictEqual(state.changes[0]!.source, 'fill');
      assert.deepEqual(
        state.changes[0]!.patches.map((p) => [p.recordId, p.fieldId, p.to]),
        [
          ['r2', 'qty', 3],
          ['r3', 'qty', 4]
        ],
        'the series goes on in the records'
      );
      assert.deepEqual(
        selected(),
        ['1:3', '2:3', '5:3', '6:3'],
        'the union is the range'
      );
    });

    test('GR10 Ctrl+D and Ctrl+R over a range that spans a header fill records only', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focusCell(2, 2);
      await press('ArrowDown', { shiftKey: true });
      assert.true(await pressed('d', { ctrlKey: true }));
      assert.deepEqual(
        state.changes[0]!.patches.map((p) => [p.recordId, p.fieldId, p.to]),
        [['r2', 'owner', 'Bo']],
        'Ctrl+D: r1’s value into r2'
      );
      await focusCell(2, 0);
      await press('ArrowDown', { shiftKey: true });
      await press('ArrowRight', { shiftKey: true });
      assert.true(await pressed('r', { ctrlKey: true }));
      assert.deepEqual(
        state.changes[1]!.patches.map((p) => [p.recordId, p.fieldId, p.to]),
        [
          ['r1', 'status', 'Name r1'],
          ['r2', 'status', 'Name r2']
        ],
        'Ctrl+R: the two records'
      );
    });

    test('GR6 a click on a record across the sheet keeps working after a range over a header', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await focusCell(2, 0);
      await press('ArrowDown', { shiftKey: true });
      await click(cell(9, 1));
      assert.deepEqual(
        selected(),
        ['9:1'],
        'a plain click collapses the range'
      );
      assert.deepEqual(boxes('euiSheetRangeOutline'), []);
    });
  }
);
