import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  render,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import type {
  EuiDataGridColumn,
  EuiDataGridItemsRendered,
  EuiDataGridScrollEvent
} from '#src/components/eui-data-grid.gts';

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function cell(row: number, col: number): HTMLElement | null {
  return document.querySelector<HTMLElement>(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${col}"]`
  );
}

function renderedRowIndexes(): number[] {
  return Array.from(document.querySelectorAll('.euiDataGridRow')).map((row) =>
    Number(row.getAttribute('data-grid-visible-row-index'))
  );
}

async function scrollTo(top: number, left = 0) {
  const outer = el('.euiDataGrid__virtualized');
  outer.scrollTop = top;
  outer.scrollLeft = left;
  await triggerEvent(outer, 'scroll');
}

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'a', displayAsText: 'A' },
  { id: 'b', displayAsText: 'B' },
  { id: 'c', displayAsText: 'C' }
];

const WIDE_COLUMNS: EuiDataGridColumn[] = Array.from({ length: 30 }, (_, i) => ({
  id: `col${i}`,
  initialWidth: 120
}));

module('Integration | Component | EuiDataGrid virtualization', function (hooks) {
  setupRenderingTest(hooks);

  test('only rows in the viewport (plus overscan) are rendered; scrolling renders more', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            @height={{300}}
            @columns={{COLUMNS}}
            @rowCount={{10000}}
            @toolbarVisibility={{false}}
          >
            <:cell as |c|>row {{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    const outer = el('.euiDataGrid__virtualized');
    assert.strictEqual(outer.style.overflow, 'auto');
    assert.ok(outer.offsetHeight <= 300, 'the scroll container fills the constrained height');
    const rows = renderedRowIndexes();
    assert.ok(rows.length > 3 && rows.length < 15, `renders a window of rows (${rows.length})`);
    assert.strictEqual(rows[0], 0);
    assert.strictEqual(
      el('.euiDataGrid__virtualized > div').offsetHeight,
      el('.euiDataGridHeader').offsetHeight + 10000 * el('.euiDataGridRow').offsetHeight,
      'the inner element is sized to every row'
    );

    const rowHeight = el('.euiDataGridRow').offsetHeight;
    await scrollTo(rowHeight * 5000);
    const scrolled = renderedRowIndexes();
    assert.true(scrolled.includes(5000), 'rows at the scroll position render');
    assert.false(scrolled.includes(0), 'rows scrolled away are removed');
    assert.ok(scrolled.length < 15);
    assert.dom(cell(5000, 0)!).hasText('row 5000');
    assert.dom(cell(5000, 0)!).hasAttribute('aria-rowindex', '5001');

    const header = el('.euiDataGridHeader');
    assert.strictEqual(getComputedStyle(header).position, 'sticky');
    assert.strictEqual(
      header.getBoundingClientRect().top,
      outer.getBoundingClientRect().top,
      'the sticky header stays at the top of the scroll container'
    );
  });

  test('scrolling within the rendered window keeps rows and cells', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid @height={{300}} @columns={{COLUMNS}} @rowCount={{500}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    const rowHeight = el('.euiDataGridRow').offsetHeight;
    await scrollTo(rowHeight * 100);
    const before = renderedRowIndexes();
    const target = cell(101, 1);
    await scrollTo(rowHeight * 100 + 3);
    assert.deepEqual(renderedRowIndexes(), before, 'same window');
    assert.strictEqual(cell(101, 1), target, 'cells are not re-created while scrolling inside the window');
    await scrollTo(rowHeight * 101 + 3);
    assert.strictEqual(cell(101, 1), target, 'cells that stay in the window are kept');
  });

  test('columns are virtualized horizontally', async function (assert) {
    await render(
      <template>
        <div style="width:500px">
          <EuiDataGrid @height={{300}} @columns={{WIDE_COLUMNS}} @rowCount={{20}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.columnId}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    const firstRow = el('.euiDataGridRow');
    const count = firstRow.querySelectorAll('[role=gridcell]').length;
    assert.ok(count >= 4 && count <= 7, `renders the visible columns (${count})`);
    assert.dom('[role=columnheader]').exists({ count: 30 }, 'the header row renders every column');
    assert.strictEqual(el('.euiDataGrid__virtualized > div').offsetWidth, 30 * 120);

    await scrollTo(0, 120 * 20);
    assert.ok(cell(0, 20), 'scrolled columns render');
    assert.notOk(cell(0, 0), 'columns scrolled away are removed');
    assert.strictEqual(cell(0, 20)!.offsetLeft, 120 * 20, 'cells are positioned by column offsets');
  });

  test('keyboard navigation scrolls virtualized cells into view', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid @height={{300}} @columns={{COLUMNS}} @rowCount={{1000}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    await click(cell(0, 0)!);
    await triggerKeyEvent(document.activeElement!, 'keydown', 'End', { ctrlKey: true });
    await waitUntil(() => document.activeElement === cell(999, 2));
    assert.strictEqual(document.activeElement, cell(999, 2), 'Ctrl+End reaches the last row');
    const outer = el('.euiDataGrid__virtualized');
    assert.ok(outer.scrollTop > 0, 'the grid scrolled');
    assert.notOk(cell(0, 0), 'the first row was virtualized away');

    await triggerKeyEvent(document.activeElement!, 'keydown', 'ArrowUp');
    assert.strictEqual(document.activeElement, cell(998, 2));
    await triggerKeyEvent(document.activeElement!, 'keydown', 'Home', { ctrlKey: true });
    await waitUntil(() => document.activeElement === cell(0, 0));
    assert.strictEqual(outer.scrollTop, 0, 'scrolled back to the top');
  });

  test('reports rendered items and scroll positions', async function (assert) {
    const items: EuiDataGridItemsRendered[] = [];
    const scrolls: EuiDataGridScrollEvent[] = [];
    const options = {
      overscanRowCount: 2,
      onItemsRendered: (rendered: EuiDataGridItemsRendered) => items.push(rendered),
      onScroll: (event: EuiDataGridScrollEvent) => scrolls.push(event)
    };
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            @height={{300}}
            @columns={{COLUMNS}}
            @rowCount={{1000}}
            @toolbarVisibility={{false}}
            @virtualizationOptions={{options}}
          >
            <:cell as |c|>{{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    const last = items[items.length - 1]!;
    assert.strictEqual(last.overscanRowStartIndex, 0);
    assert.strictEqual(last.visibleRowStartIndex, 0);
    assert.strictEqual(
      last.overscanRowStopIndex,
      last.visibleRowStopIndex + 2,
      'two overscan rows'
    );
    const rowHeight = el('.euiDataGridRow').offsetHeight;
    await scrollTo(rowHeight * 50);
    const latest = items[items.length - 1]!;
    assert.strictEqual(latest.visibleRowStartIndex, 50);
    assert.strictEqual(latest.overscanRowStartIndex, 48);
    const scroll = scrolls[scrolls.length - 1]!;
    assert.strictEqual(scroll.scrollTop, rowHeight * 50);
    assert.false(scroll.isScrolledToBlockStart);
    assert.false(scroll.isScrolledToBlockEnd);
  });

  test('without a height the grid grows with its rows', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{12}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    assert.strictEqual(renderedRowIndexes().length, 12, 'every row renders');
    const outer = el('.euiDataGrid__virtualized');
    assert.strictEqual(outer.scrollHeight, outer.clientHeight, 'no vertical scrolling');
    assert.dom('.euiDataGrid__scrollOverlay').doesNotExist('no scroll border overlay');
  });
});
