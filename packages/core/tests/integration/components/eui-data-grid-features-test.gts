import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';
import { click, render, triggerEvent, triggerKeyEvent, waitUntil } from '@ember/test-helpers';

import { modifier } from 'ember-modifier';

import EuiDataGrid from '#src/components/eui-data-grid.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type {
  EuiDataGridCellValueElementProps,
  EuiDataGridColumn,
  EuiDataGridControlColumn,
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
  { id: 'amount', displayAsText: 'Amount' }
];

const NAMES = ['delta', 'alpha', 'echo', 'bravo', 'charlie'];
const AMOUNTS = ['9', '100', '25', '3', '10'];

class Pagination {
  @tracked pageIndex = 0;
  @tracked pageSize = 10;
  pageSizeOptions = [10, 20];
  onChangePage = (pageIndex: number) => {
    this.pageIndex = pageIndex;
  };
  onChangeItemsPerPage = (pageSize: number) => {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  };
}

class Sorting {
  @tracked columns: EuiDataGridSortingColumn[] = [];
  onSort = (columns: EuiDataGridSortingColumn[]) => {
    this.columns = columns;
  };
}

class Selection {
  @tracked selected = new Set<number>();
  toggle = (rowIndex: number) => {
    const next = new Set(this.selected);
    if (next.has(rowIndex)) next.delete(rowIndex);
    else next.add(rowIndex);
    this.selected = next;
  };
}

class ValueCell extends Component<{ Args: EuiDataGridCellValueElementProps }> {
  get value() {
    return this.args.columnId === 'name'
      ? NAMES[this.args.rowIndex]
      : AMOUNTS[this.args.rowIndex];
  }

  <template>{{this.value}}</template>
}

