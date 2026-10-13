import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled, triggerEvent, waitUntil } from '@ember/test-helpers';

import { get, hash } from '@ember/helper';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import type { EuiDataGridColumn, EuiDataGridRefProps } from '#src/components/eui-data-grid.gts';

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function rowEl(visibleRowIndex: number): HTMLElement | null {
  return document.querySelector<HTMLElement>(
    `.euiDataGridRow[data-grid-visible-row-index="${visibleRowIndex}"]`
  );
}

function renderedRows(): HTMLElement[] {
  return Array.from(document.querySelectorAll<HTMLElement>('.euiDataGridRow')).sort(
    (a, b) =>
      Number(a.dataset['gridVisibleRowIndex']) - Number(b.dataset['gridVisibleRowIndex'])
  );
}

function text(row: HTMLElement): string {
  return row.querySelector('[data-gridcell-column-index="0"] [data-datagrid-cellcontent]')!.textContent!.trim();
}

async function scrollTo(top: number) {
  const outer = el('.euiDataGrid__virtualized');
  outer.scrollTop = top;
  await triggerEvent(outer, 'scroll');
}

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'name', displayAsText: 'Name' },
  { id: 'n', displayAsText: 'N' }
];

interface Node {
  id: string;
  name: string;
  n: number;
  children?: Node[];
}

/** 50 roots x 10 children x 10 grandchildren = 5,550 rows. */
function bigTree(): Node[] {
  let n = 0;
  return Array.from({ length: 50 }, (_, r) => ({
    id: `r${r}`,
    name: `r${r}`,
    n: n++,
    children: Array.from({ length: 10 }, (_, c) => ({
      id: `r${r}c${c}`,
      name: `r${r}c${c}`,
      n: n++,
      children: Array.from({ length: 10 }, (_, g) => ({
        id: `r${r}c${c}g${g}`,
        name: `r${r}c${c}g${g}`,
        n: n++
      }))
    }))
  }));
}

