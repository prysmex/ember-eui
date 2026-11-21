/**
 * A grid scroll places the parts drawn over the grid (outlines, fill
 * handle, selection handles) after its render without a tracked write
 * (READINESS.md, Performance, step 2): TK1-TK2.
 */
import { module, test } from 'qunit';
import { settled } from '@ember/test-helpers';

import SheetScroll from '#src/-private/sheet/scroll.ts';

import type EuiSheet from '#src/components/eui-sheet.gts';

/** The parts of the sheet `onScroll` reads, with nothing open. */
function fakeSheet(): EuiSheet<object> {
  return {
    dom: { isInEditor: () => false },
    fieldEditor: { fieldEditorState: null },
    focus: { gridHadFocus: false, focused: null },
    selection: { anchor: null },
    frozen: { pressing: false, scrollLeftBeforeFocus: null },
    edit: { editing: null },
    ime: { imePos: null },
    rowMenu: { menu: null }
  } as unknown as EuiSheet<object>;
}

function gridScroll(): Event {
  const target = document.createElement('div');
  target.className = 'euiDataGrid__virtualized';
  return { target } as unknown as Event;
}

module('Unit | scroll placement', function () {
  test('TK1 a grid scroll places each registered part after the render, without changing layoutTick', async function (assert) {
    const scroll = new SheetScroll(fakeSheet());
    const placed: string[] = [];
    scroll.placeOnScroll(() => placed.push('outline'));
    scroll.placeOnScroll(() => placed.push('handle'));
    scroll.onScroll(gridScroll());
    assert.deepEqual(placed, [], 'not during the scroll event');
    await settled();
    assert.deepEqual(placed, ['outline', 'handle'], 'after the render');
    assert.strictEqual(scroll.layoutTick, 0, 'no tracked write');
  });

  test('TK2 a removed part is not placed; with none, a scroll schedules nothing', async function (assert) {
    const scroll = new SheetScroll(fakeSheet());
    let placed = 0;
    const remove = scroll.placeOnScroll(() => placed++);
    scroll.onScroll(gridScroll());
    await settled();
    assert.strictEqual(placed, 1);
    remove();
    assert.strictEqual(scroll.placers.size, 0);
    scroll.onScroll(gridScroll());
    await settled();
    assert.strictEqual(placed, 1, 'not placed again');
    assert.strictEqual(scroll.layoutTick, 0);
  });
});