module('Integration | Component | EuiDataGrid features', function (hooks) {
  setupRenderingTest(hooks);

  test('pagination renders EuiTablePagination, pages rows and labels the grid', async function (assert) {
    const pagination = new Pagination();
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            aria-label="Rows"
            @columns={{COLUMNS}}
            @rowCount={{35}}
            @toolbarVisibility={{false}}
            @pagination={{pagination}}
          >
            <:cell as |c|>{{c.columnId}} {{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    assert.dom('.euiDataGrid__pagination').exists();
    assert.dom('[role=grid]').hasAttribute('aria-label', 'Rows; Page 1 of 4.');
    assert.dom('.euiDataGridRow').exists({ count: 10 });
    assert.dom(cell(0, 0)).hasText('name 0').hasAttribute('aria-rowindex', '1');
    assert.dom('.euiDataGrid__pagination [aria-label]').exists();
    assert.dom(`.euiDataGrid__pagination [aria-controls="${el('[role=grid]').id}"]`).exists();

    await click(cell(5, 1));
    await triggerKeyEvent(document.activeElement!, 'keydown', 'PageDown');
    assert.strictEqual(pagination.pageIndex, 1, 'PageDown goes to the next page');
    assert.dom('[role=grid]').hasAttribute('aria-label', 'Rows; Page 2 of 4.');
    assert.dom(cell(0, 0)).hasText('name 10').hasAttribute('aria-rowindex', '11');
    await waitUntil(() => document.activeElement === cell(0, 1));
    assert.strictEqual(document.activeElement, cell(0, 1), 'focus moves to the first row');

    await triggerKeyEvent(document.activeElement!, 'keydown', 'PageUp');
    assert.strictEqual(pagination.pageIndex, 0);
    await waitUntil(() => document.activeElement === cell(9, 1));
    assert.strictEqual(document.activeElement, cell(9, 1), 'PageUp moves to the last row of the previous page');

    pagination.pageIndex = 3;
    await waitUntil(() => document.querySelectorAll('.euiDataGridRow').length === 5);
    assert.dom('.euiDataGridRow').exists({ count: 5 }, 'the last page has the remaining rows');
  });

  test('pagination is hidden below the smallest page size', async function (assert) {
    const pagination = new Pagination();
    await render(
      <template>
        <EuiDataGrid @columns={{COLUMNS}} @rowCount={{4}} @toolbarVisibility={{false}} @pagination={{pagination}}>
          <:cell as |c|>{{c.rowIndex}}</:cell>
        </EuiDataGrid>
      </template>
    );
    assert.dom('.euiDataGrid__pagination').doesNotExist();
  });

  test('control columns and footer cells', async function (assert) {
    const selection = new Selection();
    const leading: EuiDataGridControlColumn[] = [{ id: 'select', width: 40 }];
    const trailing: EuiDataGridControlColumn[] = [{ id: 'actions', width: 60 }];
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            @columns={{COLUMNS}}
            @rowCount={{3}}
            @toolbarVisibility={{false}}
            @leadingControlColumns={{leading}}
            @trailingControlColumns={{trailing}}
          >
            <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
            <:controlHeaderCell as |c|><span data-control-header={{c.columnId}}>{{c.columnId}}</span></:controlHeaderCell>
            <:controlCell as |c|>
              {{#if (isSelect c.columnId)}}
                <input
                  type="checkbox"
                  aria-label="Select row {{c.rowIndex}}"
                  checked={{has selection.selected c.rowIndex}}
                  data-select={{c.rowIndex}}
                  {{onChange selection.toggle c.rowIndex}}
                />
              {{else}}
                <span>row {{c.rowIndex}}</span>
              {{/if}}
            </:controlCell>
            <:footerCell as |c|><b data-footer={{c.columnId}}>total {{c.columnId}}</b></:footerCell>
          </EuiDataGrid>
        </div>
      </template>
    );

    assert.dom('[role=grid]').hasAttribute('aria-colcount', '4');
    assert.dom('[role=columnheader]').exists({ count: 4 });
    assert.dom('[role=columnheader].euiDataGridHeaderCell--controlColumn').exists({ count: 2 });
    assert.dom('[data-control-header=select]').exists();
    assert.strictEqual(el('[role=columnheader][data-gridcell-column-id=select]').style.width, '40px');
    assert.dom(cell(0, 0)).hasClass('euiDataGridRowCell--controlColumn');
    assert.strictEqual(cell(0, 0).offsetWidth, 40);
    assert.dom(cell(1, 1)).hasText('name1');
    assert.dom(cell(1, 3)).hasText('row 1');
    assert.dom(cell(1, 3)).hasClass('euiDataGridRowCell--lastColumn');
    assert.strictEqual(cell(1, 1).offsetLeft, 40, 'data columns start after the control column');

    const checkbox = el('[data-select="1"]');
    assert.dom(checkbox).hasAttribute('tabindex', '-1', 'control cell interactives leave the tab order');
    await click(checkbox);
    assert.true(selection.selected.has(1));
    assert.dom('.euiDataGridRowCell__actions', cell(1, 0)).doesNotExist('control columns are not expandable');

    assert.dom('.euiDataGridFooter[role=row]').exists();
    assert.dom('.euiDataGridFooter [role=gridcell]').exists({ count: 4 });
    assert.dom('[data-footer=amount]').hasText('total amount');
    assert.dom('.euiDataGridFooter [data-gridcell-column-index="0"]').hasClass('euiDataGridRowCell--controlColumn').hasText('');
    const footer = el('.euiDataGridFooter');
    assert.strictEqual(getComputedStyle(footer).position, 'sticky', 'sticky footer by default');
    assert.strictEqual(
      getComputedStyle(el('[data-footer=name]').closest('.euiDataGridFooterCell')!).fontWeight,
      String(resolveBorealisTheme('light').euiTheme.font.weight.bold)
    );
    assert.dom('.euiDataGridFooter [data-gridcell-column-index="1"]').hasAttribute('data-gridcell-visible-row-index', '3');
  });

  test('in-memory sorting with detected schemas', async function (assert) {
    const sorting = new Sorting();
    const inMemory = { level: 'sorting' as const };
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            @columns={{COLUMNS}}
            @rowCount={{5}}
            @toolbarVisibility={{false}}
            @renderCellValue={{ValueCell}}
            @inMemory={{inMemory}}
            @sorting={{sorting}}
          />
        </div>
      </template>
    );

    await waitUntil(() => document.querySelector('.euiDataGridHeaderCell--numeric'));
    assert.dom('[data-gridcell-column-id=amount].euiDataGridHeaderCell').hasClass('euiDataGridHeaderCell--numeric', 'numeric schema detected from rendered values');
    assert.dom(cell(0, 1)).hasClass('euiDataGridRowCell--numeric');
    assert.deepEqual(columnTexts(0), NAMES, 'unsorted');

    sorting.onSort([{ id: 'name', direction: 'asc' }]);
    await waitUntil(() => columnTexts(0)[0] === 'alpha');
    assert.deepEqual(columnTexts(0), ['alpha', 'bravo', 'charlie', 'delta', 'echo']);
    assert.dom(cell(0, 0)).hasAttribute('data-gridcell-row-index', '1', 'cells know their data row');

    sorting.onSort([{ id: 'amount', direction: 'desc' }]);
    await waitUntil(() => columnTexts(1)[0] === '100');
    assert.deepEqual(columnTexts(1), ['100', '25', '10', '9', '3'], 'numeric comparator, not string order');
  });

  test('columns resize by dragging the header resizer', async function (assert) {
    const resizes: string[] = [];
    const onColumnResize = ({ columnId, width }: { columnId: string; width: number }) =>
      resizes.push(`${columnId}:${width}`);
    const columns: EuiDataGridColumn[] = [
      { id: 'name', initialWidth: 150 },
      { id: 'amount', initialWidth: 150, isResizable: false }
    ];
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid @columns={{columns}} @rowCount={{2}} @toolbarVisibility={{false}} @onColumnResize={{onColumnResize}}>
            <:cell as |c|>{{c.columnId}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    assert.dom('[data-gridcell-column-id=amount] [data-test-subj=dataGridColumnResizer]').doesNotExist('isResizable: false');
    const resizer = el('[data-gridcell-column-id=name] [data-test-subj=dataGridColumnResizer]');
    assert.strictEqual(getComputedStyle(resizer).cursor, 'ew-resize');
    await triggerEvent(resizer, 'mousedown', { clientX: 100 });
    await triggerEvent(window as unknown as Element, 'mousemove', { clientX: 160 });
    assert.dom(resizer).hasStyle({ opacity: '1' }, 'visible while dragging');
    await triggerEvent(window as unknown as Element, 'mouseup');
    assert.deepEqual(resizes, ['name:210']);
    assert.strictEqual(el('[role=columnheader][data-gridcell-column-id=name]').style.width, '210px');
    assert.strictEqual(cell(0, 0).offsetWidth, 210);
    assert.strictEqual(cell(0, 1).offsetLeft, 210, 'following columns move');

    await triggerEvent(resizer, 'mousedown', { clientX: 100 });
    await triggerEvent(window as unknown as Element, 'mousemove', { clientX: -500 });
    await triggerEvent(window as unknown as Element, 'mouseup');
    assert.deepEqual(resizes, ['name:210', 'name:40'], 'columns are at least 40px wide');
  });
});

function isSelect(columnId: string): boolean {
  return columnId === 'select';
}

function has(set: Set<number>, value: number): boolean {
  return set.has(value);
}

const onChange = modifier((element: HTMLElement, [handler, value]: [(value: number) => void, number]) => {
  const listener = () => handler(value);
  element.addEventListener('change', listener);
  return () => element.removeEventListener('change', listener);
});
