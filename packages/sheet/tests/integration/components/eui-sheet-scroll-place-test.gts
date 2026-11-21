/**
 * The range outline and the fill handle follow a grid scroll, placed
 * after the scroll's render without a tracked write (READINESS.md,
 * Performance, step 2): TK3-TK4, plain and with a frozen field.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';
import { htmlSafe } from '@ember/template';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, focusCell, press, scrollTo } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const getId = (row: { id: string }) => row.id;

const FIELDS: EuiSheetField<Row>[] = Array.from({ length: 8 }, (_, i) => ({
  id: `f${i}`,
  label: `F${i}`,
  width: 150
}));

const ROWS: Row[] = Array.from({ length: 60 }, (_, row) => {
  const record: Row = { id: `r${row}` };
  for (let col = 0; col < 8; col++) record[`f${col}`] = `${row}-${col}`;
  return record;
});

async function frames(count: number): Promise<void> {
  for (let i = 0; i < count; i++) {
    await new Promise((resolve) => requestAnimationFrame(resolve));
  }
  await settled();
}

async function renderSheet(frozenFields: number): Promise<void> {
  const store = localRecords<Row>(ROWS, { getRecordId: getId });
  const style = htmlSafe('width:700px');
  await render(
    <template>
      <div style={{style}}>
        <EuiSheet
          @records={{store.records}}
          @fields={{FIELDS}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @height={{300}}
          @frozenFields={{frozenFields}}
        />
      </div>
    </template>
  );
}

function handle(): HTMLElement | null {
  const element = document.querySelector<HTMLElement>(
    '[data-test-subj=euiSheetFillHandle]'
  );
  return element && element.style.display !== 'none' ? element : null;
}

function outline(): HTMLElement | null {
  const clip = document.querySelector<HTMLElement>(
    '[data-test-subj=euiSheetRangeOutline]'
  );
  return clip && clip.style.display !== 'none'
    ? (clip.firstElementChild as HTMLElement)
    : null;
}

/** Whether the handle is centred on cell (row, col)'s bottom-right corner and the outline ends there. */
function onCorner(row: number, col: number): boolean {
  const corner = cell(row, col).getBoundingClientRect();
  const box = handle()!.getBoundingClientRect();
  const drawn = outline()!.getBoundingClientRect();
  return (
    Math.abs(box.left + box.width / 2 - corner.right) <= 1 &&
    Math.abs(box.top + box.height / 2 - corner.bottom) <= 1 &&
    Math.abs(drawn.right - corner.right) <= 1 &&
    Math.abs(drawn.bottom - corner.bottom) <= 1
  );
}

module('Integration | Component | EuiSheet scroll placement', function (hooks) {
  setupRenderingTest(hooks);

  test('TK3 a scroll moves the range outline and the fill handle with the range', async function (assert) {
    for (const frozenFields of [0, 1]) {
      await renderSheet(frozenFields);
      await focusCell(3, 1);
      await press('ArrowRight', { shiftKey: true });
      await frames(2);
      assert.ok(handle(), `frozen ${frozenFields}: the handle is shown`);
      assert.true(onCorner(3, 2), `frozen ${frozenFields}: on the corner`);
      const before = handle()!.getBoundingClientRect().top;
      await scrollTo(40);
      await frames(2);
      const after = handle()!.getBoundingClientRect().top;
      assert.true(
        after < before - 10,
        `frozen ${frozenFields}: moved up (${before} → ${after})`
      );
      assert.true(
        onCorner(3, 2),
        `frozen ${frozenFields}: still on the corner`
      );
    }
  });

  test('TK4 the handle hides while its corner is scrolled out of view, and comes back', async function (assert) {
    for (const frozenFields of [0, 1]) {
      await renderSheet(frozenFields);
      await focusCell(3, 1);
      await press('ArrowRight', { shiftKey: true });
      await frames(2);
      assert.ok(handle(), `frozen ${frozenFields}: shown`);
      await scrollTo(900);
      await frames(2);
      assert.strictEqual(handle(), null, `frozen ${frozenFields}: hidden`);
      await scrollTo(0);
      await frames(3);
      assert.ok(handle(), `frozen ${frozenFields}: shown again`);
      assert.true(onCorner(3, 2), `frozen ${frozenFields}: on the corner`);
    }
  });
});