module('Integration | Component | EuiDataGrid grouping virtualization (large trees)', function (hooks) {
  setupRenderingTest(hooks);

  test('5,550 expanded rows: windowed rendering, scrolling to the end, toggling mid-scroll, scrollToItem', async function (assert) {
    const tree = bigTree();
    let api: EuiDataGridRefProps | undefined;
    const registerApi = (value: EuiDataGridRefProps) => {
      api = value;
    };
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            aria-label="Big tree"
            @height={{300}}
            @columns={{COLUMNS}}
            @rowTree={{hash rows=tree defaultExpandedRowIds="all"}}
            @registerApi={{registerApi}}
            @toolbarVisibility={{false}}
          >
            <:cell as |c|>{{c.row.name}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    assert.dom('[role=treegrid]').hasAttribute('aria-rowcount', '5550');
    const initial = renderedRows();
    assert.true(initial.length > 3 && initial.length < 20, `only a window of rows is in the DOM (${initial.length})`);
    assert.strictEqual(text(initial[0]!), 'r0');
    const outer = el('.euiDataGrid__virtualized');
    const rowHeight = initial[1]!.offsetTop - initial[0]!.offsetTop;
    assert.true(outer.scrollHeight >= 5550 * rowHeight, 'the scroll height covers every visible row');

    // the end
    await scrollTo(outer.scrollHeight);
    const last = rowEl(5549);
    assert.ok(last, 'the last row is rendered');
    assert.strictEqual(text(last!), 'r49c9g9');
    assert.dom(last!).hasAttribute('aria-level', '3').hasAttribute('aria-posinset', '10').hasAttribute('aria-setsize', '10');
    const spacer = el('.euiDataGridTreeCell__spacer', last!);
    assert.true(parseFloat(getComputedStyle(spacer).marginInlineStart) > 0, 'indented');
    assert.true(renderedRows().length < 20, 'still a window');

    // collapse a row in the middle of the scrolled view
    // r18c3 is at 18 * 111 (rows per root) + 1 + 3 * 11 (rows per child)
    const parentIndex = 18 * 111 + 1 + 3 * 11;
    await scrollTo((parentIndex - 3) * rowHeight);
    const parent = rowEl(parentIndex)!;
    assert.ok(parent, 'an expanded child row is in view');
    assert.dom(parent).hasAttribute('aria-level', '2').hasAttribute('aria-expanded', 'true');
    const parentName = text(parent);
    const scrollTop = outer.scrollTop;
    const top = parent.offsetTop;
    await click(el('[data-test-subj=euiDataGridRowToggle]', parent));
    assert.dom('[role=treegrid]').hasAttribute('aria-rowcount', '5540');
    assert.strictEqual(outer.scrollTop, scrollTop, 'the scroll position is kept');
    const after = rowEl(parentIndex)!;
    assert.strictEqual(text(after), parentName, 'the toggled row stays at its index');
    assert.strictEqual(after.offsetTop, top, 'and at its position');
    assert.dom(after).hasAttribute('aria-expanded', 'false');
    const next = rowEl(parentIndex + 1)!;
    assert.strictEqual(text(next), 'r18c4', 'the next sibling follows');

    await click(el('[data-test-subj=euiDataGridRowToggle]', after));
    assert.dom('[role=treegrid]').hasAttribute('aria-rowcount', '5550');
    assert.strictEqual(text(rowEl(parentIndex + 1)!), `${parentName}g0`, 're-expanded');

    // scrollToItem takes visible row indexes
    await waitUntil(() => api);
    api!.scrollToItem!({ rowIndex: 4000, align: 'start' });
    await settled();
    const target = rowEl(4000);
    assert.ok(target, 'scrollToItem rendered the visible row');
    assert.true(Math.abs(outer.scrollTop - 4000 * rowHeight) <= 1, 'scrolled to the row');
  });

  test('auto row heights are measured per row through expand and collapse', async function (assert) {
    const long = 'A long description that wraps over several lines in a narrow column. '.repeat(3);
    const rows = [
      {
        id: 'p',
        name: 'parent',
        text: 'short',
        children: [
          { id: 'c1', name: 'child 1', text: long },
          { id: 'c2', name: 'child 2', text: 'short' }
        ]
      },
      { id: 'q', name: 'other', text: long }
    ];
    const columns: EuiDataGridColumn[] = [
      { id: 'name', displayAsText: 'Name', initialWidth: 160 },
      { id: 'text', displayAsText: 'Text', initialWidth: 200 }
    ];
    const rowHeightsOptions = { defaultHeight: 'auto' as const };
    await render(
      <template>
        <div style="width:400px">
          <EuiDataGrid
            aria-label="Auto"
            @columns={{columns}}
            @rowTree={{rows}}
            @rowHeightsOptions={{rowHeightsOptions}}
            @toolbarVisibility={{false}}
          >
            <:cell as |c|>{{if c.row (get c.row c.columnId)}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    const contiguous = () => {
      const list = renderedRows();
      return list.every((row, i) => i === 0 || row.offsetTop === list[i - 1]!.offsetTop + list[i - 1]!.offsetHeight);
    };
    const heightOf = (i: number) => rowEl(i)!.offsetHeight;
    await waitUntil(() => heightOf(1) > heightOf(0) * 1.5);
    const short = heightOf(0);
    const tall = heightOf(1);
    assert.true(tall > short * 1.5, `long text rows are taller (${short} / ${tall})`);

    await click(el('[data-test-subj=euiDataGridRowToggle]', rowEl(0)!));
    await waitUntil(() => heightOf(1) > short * 1.5 && contiguous());
    assert.strictEqual(heightOf(1), tall, 'the expanded long child is measured');
    assert.strictEqual(heightOf(2), short, 'the short child keeps the short height');
    assert.strictEqual(heightOf(3), tall, 'the row below moved, keeping its height');
    assert.true(contiguous(), 'rows are laid out without gaps or overlaps');

    await click(el('[data-test-subj=euiDataGridRowToggle]', rowEl(0)!));
    await waitUntil(() => renderedRows().length === 2 && contiguous());
    assert.strictEqual(heightOf(1), tall, 'after collapsing, the long root row is tall again');
    assert.true(contiguous());
  });
});
