import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  focus,
  render,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import type { EuiDataGridColumn } from '#src/components/eui-data-grid.gts';

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

function header(col: number): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-index="${col}"]`);
}

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'a', displayAsText: 'A' },
  { id: 'b', displayAsText: 'B' },
  { id: 'c', displayAsText: 'C' }
];

async function press(key: string, modifiers: { ctrlKey?: boolean } = {}) {
  await triggerKeyEvent(document.activeElement as HTMLElement, 'keydown', key, modifiers);
}

module('Integration | Component | EuiDataGrid keyboard and focus', function (hooks) {
  setupRenderingTest(hooks);

  test('arrow, Home/End and Ctrl+Home/End navigation keep a single tabbable cell', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Grid" @columns={{COLUMNS}} @rowCount={{5}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    assert.dom('[role=grid]').hasAttribute('tabindex', '0');
    await focus('[role=grid]');
    await triggerKeyEvent('[role=grid]', 'keyup', 'Tab');
    assert.strictEqual(document.activeElement, header(0), 'tabbing into the grid focuses the first header cell');
    assert.dom(header(0)).hasAttribute('tabindex', '0');
    assert.dom('[role=grid]').hasAttribute('tabindex', '-1');

    await press('ArrowDown');
    assert.strictEqual(document.activeElement, cell(0, 0));
    assert.dom(header(0)).hasAttribute('tabindex', '-1');
    assert.dom('[role=gridcell][tabindex="0"]').exists({ count: 1 });

    await press('ArrowRight');
    assert.strictEqual(document.activeElement, cell(0, 1));
    await press('End');
    assert.strictEqual(document.activeElement, cell(0, 2));
    await press('ArrowRight');
    assert.strictEqual(document.activeElement, cell(0, 2), 'stops at the last column');
    await press('Home');
    assert.strictEqual(document.activeElement, cell(0, 0));
    await press('End', { ctrlKey: true });
    assert.strictEqual(document.activeElement, cell(4, 2), 'Ctrl+End: last cell of the page');
    await press('ArrowDown');
    assert.strictEqual(document.activeElement, cell(4, 2), 'stops at the last row');
    await press('Home', { ctrlKey: true });
    assert.strictEqual(document.activeElement, cell(0, 0), 'Ctrl+Home: first cell');
    await press('ArrowUp');
    assert.strictEqual(document.activeElement, header(0), 'ArrowUp from the first row moves to the header');
    await press('ArrowLeft');
    assert.strictEqual(document.activeElement, header(0));

    await click(cell(3, 1));
    assert.strictEqual(document.activeElement, cell(3, 1), 'clicking a cell focuses it');
    assert.dom(cell(3, 1)).hasAttribute('tabindex', '0');
    assert.dom('[role=gridcell][tabindex="0"]').exists({ count: 1 });
    assert.dom('.euiScreenReaderOnly:not([data-tabular-copy-marker])', cell(3, 1)).includesText('B, column 2, row 4');
  });

  test('Enter opens the expansion popover; Escape closes it and returns focus', async function (assert) {
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{3}} @toolbarVisibility={{false}}>
            <:cell as |c|>
              <span data-value data-details={{if c.isDetails "true" "false"}}>{{c.columnId}}-{{c.rowIndex}}</span>
            </:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    await click(cell(1, 1));
    assert.dom('.euiDataGridRowCell__actions', cell(1, 1)).exists('focused expandable cells show their actions');
    assert.dom('[data-test-subj=euiDataGridCellExpandButton]', cell(1, 1)).exists();
    assert.dom('.euiScreenReaderOnly:not([data-tabular-copy-marker])', cell(1, 1)).includesText('Press the Enter key to expand this cell.');

    await press('Enter');
    assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).exists();
    assert.dom('[data-test-subj=euiDataGridExpansionPopover] [data-details=true]', document.body).hasText('b-1');
    assert.dom(cell(1, 1)).hasClass('euiDataGridRowCell--open');
    assert.dom('.euiDataGridRowCell__popover', document.body).exists('panel class');

    await triggerKeyEvent(el('[data-test-subj=euiDataGridExpansionPopover]', document.body), 'keydown', 'Escape');
    assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).doesNotExist();
    assert.dom(cell(1, 1)).doesNotHaveClass('euiDataGridRowCell--open');
    await waitUntil(() => document.activeElement === cell(1, 1));
    assert.strictEqual(document.activeElement, cell(1, 1), 'focus returns to the cell');

    await click('[data-test-subj=euiDataGridCellExpandButton]');
    assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).exists('expand button opens');
    await click('[data-test-subj=euiDataGridCellExpandButton]');
    assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).doesNotExist('expand button toggles closed');
  });

  test('cell actions render on hover and in the popover footer', async function (assert) {
    const calls: string[] = [];
    const columns: EuiDataGridColumn[] = [
      {
        id: 'a',
        visibleCellActions: 1,
        cellActions: [
          {
            iconType: 'plusInCircle',
            label: 'Filter in',
            'data-test-subj': 'filterIn',
            onClick: ({ rowIndex, columnId, isExpanded }) =>
              calls.push(`in:${columnId}:${rowIndex}:${isExpanded}`)
          },
          {
            iconType: 'minusInCircle',
            label: 'Filter out',
            'data-test-subj': 'filterOut',
            onClick: ({ rowIndex, columnId, isExpanded }) =>
              calls.push(`out:${columnId}:${rowIndex}:${isExpanded}`)
          }
        ]
      },
      { id: 'b', isExpandable: false }
    ];

    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid @columns={{columns}} @rowCount={{2}} @toolbarVisibility={{false}}>
            <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    assert.dom('.euiDataGridRowCell__actions').doesNotExist();
    await triggerEvent(cell(1, 0), 'mouseenter');
    assert.dom('.euiDataGridRowCell__actions', cell(1, 0)).exists('hover shows actions');
    assert.dom('[data-test-subj=filterIn]', cell(1, 0)).hasAttribute('aria-label', 'Filter in');
    assert.dom('[data-test-subj=filterOut]', cell(1, 0)).doesNotExist('only visibleCellActions show on hover');
    await click(el('[data-test-subj=filterIn]', cell(1, 0)));
    assert.deepEqual(calls, ['in:a:1:false']);

    assert.true(cell(1, 0).contains(document.activeElement), 'clicking an action focuses within its cell');
    assert.dom(cell(1, 0)).hasAttribute('tabindex', '0', 'the cell becomes the focused cell');
    await triggerEvent(cell(0, 0), 'mouseenter');
    assert.dom('.euiDataGridRowCell__actions', cell(0, 0)).exists();
    await triggerEvent(cell(0, 0), 'mouseleave');
    assert.dom('.euiDataGridRowCell__actions', cell(0, 0)).doesNotExist('leaving hides the actions');
    await triggerEvent(cell(0, 1), 'mouseenter');
    assert.dom('.euiDataGridRowCell__actions', cell(0, 1)).doesNotExist('non-expandable cells have no actions');

    await click(cell(0, 0));
    await press('Enter');
    assert.dom('[data-test-subj=euiDataGridExpansionPopover] .euiPopoverFooter', document.body).exists({ count: 2 }, 'primary and secondary actions');
    await click(el('[data-test-subj=euiDataGridExpansionPopover] [data-test-subj=filterOut]', document.body));
    assert.deepEqual(calls, ['in:a:1:false', 'out:a:0:true']);
  });

  test('non-expandable cells trap focus around interactive content', async function (assert) {
    const columns: EuiDataGridColumn[] = [
      { id: 'a', isExpandable: false },
      { id: 'b' }
    ];
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid @columns={{columns}} @rowCount={{2}} @toolbarVisibility={{false}}>
            <:cell as |c|>
              <button type="button" data-inner={{c.columnId}}>{{c.columnId}}{{c.rowIndex}}</button>
            </:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    const innerButton = el('[data-inner=a]', cell(0, 0));
    assert.dom(innerButton).hasAttribute('tabindex', '-1', 'interactive children leave the tab order');
    assert.dom(innerButton).hasAttribute('data-euigrid-tab-managed', 'true', 'managed by the cell');
    assert.dom(el('[data-inner=b]', cell(0, 1))).hasAttribute('tabindex', '-1');

    await click(cell(0, 0));
    assert.dom(cell(0, 0)).hasAttribute('aria-describedby');
    assert.dom(`#${cell(0, 0).getAttribute('aria-describedby')}`).hasText(
      "Press the Enter key to interact with this cell's contents."
    );
    await triggerKeyEvent(cell(0, 0), 'keyup', 'Enter');
    assert.dom(innerButton).hasAttribute('tabindex', '0');
    await waitUntil(() => document.activeElement === innerButton);
    assert.strictEqual(document.activeElement, innerButton, 'Enter moves focus into the cell');
    assert.dom('[data-focus-lock-disabled="false"]', cell(0, 0)).exists();

    await triggerKeyEvent(innerButton, 'keyup', 'Escape');
    await waitUntil(() => document.activeElement === cell(0, 0));
    assert.dom(innerButton).hasAttribute('tabindex', '-1');
    assert.strictEqual(document.activeElement, cell(0, 0), 'Escape returns to the cell');
  });

  test('header cells open column actions with Enter and hide/move/sort columns', async function (assert) {
    const sorts: string[] = [];
    const sorting = {
      columns: [],
      onSort: (columns: { id: string; direction: string }[]) =>
        sorts.push(columns.map((c) => `${c.id}:${c.direction}`).join(','))
    };
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{2}} @toolbarVisibility={{false}} @sorting={{sorting}}>
            <:cell as |c|>{{c.columnId}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    assert.dom('[role=columnheader]').exists({ count: 3 });
    assert.dom('[data-test-subj="dataGridHeaderCellActionButton-b"]').hasAttribute('tabindex', '-1');
    await click(header(1));
    assert.strictEqual(document.activeElement, header(1));
    await triggerKeyEvent(header(1), 'keydown', 'Enter');
    assert.dom('[data-test-subj="dataGridHeaderCellActionGroup-b"]', document.body).exists();
    assert.dom(header(1)).hasClass('euiDataGridHeaderCell--isActionsPopoverOpen');
    const labels = Array.from(
      document.querySelectorAll('[data-test-subj="dataGridHeaderCellActionGroup-b"] button')
    ).map((item) => item.textContent?.trim());
    assert.deepEqual(labels, ['Hide column', 'Sort A-Z', 'Sort Z-A', 'Move left', 'Move right']);

    const items = document.querySelectorAll<HTMLElement>(
      '[data-test-subj="dataGridHeaderCellActionGroup-b"] button'
    );
    await click(items[1]!);
    assert.deepEqual(sorts, ['b:asc']);

    await click('[data-test-subj="dataGridHeaderCellActionButton-a"]');
    const hide = document.querySelector<HTMLElement>(
      '[data-test-subj="dataGridHeaderCellActionGroup-a"] button'
    )!;
    await click(hide);
    assert.dom('[role=columnheader]').exists({ count: 2 }, 'hide column removes it');
    assert.dom('[data-gridcell-column-id=a]').doesNotExist();

    await click('[data-test-subj="dataGridHeaderCellActionButton-b"]');
    const moveRight = Array.from(
      document.querySelectorAll<HTMLElement>('[data-test-subj="dataGridHeaderCellActionGroup-b"] button')
    ).find((item) => item.textContent?.includes('Move right'))!;
    await click(moveRight);
    assert.dom(header(0)).hasAttribute('data-gridcell-column-id', 'c', 'move right reorders columns');
    assert.dom(header(1)).hasAttribute('data-gridcell-column-id', 'b');
  });
});
