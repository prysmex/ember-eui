import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';
import { click, render, triggerKeyEvent, waitUntil, settled } from '@ember/test-helpers';

import { array, hash } from '@ember/helper';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import type { TOC } from '@ember/component/template-only';

import type {
  EuiDataGridCellValueElementProps,
  EuiDataGridColumn,
  EuiDataGridGroupCellProps,
  EuiDataGridRefProps,
  EuiDataGridSortingColumn
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

function row(visibleRowIndex: number): HTMLElement {
  return el(`.euiDataGridRow[data-grid-visible-row-index="${visibleRowIndex}"]`);
}

function columnTexts(col: number): string[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>(`.euiDataGridRow [data-gridcell-column-index="${col}"]`)
  )
    .sort(
      (a, b) =>
        Number(a.dataset['gridcellVisibleRowIndex']) - Number(b.dataset['gridcellVisibleRowIndex'])
    )
    .map((node) => node.querySelector('[data-datagrid-cellcontent]')!.textContent!.trim());
}

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'name', displayAsText: 'Name' },
  { id: 'size', displayAsText: 'Size' }
];

interface FileRow {
  id: string;
  name: string;
  size: number;
  children?: FileRow[];
}

const FILES: FileRow[] = [
  {
    id: 'src',
    name: 'src',
    size: 30,
    children: [
      { id: 'app', name: 'app.ts', size: 20 },
      {
        id: 'utils',
        name: 'utils',
        size: 10,
        children: [{ id: 'keys', name: 'keys.ts', size: 10 }]
      }
    ]
  },
  { id: 'readme', name: 'README.md', size: 5 }
];

/** Renders `@row[columnId]`, like a consumer with nested data would. */
class RowCell extends Component<{ Args: EuiDataGridCellValueElementProps }> {
  get value() {
    return (this.args.row as Record<string, unknown> | undefined)?.[this.args.columnId];
  }

  <template>{{this.value}}</template>
}

const PEOPLE = [
  { id: 1, name: 'Ana', country: 'France', city: 'Paris' },
  { id: 2, name: 'Bo', country: 'USA', city: 'NYC' },
  { id: 3, name: 'Cy', country: 'France', city: 'Lyon' },
  { id: 4, name: 'Di', country: 'France', city: 'Paris' },
  { id: 5, name: 'Ed', country: 'Chile', city: 'Santiago' }
];

const PEOPLE_COLUMNS: EuiDataGridColumn[] = [
  { id: 'name', displayAsText: 'Name' },
  { id: 'country', displayAsText: 'Country' },
  { id: 'city', displayAsText: 'City' }
];

class Expanded {
  @tracked ids: string[] = [];
  calls: string[][] = [];
  onExpandedChange = (ids: string[]) => {
    this.calls.push(ids);
    this.ids = ids;
  };
}

class Sorting {
  @tracked columns: EuiDataGridSortingColumn[] = [];
  onSort = (columns: EuiDataGridSortingColumn[]) => {
    this.columns = columns;
  };
}

class Pagination {
  @tracked pageIndex = 0;
  @tracked pageSize = 2;
  pageSizeOptions = [2];
  onChangePage = (pageIndex: number) => {
    this.pageIndex = pageIndex;
  };
  onChangeItemsPerPage = (pageSize: number) => {
    this.pageSize = pageSize;
  };
}

