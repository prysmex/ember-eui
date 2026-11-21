/**
 * The row-number column's width (READINESS-RESULTS.md, "Final checks"):
 * every row number up to the last record's shows in full beside the row's
 * checkbox and expand icon. On a touch screen (`hover: none`) the label,
 * the checkbox and the expand icon all show; with a mouse the checkbox
 * shows only on hover, in the label's place. Headless Chrome matches
 * `hover: none`, so each layout is set by a style of its own: the touch
 * one as the sheet's `hover: none` rules, the mouse one as a row without
 * the mouse over it (the label and the expand icon's room).
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
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  el,
  focusCell,
  pressed,
  resizerOf
} from '../../helpers/sheet.ts';

import type { EuiSheetField, SheetGroup } from '#src/core/index.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';
import type Owner from '@ember/owner';

interface Row {
  id: string;
  name: string;
  status: string;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name', width: 120 },
  { id: 'status', label: 'Status', width: 120 }
];

const rows = (count: number): Row[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    status: i < count / 2 ? 'Open' : 'Done'
  }));

const getId = (row: Row) => row.id;

class State {
  @tracked records: Row[] = rows(3);
  @tracked rowNumberOffset: number | undefined = undefined;
  @tracked rowLabel: ((row: Row, position: number) => string) | undefined =
    undefined;
  @tracked canMove = false;
  @tracked groups: SheetGroup[] | undefined = undefined;
  @tracked frozenFields: number | undefined = undefined;
  onChange = () => {};
}

/** The sheet's `hover: none` rules for the row-number cell: all three parts show. */
const TOUCH_STYLE = `
  .euiSheet__rowCheck { display: inline-block !important; }
  .euiSheet__rowExpand, .euiSheet__rowGrip { visibility: visible !important; }
`;
/** A mouse, not over the row: the label; the expand icon takes its room, hidden. */
const MOUSE_STYLE = `
  .euiSheet__rowCheck { display: none !important; }
  .euiSheet__rowExpand, .euiSheet__rowGrip { visibility: hidden !important; }
`;

function addStyle(css: string): () => void {
  const style = document.createElement('style');
  style.textContent = css;
  document.head.appendChild(style);
  return () => style.remove();
}

const showTouchLayout = () => addStyle(TOUCH_STYLE);
const showMouseLayout = () => addStyle(MOUSE_STYLE);

/** The row-number cells of record rows. */
function rowNumberCells(): HTMLElement[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>('[role=gridcell].euiSheet__rowCell')
  ).filter((cell) => cell.querySelector('[data-test-subj=euiSheetRowLabel]'));
}

/** A box in CSS px (the test container is scaled). */
function rect(element: HTMLElement, scale: number) {
  const box = element.getBoundingClientRect();
  return {
    left: box.left / scale,
    right: box.right / scale,
    width: box.width / scale
  };
}

function scaleOf(element: HTMLElement): number {
  return element.getBoundingClientRect().width / element.offsetWidth;
}

function part(cell: HTMLElement, subj: string): HTMLElement {
  const element = cell.querySelector<HTMLElement>(`[data-test-subj=${subj}]`);
  if (!element) throw new Error(`Missing ${subj}`);
  return element;
}

/**
 * Each row number in full, its checkbox (when shown) after it with a gap,
 * the expand icon after both and inside the cell.
 */
function assertFits(assert: Assert, what: string, expected: string[]): void {
  const cells = rowNumberCells();
  assert.deepEqual(
    cells.map((cell) => part(cell, 'euiSheetRowLabel').textContent),
    expected,
    `${what}: the labels`
  );
  for (const cell of cells) {
    const label = part(cell, 'euiSheetRowLabel');
    const check = part(cell, 'euiSheetRowCheck');
    const expand = part(cell, 'euiSheetRowExpand');
    const name = `${what}, ${label.textContent}`;
    const scale = scaleOf(cell);
    const box = rect(cell, scale);
    const labelBox = rect(label, scale);
    const expandBox = rect(expand, scale);
    assert.true(
      label.scrollWidth <= label.clientWidth,
      `${name}: the number is not cut (${label.scrollWidth} in ${label.clientWidth} px)`
    );
    if (getComputedStyle(check).display !== 'none') {
      const checkBox = rect(check, scale);
      assert.true(
        checkBox.width >= 13.5,
        `${name}: the checkbox keeps its size (${checkBox.width} px)`
      );
      assert.true(
        checkBox.left - labelBox.right >= 2,
        `${name}: a gap between the number and the checkbox (${checkBox.left - labelBox.right} px)`
      );
      assert.true(
        expandBox.left >= checkBox.right,
        `${name}: the expand icon after the checkbox`
      );
    }
    assert.true(
      expandBox.left >= labelBox.right,
      `${name}: the expand icon after the number`
    );
    assert.true(
      expandBox.right <= box.right - 1,
      `${name}: the expand icon inside the cell (${expandBox.right} of ${box.right})`
    );
  }
}

