/**
 * Ranges by touch (V03 11.3, D12; TR1, TR2, TR3b, TR4, TR5): the selection
 * handles after a touch press. Pointer events with `pointerType: 'touch'`
 * in headless Chromium, not a finger. TR3 (a touch move on the grid
 * selects nothing) is the v0.2 touch tests TC1-TC3, unchanged; TR3b adds
 * the case with the handles shown.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  focus,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { frames as autoScrollFrames } from '#src/-private/auto-scroll.ts';
import { localRecords } from '#src/local-records.ts';
import { cell, el, selected } from '../../helpers/sheet.ts';

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

const rowsOf = (count: number): Row[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    city: `city${i}`,
    code: `C${i}`
  }));

/** A pointer event at a point (default: the middle of `target`). */
function pointer(
  type: string,
  target: Element,
  options: { pointerType?: string; x?: number; y?: number } = {}
): PointerEvent {
  const box = target.getBoundingClientRect();
  return new PointerEvent(type, {
    bubbles: true,
    cancelable: true,
    pointerType: options.pointerType ?? 'touch',
    isPrimary: true,
    pointerId: 7,
    clientX: options.x ?? box.left + box.width / 2,
    clientY: options.y ?? box.top + box.height / 2
  });
}

/** A touch tap on a cell: the press, the release, and the focus the browser gives it. */
async function tap(target: HTMLElement): Promise<void> {
  target.dispatchEvent(pointer('pointerdown', target));
  target.dispatchEvent(pointer('pointerup', target));
  await focus(target);
}

function handles(): HTMLElement[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>(
      '[data-test-subj=euiSheetSelectionHandle]'
    )
  );
}

function handle(corner: 'start' | 'end'): HTMLElement {
  return el(`[data-eui-sheet-handle=${corner}]`);
}

/** The middle of a handle's 20 px circle. */
function centre(element: HTMLElement): { x: number; y: number } {
  const box = element.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
}

/** Drags a handle by touch to a point. */
async function dragHandle(
  corner: 'start' | 'end',
  to: { x: number; y: number }
): Promise<void> {
  const element = handle(corner);
  element.dispatchEvent(pointer('pointerdown', element));
  await settled();
  element.dispatchEvent(pointer('pointermove', element, to));
  await settled();
  element.dispatchEvent(pointer('pointerup', element, to));
  await settled();
}

const middleOf = (element: HTMLElement) => centre(element);

async function frames(count: number): Promise<void> {
  for (let i = 0; i < count; i++) {
    await new Promise((resolve) => requestAnimationFrame(resolve));
  }
  await settled();
}

