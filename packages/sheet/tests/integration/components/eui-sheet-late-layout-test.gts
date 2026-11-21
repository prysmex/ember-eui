/**
 * The parts over the grid follow a layout change that comes after the
 * render they were placed on (READINESS.md item 5, TR1's cause), LL1-LL2:
 * the grid sizes its columns again a frame or more after a render (its
 * scroll bar measured, its container resized), with no change to the
 * parts' arguments. A width change of the sheet's container makes such a
 * change on purpose.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, focus, render, settled, waitUntil } from '@ember/test-helpers';
import { htmlSafe } from '@ember/template';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, el } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  city: string;
  code: string;
}

const getId = (row: Row) => row.id;

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'city', label: 'City' },
  { id: 'code', label: 'Code' }
];

const ROWS: Row[] = Array.from({ length: 6 }, (_, i) => ({
  id: `r${i}`,
  name: `name${i}`,
  city: `city${i}`,
  code: `C${i}`
}));

class Box {
  @tracked width = 900;
  get style() {
    return htmlSafe(`width:${this.width}px`);
  }
}

/** A touch tap on a cell: the press, the release, and the focus the browser gives it. */
async function tap(target: HTMLElement): Promise<void> {
  const box = target.getBoundingClientRect();
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
}

function centre(element: HTMLElement): { x: number; y: number } {
  const box = element.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
}

const near = (a: number, b: number) => Math.abs(a - b) < 1.5;

/** How far a point is from a cell's corner, as text for the messages. */
function offset(
  point: { x: number; y: number },
  corner: { x: number; y: number }
): string {
  return `${(point.x - corner.x).toFixed(1)}, ${(point.y - corner.y).toFixed(1)}`;
}

/** Waits (up to 1 s) for `done`, then lets the test assert either way. */
async function until(done: () => boolean): Promise<void> {
  try {
    await waitUntil(done, { timeout: 1000 });
  } catch {
    // the assertion below says what is off
  }
  await settled();
}

module('Integration | Component | EuiSheet late layout', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    // elementFromPoint needs the container on screen
    document.getElementById('ember-testing-container')?.scrollIntoView();
  });

  async function renderSheet(box: Box): Promise<void> {
    const store = localRecords<Row>(ROWS, {
      getRecordId: getId,
      fields: FIELDS
    });
    await render(
      <template>
        <div style={{box.style}}>
          <EuiSheet
            @records={{store.records}}
            @fields={{store.fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @height={{300}}
          />
        </div>
      </template>
    );
  }

  test('LL1 the touch handles follow the columns the grid sizes after their render', async function (assert) {
    const box = new Box();
    await renderSheet(box);
    await tap(cell(1, 1));
    const before = cell(1, 1).getBoundingClientRect();
    // the container narrows: the grid sizes its columns again, later
    box.width = 600;
    await until(
      () => cell(1, 1).getBoundingClientRect().width < before.width - 20
    );
    const after = cell(1, 1).getBoundingClientRect();
    assert.true(after.width < before.width - 20, 'the column narrowed');
    const start = el('[data-eui-sheet-handle=start]');
    const end = el('[data-eui-sheet-handle=end]');
    const corners = {
      start: { x: after.left, y: after.top },
      end: { x: after.right, y: after.bottom }
    };
    await until(
      () =>
        near(centre(end).x, corners.end.x) &&
        near(centre(start).x, corners.start.x)
    );
    assert.true(
      near(centre(start).x, corners.start.x) &&
        near(centre(start).y, corners.start.y),
      `top-left on the corner (off by ${offset(centre(start), corners.start)})`
    );
    assert.true(
      near(centre(end).x, corners.end.x) && near(centre(end).y, corners.end.y),
      `bottom-right on the corner (off by ${offset(centre(end), corners.end)})`
    );
  });

  test('LL2 the fill handle and the range outline follow them too', async function (assert) {
    const box = new Box();
    await renderSheet(box);
    await click(cell(1, 0));
    await click(cell(2, 1), { shiftKey: true });
    const before = cell(2, 1).getBoundingClientRect();
    box.width = 600;
    await until(
      () => cell(2, 1).getBoundingClientRect().right < before.right - 20
    );
    // not the last column: the handle is moved in at the body's right edge
    const corner = cell(2, 1).getBoundingClientRect();
    const handle = el('[data-test-subj=euiSheetFillHandle]');
    // the clip box is the body; the drawn box is its child
    const outline = el(
      '[data-test-subj=euiSheetRangeOutline] .euiSheet__range'
    );
    await until(() => near(centre(handle).x, corner.right));
    assert.true(
      near(centre(handle).x, corner.right) &&
        near(centre(handle).y, corner.bottom),
      `the fill handle on the corner (off by ${offset(centre(handle), {
        x: corner.right,
        y: corner.bottom
      })})`
    );
    const first = cell(1, 0).getBoundingClientRect();
    const drawn = outline.getBoundingClientRect();
    assert.true(
      near(drawn.left, first.left) && near(drawn.right, corner.right),
      `the outline over the range (${drawn.left.toFixed(1)}-${drawn.right.toFixed(1)} vs ${first.left.toFixed(1)}-${corner.right.toFixed(1)})`
    );
  });
});
