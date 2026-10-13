import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';
import { click, render, triggerKeyEvent, waitUntil, settled } from '@ember/test-helpers';

import { array, hash } from '@ember/helper';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import type {
  EuiDataGridCellValueElementProps,
  EuiDataGridColumn,
  EuiDataGridControlColumn
} from '#src/components/eui-data-grid.gts';

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function cell(row: number, col: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${col}"]`
  );
}

function names(col = 0): string[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>(`.euiDataGridRow [data-gridcell-column-index="${col}"]`)
  )
    .sort(
      (a, b) =>
        Number(a.dataset['gridcellVisibleRowIndex']) - Number(b.dataset['gridcellVisibleRowIndex'])
    )
    .map((node) => node.querySelector('[data-datagrid-cellcontent]')!.textContent!.trim());
}

async function press(target: HTMLElement, key: string) {
  await triggerKeyEvent(target, 'keydown', key);
}

async function focused(target: HTMLElement) {
  await waitUntil(() => document.activeElement === target, { timeout: 2000 });
  return document.activeElement === target;
}

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'name', displayAsText: 'Name' },
  { id: 'size', displayAsText: 'Size' }
];

const FILES = [
  {
    id: 'src',
    name: 'src',
    size: 30,
    children: [
      { id: 'app', name: 'app.ts', size: 20 },
      { id: 'utils', name: 'utils', size: 10, children: [{ id: 'keys', name: 'keys.ts', size: 10 }] }
    ]
  },
  { id: 'readme', name: 'README.md', size: 5 }
];

class RowCell extends Component<{ Args: EuiDataGridCellValueElementProps }> {
  get value() {
    return (this.args.row as Record<string, unknown> | undefined)?.[this.args.columnId];
  }

  <template>{{this.value}}</template>
}

class Pagination {
  @tracked pageIndex = 0;
  @tracked pageSize = 2;
  pageSizeOptions = [2];
  onChangePage = (pageIndex: number) => {
    this.pageIndex = pageIndex;
  };
  onChangeItemsPerPage = () => {};
}