module('Integration | Component | EuiSheet touch ranges', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    // elementFromPoint needs the container on screen
    document.getElementById('ember-testing-container')?.scrollIntoView();
  });

  async function renderSheet(count = 6) {
    const store = localRecords<Row>(rowsOf(count), {
      getRecordId: getId,
      fields: FIELDS
    });
    await render(
      <template>
        <EuiSheet
          @records={{store.records}}
          @fields={{store.fields}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @height={{300}}
        />
      </template>
    );
    return store;
  }

  test('TR1 a touch tap shows two handles on the cell; a mouse click shows none', async function (assert) {
    await renderSheet();
    // the grid sizes its columns after the first render (in the full run
    // the cells moved by a pixel or two after the handles were placed)
    await frames(2);
    await tap(cell(1, 1));
    assert.deepEqual(selected(), ['1:1']);
    assert.strictEqual(handles().length, 2, 'two handles');
    assert.true(
      handles().every((h) => h.style.display !== 'none'),
      'both shown'
    );
    const box = cell(1, 1).getBoundingClientRect();
    const start = centre(handle('start'));
    const end = centre(handle('end'));
    assert.ok(
      Math.abs(start.x - box.left) < 1.5 && Math.abs(start.y - box.top) < 1.5,
      `top-left on the corner (${start.x},${start.y} vs ${box.left},${box.top})`
    );
    assert.ok(
      Math.abs(end.x - box.right) < 1.5 && Math.abs(end.y - box.bottom) < 1.5,
      `bottom-right on the corner (${end.x},${end.y} vs ${box.right},${box.bottom})`
    );
    const style = getComputedStyle(handle('end'));
    assert.strictEqual(style.touchAction, 'none');
    assert.strictEqual(style.width, '44px', 'a 44 px hit area');
    assert.strictEqual(
      getComputedStyle(handle('end'), '::before').width,
      '20px',
      'a 20 px circle'
    );
    assert
      .dom('[data-test-subj=euiSheetFillHandle]')
      .doesNotExist('no fill handle with the handles');
    // a mouse press: no handles (a hybrid device), the fill handle again
    const other = cell(2, 0);
    other.dispatchEvent(
      pointer('pointerdown', other, { pointerType: 'mouse' })
    );
    await click(other);
    assert.deepEqual(selected(), ['2:0']);
    assert.strictEqual(handles().length, 0, 'none after a mouse click');
    assert.dom('[data-test-subj=euiSheetFillHandle]').exists();
  });

  test('TR2 the bottom-right handle extends the range; the top-left one moves the anchor', async function (assert) {
    await renderSheet();
    await tap(cell(1, 1));
    await dragHandle('end', middleOf(cell(3, 2)));
    assert.deepEqual(
      selected(),
      ['1:1', '1:2', '2:1', '2:2', '3:1', '3:2'],
      'extended to 3:2'
    );
    assert.strictEqual(document.activeElement, cell(1, 1), 'focus stays');
    const box = cell(3, 2).getBoundingClientRect();
    const end = centre(handle('end'));
    assert.ok(
      Math.abs(end.x - box.right) < 1.5 && Math.abs(end.y - box.bottom) < 1.5,
      'the handle follows the corner'
    );
    // the top-left handle: the anchor moves, the bottom-right corner stays
    await dragHandle('start', middleOf(cell(0, 0)));
    assert.deepEqual(selected(), [
      '0:0',
      '0:1',
      '0:2',
      '1:0',
      '1:1',
      '1:2',
      '2:0',
      '2:1',
      '2:2',
      '3:0',
      '3:1',
      '3:2'
    ]);
    assert.strictEqual(
      document.activeElement,
      cell(0, 0),
      'the new anchor is the active cell'
    );
    // dragged onto the add row: the corner stays on the last record
    await dragHandle('end', middleOf(cell(6, 1)));
    assert.true(selected().includes('3:2'), 'unchanged over the add row');
    assert.false(selected().some((pos) => pos.startsWith('6:')));
  });

  test('TR3b with the handles shown, a touch move on the grid selects nothing', async function (assert) {
    await renderSheet();
    await tap(cell(1, 1));
    const from = cell(2, 0);
    from.dispatchEvent(pointer('pointerdown', from));
    from.dispatchEvent(
      pointer('pointermove', from, { ...middleOf(cell(4, 2)) })
    );
    await triggerEvent(cell(4, 2), 'mouseover');
    from.dispatchEvent(pointer('pointercancel', from));
    await settled();
    assert.deepEqual(selected(), ['1:1'], 'the range is unchanged');
  });

  test('TR4 near the bottom edge the handle drag feeds auto-scroll', async function (assert) {
    const queue: Array<FrameRequestCallback | null> = [];
    const original = { ...autoScrollFrames };
    autoScrollFrames.request = (callback) => {
      queue.push(callback);
      return queue.length;
    };
    autoScrollFrames.cancel = (id) => {
      queue[id - 1] = null;
    };
    try {
      await renderSheet(200);
      await tap(cell(1, 1));
      const element = handle('end');
      element.dispatchEvent(pointer('pointerdown', element));
      await settled();
      const outer = el('.euiDataGrid__virtualized');
      const bottom = outer.getBoundingClientRect().bottom;
      const x = middleOf(cell(1, 1)).x;
      element.dispatchEvent(
        pointer('pointermove', element, { x, y: bottom - 30 })
      );
      await settled();
      element.dispatchEvent(
        pointer('pointermove', element, { x, y: bottom + 20 })
      );
      await settled();
      assert.strictEqual(queue.filter(Boolean).length, 1, 'the loop started');
      for (let i = 0; i < 10; i++) {
        const now = queue.splice(0, queue.length);
        queue.push(...now.map(() => null));
        for (const callback of now) callback?.(performance.now());
        await settled();
      }
      assert.true(outer.scrollTop > 50, `scrolled to ${outer.scrollTop}`);
      const rows = selected().map((pos) => Number(pos.split(':')[0]));
      assert.true(
        Math.max(...rows) > 8,
        `the range followed the scroll (to row ${Math.max(...rows)})`
      );
      element.dispatchEvent(
        pointer('pointerup', element, { x, y: bottom + 20 })
      );
      await settled();
      assert.strictEqual(queue.filter(Boolean).length, 0, 'stopped');
    } finally {
      Object.assign(autoScrollFrames, original);
    }
  });

  test('TR5 a long press with a range: the menu has Copy and Paste; Copy copies the range', async function (assert) {
    const written: string[] = [];
    const clip = navigator.clipboard as unknown as {
      writeText: (text: string) => Promise<void>;
      readText: () => Promise<string>;
    };
    const originalWrite = Object.getOwnPropertyDescriptor(clip, 'writeText');
    const originalRead = Object.getOwnPropertyDescriptor(clip, 'readText');
    Object.defineProperty(clip, 'writeText', {
      configurable: true,
      value: (value: string) => {
        written.push(value);
        return Promise.resolve();
      }
    });
    Object.defineProperty(clip, 'readText', {
      configurable: true,
      value: () => Promise.resolve('X\tY')
    });
    try {
      const store = await renderSheet();
      await tap(cell(1, 0));
      await dragHandle('end', middleOf(cell(2, 1)));
      const target = cell(2, 1);
      target.dispatchEvent(pointer('pointerdown', target));
      // the 500 ms timer is a run loop timer: settled() waits for it
      await settled();
      assert.dom('[data-test-subj=euiSheetRowMenu]', document.body).exists();
      assert
        .dom('[data-test-subj=euiSheetRowMenu-copyCells]', document.body)
        .hasText('Copy');
      assert
        .dom('[data-test-subj=euiSheetRowMenu-pasteCells]', document.body)
        .hasText('Paste');
      assert.deepEqual(selected(), ['1:0', '1:1', '2:0', '2:1'], 'kept');
      target.dispatchEvent(pointer('pointerup', target));
      await click(el('[data-test-subj=euiSheetRowMenu-copyCells]'));
      assert.deepEqual(written, ['name1\tcity1\nname2\tcity2']);
      assert.dom('.euiSheet__range--copied').exists('the copy mark');
      // Paste: the clipboard's text over the range (tiled: 2 x 1 into 2 x 2)
      target.dispatchEvent(pointer('pointerdown', target));
      await settled();
      target.dispatchEvent(pointer('pointerup', target));
      await click(el('[data-test-subj=euiSheetRowMenu-pasteCells]'));
      // the clipboard is read asynchronously
      await waitUntil(() => store.records[1]?.name === 'X');
      assert.deepEqual(
        store.records.slice(1, 3).map((r) => [r.name, r.city]),
        [
          ['X', 'Y'],
          ['X', 'Y']
        ]
      );
      // a right-click menu has no cell items (the keys copy and paste)
      await triggerEvent(target, 'mousedown', { button: 2 });
      await triggerEvent(target, 'contextmenu', { button: 2 });
      assert
        .dom('[data-test-subj=euiSheetRowMenu-copyCells]', document.body)
        .doesNotExist();
    } finally {
      if (originalWrite)
        Object.defineProperty(clip, 'writeText', originalWrite);
      else delete (clip as { writeText?: unknown }).writeText;
      if (originalRead) Object.defineProperty(clip, 'readText', originalRead);
      else delete (clip as { readText?: unknown }).readText;
    }
  });
});