module('Integration | Component | EuiDataGrid grouping (nested rows)', function (hooks) {
  setupRenderingTest(hooks);

  test('without @rowTree/@grouping nothing changes (role=grid, no tree attributes)', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Plain" @columns={{COLUMNS}} @rowCount={{3}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.columnId}} {{c.rowIndex}}{{if c.row "ROW"}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    assert.dom('[role=grid]').exists().hasAttribute('aria-rowcount', '3');
    assert.dom('[role=treegrid]').doesNotExist();
    assert.dom('.euiDataGridRow').exists({ count: 3 });
    for (const name of ['aria-level', 'aria-expanded', 'aria-setsize', 'aria-posinset']) {
      assert.dom('.euiDataGridRow[' + name + ']').doesNotExist(`no ${name}`);
    }
    assert.dom('[data-test-subj=euiDataGridRowToggle]').doesNotExist();
    assert.dom('.euiDataGridTreeCell__spacer').doesNotExist();
    assert.dom('[data-datagrid-cellcontent]', cell(2, 0)).hasText('name 2', 'no @row');
  });

  test('nested rows: zero-config `children`, toggling by click, treegrid ARIA and @row', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            aria-label="Files"
            @columns={{COLUMNS}}
            @rowTree={{FILES}}
            @renderCellValue={{RowCell}}
            @toolbarVisibility={{false}}
          />
        </div>
      </template>
    );
    assert.dom('[role=treegrid]').exists().hasAttribute('aria-rowcount', '2');
    assert.deepEqual(columnTexts(0), ['src', 'README.md'], 'only root rows');
    assert.dom(row(0)).hasAttribute('aria-level', '1').hasAttribute('aria-expanded', 'false');
    assert.dom(row(0)).hasAttribute('aria-setsize', '2').hasAttribute('aria-posinset', '1');
    assert.dom(row(1)).doesNotHaveAttribute('aria-expanded', 'leaf rows have no aria-expanded');
    assert.dom('[data-test-subj=euiDataGridRowToggle]', cell(0, 0)).exists().hasAttribute('aria-label', 'Expand row');
    assert.dom('[data-test-subj=euiDataGridRowToggle]', cell(1, 0)).doesNotExist();
    assert.dom('.euiDataGridTreeCell__spacer', cell(1, 0)).exists('leaves keep the toggle space');
    assert.dom('[data-test-subj=euiDataGridRowToggle]', cell(0, 1)).doesNotExist('toggle only in the first data column');
    assert.dom(cell(1, 0)).hasAttribute('data-gridcell-row-index', '4', 'pre-order data row index');

    await click(el('[data-test-subj=euiDataGridRowToggle]', cell(0, 0)));
    assert.deepEqual(columnTexts(0), ['src', 'app.ts', 'utils', 'README.md']);
    assert.dom('[role=treegrid]').hasAttribute('aria-rowcount', '4');
    assert.dom(row(0)).hasAttribute('aria-expanded', 'true');
    assert.dom('[data-test-subj=euiDataGridRowToggle]', cell(0, 0)).hasAttribute('aria-label', 'Collapse row').hasAttribute('aria-expanded', 'true');
    assert.dom(row(2)).hasAttribute('aria-level', '2').hasAttribute('aria-setsize', '2').hasAttribute('aria-posinset', '2');
    assert.dom(cell(2, 1)).hasAttribute('data-gridcell-row-index', '2');
    const indent = el('.euiDataGridTreeCell__toggle', cell(2, 0));
    assert.true(parseFloat(getComputedStyle(indent).marginInlineStart) > 0, 'children are indented');
    const content = el('[data-datagrid-cellcontent]', cell(0, 0));
    assert.true(content.scrollHeight <= content.clientHeight + 1, 'the toggle does not overflow the row');

    await click(el('[data-test-subj=euiDataGridRowToggle]', cell(2, 0)));
    assert.deepEqual(columnTexts(0), ['src', 'app.ts', 'utils', 'keys.ts', 'README.md']);
    assert.dom(row(3)).hasAttribute('aria-level', '3');

    await click(el('[data-test-subj=euiDataGridRowToggle]', cell(0, 0)));
    assert.deepEqual(columnTexts(0), ['src', 'README.md'], 'collapsing hides all descendants');
    await click(el('[data-test-subj=euiDataGridRowToggle]', cell(0, 0)));
    assert.deepEqual(columnTexts(0), ['src', 'app.ts', 'utils', 'keys.ts', 'README.md'], 'descendants keep their state');
    assert.dom('[tabindex="0"][data-test-subj=euiDataGridRowToggle]').doesNotExist('the toggle stays out of the tab order');
  });

  test('keyboard: Space toggles, Enter still opens the expandable cell popover, leaves keep arrow navigation', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Files" @columns={{COLUMNS}} @rowTree={{FILES}} @renderCellValue={{RowCell}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    await click(cell(0, 0));
    assert.strictEqual(document.activeElement, cell(0, 0));
    await triggerKeyEvent(cell(0, 0), 'keydown', ' ');
    assert.deepEqual(columnTexts(0), ['src', 'app.ts', 'utils', 'README.md'], 'Space expands');
    await triggerKeyEvent(cell(0, 0), 'keydown', ' ');
    assert.deepEqual(columnTexts(0), ['src', 'README.md'], 'Space collapses');

    await triggerKeyEvent(cell(0, 0), 'keydown', 'Enter');
    await waitUntil(() => document.querySelector('[data-test-subj=euiDataGridExpansionPopover]'));
    assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).hasText('src', 'Enter opens the popover');
    assert.deepEqual(columnTexts(0), ['src', 'README.md']);

    // a leaf's ArrowRight keeps navigating cells
    await triggerKeyEvent(document.activeElement!, 'keydown', 'Escape');
    await waitUntil(() => !document.querySelector('[data-test-subj=euiDataGridExpansionPopover]'));
    await click(cell(1, 0));
    await triggerKeyEvent(cell(1, 0), 'keydown', 'ArrowRight');
    await waitUntil(() => document.activeElement === cell(1, 1));
    assert.strictEqual(document.activeElement, cell(1, 1), 'ArrowRight on a leaf moves to the next cell');
    await click(cell(0, 1));
    await triggerKeyEvent(cell(0, 1), 'keydown', ' ');
    assert.deepEqual(columnTexts(0), ['src', 'README.md'], 'Space outside the toggle cell does nothing');
  });

  test('flat rows with parentId, controlled expansion, toggleColumnId and defaults', async function (assert) {
    const flat = [
      { id: 'a', name: 'Parent', parentId: null, size: 1 },
      { id: 'b', name: 'Child', parentId: 'a', size: 2 },
      { id: 'c', name: 'Other', size: 3 }
    ];
    const expanded = new Expanded();
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            aria-label="Flat"
            @columns={{COLUMNS}}
            @rowTree={{hash rows=flat expandedRowIds=expanded.ids onExpandedChange=expanded.onExpandedChange toggleColumnId="size"}}
            @toolbarVisibility={{false}}
          >
            <:cell as |c|>{{c.rowIndex}}:{{c.row.name}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    assert.deepEqual(columnTexts(0), ['0:Parent', '2:Other'], 'flat rows keep their array index');
    assert.dom('[data-test-subj=euiDataGridRowToggle]', cell(0, 1)).exists('toggle in the toggleColumnId column');
    await click(el('[data-test-subj=euiDataGridRowToggle]', cell(0, 1)));
    assert.deepEqual(expanded.calls, [['a']]);
    assert.deepEqual(columnTexts(0), ['0:Parent', '1:Child', '2:Other']);

    expanded.ids = [];
    await settled();
    assert.deepEqual(columnTexts(0), ['0:Parent', '2:Other'], 'controlled: follows expandedRowIds');

    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="All" @columns={{COLUMNS}} @rowTree={{hash rows=FILES defaultExpandedRowIds="all"}} @renderCellValue={{RowCell}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    assert.deepEqual(columnTexts(0), ['src', 'app.ts', 'utils', 'keys.ts', 'README.md'], "defaultExpandedRowIds='all'");
  });

  test('grouping: group rows with value and count, toggling, ARIA and non-expandable group cells', async function (assert) {
    const expanded = new Expanded();
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            aria-label="People"
            @columns={{PEOPLE_COLUMNS}}
            @grouping={{hash groupBy=(array "country" "city") rows=PEOPLE onExpandedChange=expanded.onExpandedChange}}
            @toolbarVisibility={{false}}
          >
            <:cell as |c|>{{c.row.name}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    assert.dom('[role=treegrid]').hasAttribute('aria-rowcount', '3');
    assert.deepEqual(columnTexts(0), ['Chile(1)', 'France(3)', 'USA(1)'], 'groups sorted by value with counts');
    assert.dom('.euiDataGridGroupCell__label', cell(1, 0)).hasText('France');
    assert.dom(row(1)).hasClass('euiDataGridRow--group').hasAttribute('aria-expanded', 'false').hasAttribute('aria-level', '1');
    assert.deepEqual(columnTexts(1), ['', '', ''], 'other group cells are empty');
    assert.dom(cell(1, 0)).hasAttribute('data-gridcell-row-index', '-1', 'group rows have negative row indexes');

    await click(el('[data-test-subj=euiDataGridRowToggle]', cell(1, 0)));
    assert.deepEqual(expanded.calls, [['group:["France"]']]);
    assert.deepEqual(columnTexts(0), ['Chile(1)', 'France(3)', 'Lyon(1)', 'Paris(2)', 'USA(1)']);
    assert.dom(row(3)).hasAttribute('aria-level', '2');

    // group rows: Enter toggles (no popover), no cell actions
    await click(cell(3, 0));
    await triggerKeyEvent(cell(3, 0), 'keydown', 'Enter');
    assert.deepEqual(columnTexts(0), ['Chile(1)', 'France(3)', 'Lyon(1)', 'Paris(2)', 'Ana', 'Di', 'USA(1)']);
    assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).doesNotExist();
    assert.dom('.euiDataGridRowCell__actionsWrapper', cell(3, 0)).doesNotExist();
    assert.dom(row(4)).hasAttribute('aria-level', '3');
    assert.dom(cell(4, 0)).hasAttribute('data-gridcell-row-index', '0');

    await triggerKeyEvent(cell(3, 0), 'keydown', 'Enter');
    assert.deepEqual(columnTexts(0), ['Chile(1)', 'France(3)', 'Lyon(1)', 'Paris(2)', 'USA(1)']);
  });

  test('grouping with getValue + rowCount, renderGroupCell and sorted group order', async function (assert) {
    const sorting = new Sorting();
    const getValue = (rowIndex: number, columnId: string) =>
      (PEOPLE[rowIndex] as Record<string, unknown>)[columnId];
    const GroupCell: TOC<{ Args: EuiDataGridGroupCellProps }> = <template>
      {{#if @isToggleCell}}{{@group.columnId}}={{@group.value}}{{else}}n={{@group.count}}{{/if}}
    </template>;
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            aria-label="People"
            @columns={{PEOPLE_COLUMNS}}
            @rowCount={{PEOPLE.length}}
            @sorting={{sorting}}
            @grouping={{hash groupBy=(array "country") getValue=getValue renderGroupCell=GroupCell defaultExpandedGroupIds="all"}}
            @toolbarVisibility={{false}}
          >
            <:cell as |c|>{{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    assert.deepEqual(columnTexts(0), ['country=Chile', '4', 'country=France', '0', '2', '3', 'country=USA', '1']);
    assert.deepEqual(columnTexts(2).slice(0, 2), ['n=1', '4'], 'renderGroupCell in every data cell of group rows only');

    sorting.onSort([{ id: 'country', direction: 'desc' }]);
    await settled();
    assert.deepEqual(columnTexts(0), ['country=USA', '1', 'country=France', '0', '2', '3', 'country=Chile', '4'], 'groups follow the sort direction of their column');
  });

  test('in-memory sorting sorts siblings within each parent', async function (assert) {
    const sorting = new Sorting();
    const inMemory = { level: 'sorting' as const };
    const rows = [
      { id: 'z', name: 'zeta', size: 1, children: [{ id: 'z2', name: 'b', size: 1 }, { id: 'z1', name: 'a', size: 2 }] },
      { id: 'a', name: 'alpha', size: 2 }
    ];
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            aria-label="Sorted"
            @columns={{COLUMNS}}
            @rowTree={{hash rows=rows defaultExpandedRowIds="all"}}
            @renderCellValue={{RowCell}}
            @inMemory={{inMemory}}
            @sorting={{sorting}}
            @toolbarVisibility={{false}}
          />
        </div>
      </template>
    );
    assert.deepEqual(columnTexts(0), ['zeta', 'b', 'a', 'alpha']);
    sorting.onSort([{ id: 'name', direction: 'asc' }]);
    await waitUntil(() => columnTexts(0)[0] === 'alpha');
    assert.deepEqual(columnTexts(0), ['alpha', 'zeta', 'a', 'b'], 'children stay under their parent');
  });

  test('pagination pages over visible rows', async function (assert) {
    const pagination = new Pagination();
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Paged" @columns={{COLUMNS}} @rowTree={{FILES}} @renderCellValue={{RowCell}} @pagination={{pagination}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    assert.deepEqual(columnTexts(0), ['src', 'README.md']);
    assert.dom('.euiDataGrid__pagination').exists();
    assert.dom('[role=treegrid]').hasAttribute('aria-label', 'Paged; Page 1 of 1.');
    await click(el('[data-test-subj=euiDataGridRowToggle]', cell(0, 0)));
    assert.deepEqual(columnTexts(0), ['src', 'app.ts'], 'expanding pushes rows to the next page');
    assert.dom('[role=treegrid]').hasAttribute('aria-label', 'Paged; Page 1 of 2.');
    pagination.pageIndex = 1;
    await settled();
    assert.deepEqual(columnTexts(0), ['utils', 'README.md']);
    assert.dom(cell(0, 0)).hasAttribute('aria-rowindex', '3');
  });

  test('@registerApi: expandAll, collapseAll, expandRow and setFocusedCell revealing rows', async function (assert) {
    let api: EuiDataGridRefProps | undefined;
    const registerApi = (value: EuiDataGridRefProps) => {
      api = value;
    };
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Api" @columns={{COLUMNS}} @rowTree={{FILES}} @renderCellValue={{RowCell}} @registerApi={{registerApi}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    await waitUntil(() => api);
    api!.expandAll!();
    await settled();
    assert.deepEqual(columnTexts(0), ['src', 'app.ts', 'utils', 'keys.ts', 'README.md']);
    api!.collapseAll!();
    await settled();
    assert.deepEqual(columnTexts(0), ['src', 'README.md']);
    api!.expandRow!('src');
    await settled();
    assert.deepEqual(columnTexts(0), ['src', 'app.ts', 'utils', 'README.md']);
    api!.collapseRow!('src');
    await settled();

    api!.setFocusedCell({ rowIndex: 3, colIndex: 1 }); // keys.ts, two levels deep
    await waitUntil(() => document.activeElement === cell(3, 1));
    assert.deepEqual(columnTexts(0), ['src', 'app.ts', 'utils', 'keys.ts', 'README.md'], 'ancestors expanded');
    assert.strictEqual(document.activeElement, cell(3, 1));
    assert.throws(() => api!.setFocusedCell({ rowIndex: 5, colIndex: 0 }), /not a valid row/);
  });

  test('lazy loading: hasChildren rows expand, then rows get their children', async function (assert) {
    class Lazy {
      @tracked rows: Array<Record<string, unknown>> = [
        { id: 'p', name: 'parent', size: 1, hasChildren: true },
        { id: 'q', name: 'other', size: 2 }
      ];
      onExpandedChange = (ids: string[]) => {
        if (ids.includes('p') && !this.rows[0]!['children']) {
          this.rows = [{ ...this.rows[0], children: [{ id: 'c', name: 'child', size: 3 }] }, this.rows[1]!];
        }
      };
    }
    const lazy = new Lazy();
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Lazy" @columns={{COLUMNS}} @rowTree={{hash rows=lazy.rows onExpandedChange=lazy.onExpandedChange}} @renderCellValue={{RowCell}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    assert.dom(row(0)).hasAttribute('aria-expanded', 'false');
    await click(el('[data-test-subj=euiDataGridRowToggle]', cell(0, 0)));
    assert.deepEqual(columnTexts(0), ['parent', 'child', 'other'], 'expansion state survives the rows update (ids)');
  });

  test('collapsing rows clamps a page index past the last page', async function (assert) {
    const pagination = new Pagination();
    let api: EuiDataGridRefProps | undefined;
    const registerApi = (value: EuiDataGridRefProps) => {
      api = value;
    };
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Clamp" @columns={{COLUMNS}} @rowTree={{hash rows=FILES defaultExpandedRowIds="all"}} @renderCellValue={{RowCell}} @pagination={{pagination}} @registerApi={{registerApi}} @toolbarVisibility={{false}} />
        </div>
      </template>
    );
    pagination.pageIndex = 2;
    await settled();
    assert.deepEqual(columnTexts(0), ['README.md']);
    api!.collapseAll!();
    await settled();
    assert.strictEqual(pagination.pageIndex, 0, 'moved to the last page');
    assert.deepEqual(columnTexts(0), ['src', 'README.md']);
  });
});