module('Integration | Component | EuiDataGrid grouping keyboard (arrow keys)', function (hooks) {
  setupRenderingTest(hooks);

  test('ArrowRight expands a collapsed row, then moves right; leaves move right', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Files" @columns={{COLUMNS}} @rowTree={{FILES}} @renderCellValue={{RowCell}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    await click(cell(0, 0));
    await press(cell(0, 0), 'ArrowRight');
    assert.deepEqual(names(), ['src', 'app.ts', 'utils', 'README.md'], 'expanded');
    assert.true(await focused(cell(0, 0)), 'focus stays on the toggle cell');

    await press(cell(0, 0), 'ArrowRight');
    assert.true(await focused(cell(0, 1)), 'an expanded row moves right');
    assert.deepEqual(names(), ['src', 'app.ts', 'utils', 'README.md']);

    await click(cell(1, 0));
    await press(cell(1, 0), 'ArrowRight');
    assert.true(await focused(cell(1, 1)), 'a leaf moves right');
  });

  test('ArrowLeft collapses an expanded row, moves to the parent, keeps grid behavior on top-level rows', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Files" @columns={{COLUMNS}} @rowTree={{hash rows=FILES defaultExpandedRowIds="all"}} @renderCellValue={{RowCell}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    assert.deepEqual(names(), ['src', 'app.ts', 'utils', 'keys.ts', 'README.md']);

    await click(cell(3, 0)); // keys.ts (leaf)
    await press(cell(3, 0), 'ArrowLeft');
    assert.true(await focused(cell(2, 0)), 'a leaf moves to its parent row');
    assert.deepEqual(names(), ['src', 'app.ts', 'utils', 'keys.ts', 'README.md'], 'nothing collapsed');

    await press(cell(2, 0), 'ArrowLeft');
    assert.deepEqual(names(), ['src', 'app.ts', 'utils', 'README.md'], 'an expanded row collapses');
    assert.true(await focused(cell(2, 0)), 'focus stays');

    await press(cell(2, 0), 'ArrowLeft');
    assert.true(await focused(cell(0, 0)), 'a collapsed row moves to its parent');

    await press(cell(0, 0), 'ArrowLeft');
    assert.deepEqual(names(), ['src', 'README.md']);
    await press(cell(0, 0), 'ArrowLeft');
    assert.true(await focused(cell(0, 0)), 'a collapsed top-level row without a column on its left stays');

    // other columns navigate as usual
    await click(cell(0, 1));
    await press(cell(0, 1), 'ArrowLeft');
    assert.true(await focused(cell(0, 0)), 'ArrowLeft outside the toggle column moves left');
    await click(cell(0, 1));
    await press(cell(0, 1), 'ArrowRight');
    assert.deepEqual(names(), ['src', 'README.md'], 'ArrowRight outside the toggle column does not expand');
  });

  test('top-level rows move left into a leading control column', async function (assert) {
    const leading: EuiDataGridControlColumn[] = [{ id: 'select', width: 36 }];
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Files" @columns={{COLUMNS}} @rowTree={{FILES}} @renderCellValue={{RowCell}} @leadingControlColumns={{leading}} @toolbarVisibility={{false}}>
            <:controlCell>x</:controlCell>
          </EuiDataGrid>
        </div>
      </template>
    );
    await click(cell(1, 1)); // README.md, top-level leaf
    await press(cell(1, 1), 'ArrowLeft');
    assert.true(await focused(cell(1, 0)), 'moves to the control column');
  });

  test('ArrowLeft to a parent on the previous page changes page', async function (assert) {
    const pagination = new Pagination();
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Files" @columns={{COLUMNS}} @rowTree={{hash rows=FILES defaultExpandedRowIds="all"}} @renderCellValue={{RowCell}} @pagination={{pagination}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    pagination.pageIndex = 1;
    await settled();
    assert.deepEqual(names(), ['utils', 'keys.ts']);
    await click(cell(0, 0)); // utils, parent src is on page 0
    await press(cell(0, 0), 'ArrowLeft');
    assert.deepEqual(names(), ['utils', 'README.md'], 'collapsed first');
    await press(cell(0, 0), 'ArrowLeft');
    assert.strictEqual(pagination.pageIndex, 0, 'went to the parent page');
    assert.true(await focused(cell(0, 0)), 'focus on the parent');
  });

  test('group rows: ArrowRight expands, ArrowLeft from a row goes to its group', async function (assert) {
    const people = [
      { name: 'Ana', country: 'France' },
      { name: 'Bo', country: 'USA' },
      { name: 'Cy', country: 'France' }
    ];
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="People" @columns={{COLUMNS}} @grouping={{hash groupBy=(array "country") rows=people}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.row.name}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    await click(cell(0, 0));
    await press(cell(0, 0), 'ArrowRight');
    assert.deepEqual(names(), ['France(2)', 'Ana', 'Cy', 'USA(1)']);
    await click(cell(2, 0));
    await press(cell(2, 0), 'ArrowLeft');
    assert.true(await focused(cell(0, 0)), 'moved to the group row');
    await press(cell(0, 0), 'ArrowLeft');
    assert.deepEqual(names(), ['France(2)', 'USA(1)'], 'the group collapses');
  });

  test('ignored while the popover is open or the cell content has focus', async function (assert) {
    const columns: EuiDataGridColumn[] = [{ id: 'name', isExpandable: false }, { id: 'size' }];
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Files" @columns={{columns}} @rowTree={{FILES}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.row.name}}{{#if (eqName c.columnId)}}<button type="button" data-test-inner>edit</button>{{/if}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    // focus trap mode: Enter enters the cell instead of toggling
    await click(cell(0, 0));
    await triggerKeyEvent(cell(0, 0), 'keydown', 'Enter');
    await triggerKeyEvent(cell(0, 0), 'keyup', 'Enter');
    const inner = el('[data-test-inner]', cell(0, 0));
    assert.true(await focused(inner), 'Enter entered the cell');
    assert.deepEqual(names(), ['srcedit', 'README.mdedit'], 'Enter did not toggle');
    await press(inner, 'ArrowRight');
    assert.deepEqual(names(), ['srcedit', 'README.mdedit'], 'arrows from the content do not toggle');
    await triggerKeyEvent(inner, 'keyup', 'Escape');
    assert.true(await focused(cell(0, 0)));
    await press(cell(0, 0), 'ArrowRight');
    assert.deepEqual(names(), ['srcedit', 'app.tsedit', 'utilsedit', 'README.mdedit'], 'the cell itself expands');
  });

  test('ignored while the cell popover is open', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Files" @columns={{COLUMNS}} @rowTree={{FILES}} @renderCellValue={{RowCell}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    await click(cell(0, 0));
    await press(cell(0, 0), 'Enter');
    await waitUntil(() => document.querySelector('[data-test-subj=euiDataGridExpansionPopover]'));
    await press(cell(0, 0), 'ArrowRight');
    assert.deepEqual(names(), ['src', 'README.md'], 'not expanded while the popover is open');
  });

  test('grids without @rowTree/@grouping navigate with arrows as before', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Plain" @columns={{COLUMNS}} @rowCount={{2}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    await click(cell(0, 0));
    await press(cell(0, 0), 'ArrowRight');
    assert.true(await focused(cell(0, 1)));
    await press(cell(0, 1), 'ArrowLeft');
    assert.true(await focused(cell(0, 0)));
    await press(cell(0, 0), 'ArrowLeft');
    assert.true(await focused(cell(0, 0)), 'stays on the first column');
    await press(cell(0, 0), 'ArrowDown');
    assert.true(await focused(cell(1, 0)));
  });
});

function eqName(columnId: string) {
  return columnId === 'name';
}
