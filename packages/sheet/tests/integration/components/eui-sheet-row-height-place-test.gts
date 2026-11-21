/**
 * The parts over the grid after a row-height change (READINESS.md item 5,
 * v0.4 batch C's screenshot of the fill handle about 90 px above its
 * corner), RH1-RH2. The grid gives the rows their new height after the
 * render that changes `@rowHeight`, so the parts placed on that render
 * were a row-height difference per row above their cell until the next
 * scroll or selection change: a placement bug, not an early screenshot.
 * The grid's content box changing size places them again.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, focus, render, settled, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, el } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { SheetRowHeight } from '#src/types.ts';

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

const ROWS: Row[] = Array.from({ length: 8 }, (_, i) => ({
  id: `r${i}`,
  name: `name${i}`,
  city: `city${i}`,
  code: `C${i}`
}));

const HEIGHTS: SheetRowHeight[] = ['extraTall', 'tall', 'medium', 'short'];

class State {
  @tracked rowHeight: SheetRowHeight = 'short';
}

function centre(element: HTMLElement): { x: number; y: number } {
  const box = element.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
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

module(
  'Integration | Component | EuiSheet row height placement',
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      // elementFromPoint needs the container on screen
      document.getElementById('ember-testing-container')?.scrollIntoView();
    });

    async function renderSheet(state: State): Promise<void> {
      const store = localRecords<Row>(ROWS, {
        getRecordId: getId,
        fields: FIELDS
      });
      await render(
        <template>
          <div style="width:700px">
            <EuiSheet
              @records={{store.records}}
              @fields={{store.fields}}
              @getRecordId={{getId}}
              @onChange={{store.apply}}
              @height={{600}}
              @rowHeight={{state.rowHeight}}
            />
          </div>
        </template>
      );
    }

    test('RH1 the fill handle and the range outline stay on the range at every height', async function (assert) {
      const state = new State();
      await renderSheet(state);
      await click(cell(1, 0));
      await click(cell(2, 1), { shiftKey: true });
      for (const height of HEIGHTS) {
        state.rowHeight = height;
        await settled();
        const handle = el('[data-test-subj=euiSheetFillHandle]');
        const atCorner = () => {
          const corner = cell(2, 1).getBoundingClientRect();
          return (
            near(centre(handle).x, corner.right) &&
            near(centre(handle).y, corner.bottom)
          );
        };
        await until(atCorner);
        const corner = cell(2, 1).getBoundingClientRect();
        assert.true(
          atCorner(),
          `${height}: the fill handle on the corner (off by ${(centre(handle).x - corner.right).toFixed(1)}, ${(centre(handle).y - corner.bottom).toFixed(1)}; the cell ${corner.height.toFixed(1)} px high)`
        );
        const drawn = el(
          '[data-test-subj=euiSheetRangeOutline] .euiSheet__range'
        ).getBoundingClientRect();
        const first = cell(1, 0).getBoundingClientRect();
        assert.true(
          near(drawn.top, first.top) && near(drawn.bottom, corner.bottom),
          `${height}: the outline over the rows (${drawn.top.toFixed(1)}-${drawn.bottom.toFixed(1)} vs ${first.top.toFixed(1)}-${corner.bottom.toFixed(1)})`
        );
      }
    });

    test('RH2 the touch handles too', async function (assert) {
      const state = new State();
      await renderSheet(state);
      const target = cell(2, 1);
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
      for (const height of HEIGHTS) {
        state.rowHeight = height;
        await settled();
        const end = el('[data-eui-sheet-handle=end]');
        const start = el('[data-eui-sheet-handle=start]');
        const placed = () => {
          const now = cell(2, 1).getBoundingClientRect();
          return (
            near(centre(end).y, now.bottom) && near(centre(start).y, now.top)
          );
        };
        await until(placed);
        const now = cell(2, 1).getBoundingClientRect();
        assert.true(
          placed(),
          `${height}: the handles on the cell's corners (top ${(centre(start).y - now.top).toFixed(1)}, bottom ${(centre(end).y - now.bottom).toFixed(1)})`
        );
      }
    });
  }
);
