import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, fillIn, render, triggerEvent, triggerKeyEvent, waitUntil } from '@ember/test-helpers';

import EuiDataGrid from '#src/components/eui-data-grid.gts';
import EuiDataGridToolbarControl from '#src/components/eui-data-grid-toolbar-control.gts';

import type {
  EuiDataGridColumn,
  EuiDataGridSortingColumn,
  EuiDataGridStyle
} from '#src/components/eui-data-grid.gts';

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function all(selector: string, root: ParentNode = document): HTMLElement[] {
  return Array.from(root.querySelectorAll<HTMLElement>(selector));
}

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'name', displayAsText: 'Name' },
  { id: 'email', displayAsText: 'Email' },
  { id: 'age', displayAsText: 'Age', schema: 'numeric' }
];

class Sorting {
  @tracked columns: EuiDataGridSortingColumn[] = [];
  onSort = (columns: EuiDataGridSortingColumn[]) => {
    this.columns = columns;
  };
}

module('Integration | Component | EuiDataGrid toolbar', function (hooks) {
  setupRenderingTest(hooks);

  test('renders the default controls and upstream toolbar styles', async function (assert) {
    await render(
      <template>
        <div style="width:800px">
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{3}}>
            <:cell as |c|>{{c.columnId}}</:cell>
            <:leftControlsPrepend><span data-prepend>prepend</span></:leftControlsPrepend>
            <:leftControlsAppend><span data-append>append</span></:leftControlsAppend>
            <:rightControls><span data-right>right</span></:rightControls>
          </EuiDataGrid>
        </div>
      </template>
    );

    assert.dom('.euiDataGrid').doesNotHaveClass('euiDataGrid--noControls');
    const controls = el('[data-test-subj=dataGridControls]');
    assert.strictEqual(getComputedStyle(controls).display, 'flex');
    assert.strictEqual(getComputedStyle(controls).justifyContent, 'space-between');
    assert.dom('.euiDataGrid__leftControls [data-prepend] + .euiPopover [data-test-subj=dataGridColumnSelectorButton]').exists('prepend comes first');
    assert.dom('[data-test-subj=dataGridColumnSelectorButton]').hasText('Columns 3');
    assert.dom('[data-test-subj=dataGridColumnSelectorButton] .euiDataGridToolbarControl__badge').hasAttribute('aria-label', '- Active: 3').hasAttribute('role', 'marquee');
    assert.dom('[data-test-subj=dataGridColumnSortingButton]').doesNotExist('no sort control without @sorting');
    assert.dom('.euiDataGrid__leftControls [data-append]').exists();
    assert.dom('.euiDataGrid__rightControls [data-right]').exists();
    assert.dom('[data-test-subj=dataGridKeyboardShortcutsButton]').hasAttribute('aria-label', 'Keyboard shortcuts');
    assert.dom('[data-test-subj=dataGridDisplaySelectorButton]').hasAttribute('aria-label', 'Display options');
    assert.dom('[data-test-subj=dataGridFullScreenButton]').hasAttribute('aria-label', 'Enter fullscreen').hasAttribute('aria-pressed', 'false');
  });

  test('toolbarVisibility options and narrow grids hide controls', async function (assert) {
    const visibility = { showColumnSelector: false, showDisplaySelector: false, showKeyboardShortcuts: false };
    await render(
      <template>
        <div style="width:800px" data-wide>
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{3}} @toolbarVisibility={{visibility}}>
            <:cell as |c|>{{c.columnId}}</:cell>
          </EuiDataGrid>
        </div>
        <div style="width:300px" data-narrow>
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{3}}>
            <:cell as |c|>{{c.columnId}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    const wide = el('[data-wide]');
    assert.dom('[data-test-subj=dataGridColumnSelectorButton]', wide).doesNotExist();
    assert.dom('[data-test-subj=dataGridDisplaySelectorButton]', wide).doesNotExist();
    assert.dom('[data-test-subj=dataGridFullScreenButton]', wide).exists();
    const shortcuts = el('[data-test-subj=dataGridKeyboardShortcutsButton]', wide);
    const wrapper = shortcuts.closest('.euiDataGrid__rightControls > span')!;
    assert.strictEqual(getComputedStyle(wrapper).position, 'absolute', 'keyboard shortcuts stay reachable, visually hidden');
    const narrow = el('[data-narrow]');
    assert.dom('.euiDataGrid__leftControls', narrow).doesNotExist('no room for the left controls');
    assert.dom('[data-test-subj=dataGridDisplaySelectorButton]', narrow).exists();
  });

  test('column selector hides, shows, searches and reorders columns', async function (assert) {
    await render(
      <template>
        <div style="width:800px">
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{3}}>
            <:cell as |c|>{{c.columnId}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    await click('[data-test-subj=dataGridColumnSelectorButton]');
    assert.dom('[data-test-subj^=dataGridColumnSelectorColumnItem-]', document.body).exists({ count: 3 });
    const toggle = el('[data-test-subj=dataGridColumnSelectorToggleColumnVisibility-email]', document.body);
    assert.dom(toggle).hasAttribute('aria-checked', 'true').hasAttribute('aria-label', 'Email');
    await click(toggle);
    assert.dom('[role=columnheader]').exists({ count: 2 });
    assert.dom('[data-gridcell-column-id=email]').doesNotExist();
    assert.dom('[data-test-subj=dataGridColumnSelectorButton]').hasText('Columns 2/3');
    assert.dom(toggle).hasAttribute('aria-checked', 'false');

    await fillIn(el('[data-test-subj=dataGridColumnSelectorSearch]', document.body), 'ag');
    assert.dom('[data-test-subj^=dataGridColumnSelectorColumnItem-]', document.body).exists({ count: 1 });
    assert.dom('[data-test-subj=dataGridColumnSelectorColumnItem-age]', document.body).exists();
    assert.dom('.euiDataGridColumnSelector__dragHandle', document.body).doesNotExist('no reordering while searching');
    await fillIn(el('[data-test-subj=dataGridColumnSelectorSearch]', document.body), '');
    assert.dom('.euiDataGridColumnSelector__dragHandle', document.body).exists({ count: 3 });

    await click(el('[data-test-subj=dataGridColumnSelectorHideAllButton]', document.body));
    assert.dom('[role=columnheader]').doesNotExist();
    assert.dom('[role=grid]').hasAttribute('aria-colcount', '0');
    await click(el('[data-test-subj=dataGridColumnSelectorShowAllButton]', document.body));
    assert.deepEqual(
      all('[role=columnheader]').map((header) => header.dataset['gridcellColumnId']),
      ['name', 'email', 'age']
    );

    // keyboard drag: space picks up, arrow moves, space drops
    const handle = all('.euiDataGridColumnSelector__dragHandle', document.body)[0]!;
    handle.focus();
    await triggerKeyEvent(handle, 'keydown', ' ');
    await triggerKeyEvent(handle, 'keydown', 'ArrowDown');
    await triggerKeyEvent(handle, 'keydown', ' ');
    await waitUntil(() => el('[role=columnheader]').dataset['gridcellColumnId'] === 'email');
    assert.deepEqual(
      all('[role=columnheader]').map((header) => header.dataset['gridcellColumnId']),
      ['email', 'name', 'age'],
      'dragging reorders the grid columns'
    );
  });

  test('sorting popover adds, changes, removes and clears sorts', async function (assert) {
    const sorting = new Sorting();
    await render(
      <template>
        <div style="width:800px">
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{3}} @sorting={{sorting}}>
            <:cell as |c|>{{c.columnId}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    assert.dom('[data-test-subj=dataGridColumnSortingButton]').hasText('Sort fields');
    await click('[data-test-subj=dataGridColumnSortingButton]');
    assert.dom('[data-test-subj=dataGridColumnSortingPopover] [role=alert]', document.body).doesNotExist();
    assert.dom('[role=alert]', document.body).hasText('Currently no fields are sorted');
    await click(el('[data-test-subj=dataGridColumnSortingSelectionButton]', document.body));
    assert.dom('[data-test-subj^=dataGridColumnSortingPopoverColumnSelection-]', document.body).exists({ count: 3 });
    await click(el('[data-test-subj=dataGridColumnSortingPopoverColumnSelection-age]', document.body));
    assert.deepEqual(sorting.columns, [{ id: 'age', direction: 'asc' }]);

    assert.dom('[data-test-subj=dataGridColumnSortingButton]').hasText('Sort fields 1');
    assert.dom('[data-gridcell-column-id=age].euiDataGridHeaderCell').hasAttribute('aria-sort', 'ascending');
    assert.dom('[data-test-subj=dataGridHeaderCellSortingIcon-age]').exists();
    assert.dom('[data-test-subj=euiDataGridColumnSorting-sortColumn-age]', document.body).exists();
    assert.dom('[data-test-subj=euiDataGridColumnSorting-sortColumn-age]', document.body).includesText('Low-High', 'numeric schema labels');

    const desc = all('[data-test-subj=euiDataGridColumnSorting-sortColumn-age] .euiButtonGroupButton', document.body)[1]!;
    await click(desc);
    assert.deepEqual(sorting.columns, [{ id: 'age', direction: 'desc' }]);
    assert.dom('[data-gridcell-column-id=age].euiDataGridHeaderCell').hasAttribute('aria-sort', 'descending');

    await click(el('[data-test-subj=dataGridColumnSortingSelectionButton]', document.body));
    await click(el('[data-test-subj=dataGridColumnSortingPopoverColumnSelection-name]', document.body));
    assert.deepEqual(sorting.columns, [
      { id: 'age', direction: 'desc' },
      { id: 'name', direction: 'asc' }
    ]);
    assert.dom('[data-gridcell-column-id=age].euiDataGridHeaderCell').doesNotHaveAttribute('aria-sort', 'multi-column sorts are described instead');
    const ageHeader = el('[data-gridcell-column-id=age].euiDataGridHeaderCell');
    assert.dom(`#${ageHeader.getAttribute('aria-describedby')}`).hasText(
      'Sorted by age, descending, then sorted by name, ascending.'
    );

    await click(el('[data-test-subj=euiDataGridColumnSorting-sortColumn-age] .euiDataGridColumnSorting__button', document.body));
    assert.deepEqual(sorting.columns, [{ id: 'name', direction: 'asc' }]);
    await click(el('[data-test-subj=dataGridColumnSortingClearButton]', document.body));
    assert.deepEqual(sorting.columns, []);
  });

  test('display selector changes density and row heights, and resets them', async function (assert) {
    const changes: EuiDataGridStyle[] = [];
    const gridStyle: EuiDataGridStyle = { onChange: (styles) => changes.push(styles) };
    await render(
      <template>
        <div style="width:800px">
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{3}} @gridStyle={{gridStyle}}>
            <:cell as |c|>{{c.columnId}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    await click('[data-test-subj=dataGridDisplaySelectorButton]');
    assert.dom('.euiDataGrid__displayPopoverPanel', document.body).exists();
    assert.dom('[data-test-subj=densityButtonGroup]', document.body).exists();
    const compact = all('[data-test-subj=densityButtonGroup] .euiButtonGroupButton', document.body)[0]!;
    await click(compact);
    assert.dom('.euiDataGrid').hasClass('euiDataGrid--fontSizeSmall').hasClass('euiDataGrid--paddingSmall');
    assert.strictEqual(changes[changes.length - 1]?.fontSize, 's');
    assert.dom('[data-test-subj=resetDisplaySelector]', document.body).exists();

    const auto = all('[data-test-subj=rowHeightButtonGroup] .euiButtonGroupButton', document.body)[0]!;
    await click(auto);
    assert.dom('.euiDataGridRowCell__content--autoHeight').exists();
    assert.dom('[data-test-subj=lineCountNumber]', document.body).isDisabled();
    const staticButton = all('[data-test-subj=rowHeightButtonGroup] .euiButtonGroupButton', document.body)[1]!;
    await click(staticButton);
    await fillIn(el('[data-test-subj=lineCountNumber]', document.body), '3');
    await triggerEvent(el('[data-test-subj=lineCountNumber]', document.body), 'change');
    assert.dom('.euiDataGridRowCell__content--lineCountHeight').exists();

    await click(el('[data-test-subj=resetDisplaySelector]', document.body));
    assert.dom('.euiDataGrid').doesNotHaveClass('euiDataGrid--fontSizeSmall');
    assert.dom('.euiDataGridRowCell__content--defaultHeight').exists();
    assert.dom('[data-test-subj=resetDisplaySelector]', document.body).doesNotExist();
  });

  test('fullscreen mode and keyboard shortcuts popover', async function (assert) {
    const changes: boolean[] = [];
    const onFullScreenChange = (value: boolean) => changes.push(value);
    await render(
      <template>
        <div style="width:800px">
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{3}} @onFullScreenChange={{onFullScreenChange}}>
            <:cell as |c|>{{c.columnId}}</:cell>
          </EuiDataGrid>
        </div>
      </template>
    );

    await click('[data-test-subj=dataGridFullScreenButton]');
    assert.dom('.euiDataGrid').hasClass('euiDataGrid--fullScreen');
    assert.strictEqual(getComputedStyle(el('.euiDataGrid')).position, 'fixed');
    assert.true(document.body.classList.contains('euiDataGrid__restrictBody'));
    assert.strictEqual(getComputedStyle(document.body).overflow, 'hidden');
    assert.dom('[data-test-subj=dataGridFullScreenButton]').hasAttribute('aria-pressed', 'true').hasAttribute('aria-label', 'Exit fullscreen');
    await triggerKeyEvent('.euiDataGrid', 'keydown', 'Escape');
    assert.dom('.euiDataGrid').doesNotHaveClass('euiDataGrid--fullScreen');
    assert.false(document.body.classList.contains('euiDataGrid__restrictBody'));
    assert.deepEqual(changes, [true, false]);

    await click('[data-test-subj=dataGridKeyboardShortcutsButton]');
    assert.dom('[data-test-subj=dataGridKeyboardShortcutsPopover] h2, .euiPopoverTitle h2', document.body).hasText('Keyboard shortcuts');
    assert.dom('.euiDataGrid__keyboardShortcuts kbd', document.body).exists({ count: 16 });
    assert.dom('.euiDataGrid__keyboardShortcuts', document.body).includesText('Move to the first cell of the current page');
  });

  test('EuiDataGridToolbarControl renders a badge for custom controls', async function (assert) {
    await render(
      <template>
        <EuiDataGridToolbarControl @iconType="filter" @badgeContent="2/5" data-custom>
          Filters
        </EuiDataGridToolbarControl>
      </template>
    );
    assert.dom('[data-custom]').hasClass('euiDataGridToolbarControl').includesText('Filters');
    assert.dom('[data-custom] .euiDataGridToolbarControl__badge').hasText('2/5').hasAttribute('aria-label', '- Active: 2 out of 5');
  });
});