const near = (a: number, b: number) => Math.abs(a - b) < 1.5;

/** Waits (up to 1 s) for `done`, then lets the test assert either way. */
async function until(done: () => boolean): Promise<void> {
  try {
    await waitUntil(done, { timeout: 1000 });
  } catch {
    // the assertion below says what is off
  }
  await settled();
}

/** The labels of `count` records numbered from `offset + 1`. */
const numbers = (offset: number, count: number): string[] =>
  Array.from({ length: count }, (_, i) => String(offset + i + 1));

module(
  'Integration | Component | EuiSheet row-number column width',
  function (hooks) {
    setupRenderingTest(hooks);

    let restore: (() => void) | undefined;

    hooks.afterEach(function () {
      restore?.();
      restore = undefined;
      (
        this.owner.lookup('service:eui-emotion') as EuiEmotionService
      ).colorMode = 'light';
    });

    async function renderSheet(
      owner: Owner,
      state: State,
      mode: 'light' | 'dark' = 'light'
    ): Promise<void> {
      (owner.lookup('service:eui-emotion') as EuiEmotionService).colorMode =
        mode;
      await render(
        <template>
          <div style="width:360px">
            <EuiSheet
              @records={{state.records}}
              @fields={{FIELDS}}
              @getRecordId={{getId}}
              @onChange={{state.onChange}}
              @rowNumberOffset={{state.rowNumberOffset}}
              @rowLabel={{state.rowLabel}}
              @canMove={{state.canMove}}
              @groups={{state.groups}}
              @frozenFields={{state.frozenFields}}
              @height={{400}}
            />
          </div>
        </template>
      );
    }

    // the last record's number: 1 to 6 digits, and 99 -> 100 (the last is the longest)
    const CASES: [string, number][] = [
      ['1 digit', 0],
      ['2 digits', 8],
      ['3 digits', 97],
      ['4 digits', 997],
      ['5 digits', 9_997],
      ['6 digits', 99_997]
    ];

    for (const mode of ['light', 'dark'] as const) {
      test(`RNW1 ${mode}, touch layout: each number up to 6 digits beside its checkbox and expand icon`, async function (assert) {
        restore = showTouchLayout();
        const state = new State();
        await renderSheet(this.owner, state, mode);
        for (const [what, offset] of CASES) {
          state.rowNumberOffset = offset;
          await settled();
          assertFits(assert, what, numbers(offset, 3));
        }
      });

      test(`RNW2 ${mode}, mouse layout: each number up to 6 digits in full, the expand icon beside it`, async function (assert) {
        restore = showMouseLayout();
        const state = new State();
        await renderSheet(this.owner, state, mode);
        for (const [what, offset] of CASES) {
          state.rowNumberOffset = offset;
          await settled();
          assertFits(assert, what, numbers(offset, 3));
        }
      });
    }

    test('RNW3 the column grows with the records: the tenth record, the row drag grip', async function (assert) {
      restore = showTouchLayout();
      const state = new State();
      state.records = rows(9);
      await renderSheet(this.owner, state);
      assertFits(assert, 'nine records', numbers(0, 9));
      const header = () =>
        document.querySelector<HTMLElement>(
          '[role=columnheader][data-gridcell-column-index="0"]'
        )!.offsetWidth;
      const nine = header();
      state.records = rows(10);
      await settled();
      const ten = header();
      assert.true(ten > nine, `wider for "10" (${nine} -> ${ten} px)`);
      assertFits(assert, 'ten records', numbers(0, 10));
      // a change that keeps the digits keeps the width
      state.records = rows(10).map((row) => ({ ...row, name: 'edited' }));
      await settled();
      assert.strictEqual(header(), ten, 'an edit keeps it');
      state.rowNumberOffset = 99_990;
      state.canMove = true;
      await settled();
      assert
        .dom('[data-test-subj=euiSheetRowGrip]', rowNumberCells()[0])
        .exists('the grip shows');
      assertFits(assert, 'with the grip', numbers(99_990, 10));
      const grip = part(rowNumberCells()[0]!, 'euiSheetRowGrip');
      const label = part(rowNumberCells()[0]!, 'euiSheetRowLabel');
      assert.true(
        label.getBoundingClientRect().left >=
          grip.getBoundingClientRect().right,
        'the number after the grip'
      );
    });

    test('RNW4 group starts and @rowLabel: the longest label fits', async function (assert) {
      restore = showTouchLayout();
      const state = new State();
      state.records = rows(4);
      // the first group starts at 123456, the second at 7: the first is the longest
      state.groups = [
        {
          key: 'status:Open',
          depth: 0,
          value: 'Open',
          count: 2,
          loaded: 2,
          rowNumberStart: 123_456
        },
        {
          key: 'status:Done',
          depth: 0,
          value: 'Done',
          count: 2,
          loaded: 2,
          rowNumberStart: 7
        }
      ];
      await renderSheet(this.owner, state);
      assertFits(assert, 'group starts', ['123456', '123457', '7', '8']);
      state.groups = undefined;
      state.rowLabel = (row, position) =>
        `#${position}-${row.id.toUpperCase()}`;
      await settled();
      assertFits(assert, '@rowLabel', ['#1-R0', '#2-R1', '#3-R2', '#4-R3']);
    });

    for (const frozen of [undefined, 1]) {
      test(`RNW5 ${frozen ? 'frozen' : 'not frozen'}: the parts over the grid follow the column when it grows (2 -> 6 digits)`, async function (assert) {
        const state = new State();
        state.rowNumberOffset = 10;
        state.frozenFields = frozen;
        await renderSheet(this.owner, state);
        await click(cell(0, 0));
        await click(cell(1, 1), { shiftKey: true });
        const before = cell(0, 0).getBoundingClientRect().left;
        state.rowNumberOffset = 99_990;
        await settled();
        assert.true(
          cell(0, 0).getBoundingClientRect().left > before,
          'the first field moved right'
        );
        const onRange = () => {
          const handle = el(
            '[data-test-subj=euiSheetFillHandle]'
          ).getBoundingClientRect();
          const corner = cell(1, 1).getBoundingClientRect();
          const drawn = el(
            '[data-test-subj=euiSheetRangeOutline] .euiSheet__range'
          ).getBoundingClientRect();
          const first = cell(0, 0).getBoundingClientRect();
          return (
            near(handle.left + handle.width / 2, corner.right) &&
            near(handle.top + handle.height / 2, corner.bottom) &&
            near(drawn.left, first.left) &&
            near(drawn.right, corner.right)
          );
        };
        await until(onRange);
        assert.true(onRange(), 'the fill handle and the outline on the range');
        const header = el(
          '[role=columnheader][data-gridcell-column-index="1"]'
        ).getBoundingClientRect();
        assert.true(
          near(header.left, cell(0, 0).getBoundingClientRect().left),
          'the first field header over its cells'
        );
      });
    }

    test('RNW6 the tenth record added from the add row: the column grows, focus stays in the grid, a resized field keeps its width', async function (assert) {
      const store = localRecords<Row>(rows(9), { getRecordId: getId });
      await render(
        <template>
          <div style="width:500px">
            <EuiSheet
              @records={{store.records}}
              @fields={{FIELDS}}
              @getRecordId={{getId}}
              @onChange={{store.apply}}
              @height={{700}}
            />
          </div>
        </template>
      );
      const widthOf = (id: string) =>
        el(`[role=columnheader][data-gridcell-column-id="${id}"]`).offsetWidth;
      // a drag of Name first: 120 -> 160
      const resizer = resizerOf(
        el('[role=columnheader][data-gridcell-column-id="name"]')
      );
      await triggerEvent(resizer, 'mousedown', { clientX: 300 });
      await triggerEvent(window as unknown as Element, 'mousemove', {
        clientX: 340
      });
      await triggerEvent(window as unknown as Element, 'mouseup');
      const resized = widthOf('name');
      assert.true(resized > 150, `Name resized (${resized} px)`);
      const nine = widthOf('euiSheetRow');

      // Enter on the add row (grid row 9): the tenth record
      await focusCell(9, 0);
      assert.true(await pressed('Enter'), 'Enter on the add row');
      await settled();
      assert.strictEqual(store.records.length, 10, 'a tenth record');
      assert.true(
        widthOf('euiSheetRow') > nine,
        `the column grew (${nine} -> ${widthOf('euiSheetRow')} px)`
      );
      assert.strictEqual(widthOf('name'), resized, 'Name keeps its width');
      const active = document.activeElement as HTMLElement | null;
      assert.strictEqual(
        active?.getAttribute('role'),
        'gridcell',
        'focus is on a grid cell'
      );
      assertFits(assert, 'ten records', numbers(0, 10));
      // the fill handle on the focused cell's corner
      const atCorner = () => {
        const handle = document.querySelector<HTMLElement>(
          '[data-test-subj=euiSheetFillHandle]'
        );
        const focused = document.activeElement;
        if (!handle || !(focused instanceof HTMLElement)) return false;
        const box = handle.getBoundingClientRect();
        const corner = focused.getBoundingClientRect();
        return (
          near(box.left + box.width / 2, corner.right) &&
          near(box.top + box.height / 2, corner.bottom)
        );
      };
      await until(atCorner);
      assert.true(atCorner(), 'the fill handle on the focused cell');
    });
  }
);
