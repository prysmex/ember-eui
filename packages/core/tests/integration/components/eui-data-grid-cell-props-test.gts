/**
 * `setCellProps` (SCP1-SCP4): the props a cell renderer sets are on the
 * cell after the render that set them, follow changes, and stay with the
 * invoker's own `class`, `style` and `data-test-subj` (a custom body's
 * `Cell`). They are applied to the element without a tracked write after
 * the render (only `isExpandable` is tracked), so that pass does not make
 * every rendered cell revalidate.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import type {
  EuiDataGridColumn,
  EuiDataGridCustomBodyProps
} from '#src/components/eui-data-grid.gts';

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'a', displayAsText: 'A' },
  { id: 'b', displayAsText: 'B' }
];

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

class State {
  @tracked step = 1;
}

/** Row 0, column a: step 1 and step 2 set different props; other cells none. */
function propsFor(rowIndex: number, columnId: string, step: number): Record<string, unknown> {
  if (rowIndex !== 0 || columnId !== 'a') return {};
  return step === 1
    ? {
        className: 'one-cell',
        style: { backgroundColor: 'red' },
        'data-test-subj': 'one',
        'data-custom': 'yes',
        title: 'first'
      }
    : {
        className: 'two-cell',
        style: { backgroundColor: 'blue' },
        title: 'second'
      };
}

const rowsOf = (data: EuiDataGridCustomBodyProps['visibleRowData']) =>
  Array.from({ length: data.visibleRowCount }, (_, i) => i);

module('Integration | Component | EuiDataGrid setCellProps', function (hooks) {
  setupRenderingTest(hooks);

  test('SCP1 the props are on the cell after the render, with the cell’s own class and style', async function (assert) {
    const state = new State();
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Grid" @columns={{COLUMNS}} @rowCount={{3}} @toolbarVisibility={{false}}>
            <:cell as |c|>
              {{c.setCellProps (propsFor c.rowIndex c.columnId state.step)}}
              {{c.columnId}}{{c.rowIndex}}
            </:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    const first = cell(0, 0);
    assert.dom(first).hasClass('one-cell').hasClass('euiDataGridRowCell');
    assert.dom(first).hasAttribute('data-test-subj', 'dataGridRowCell one');
    assert.dom(first).hasAttribute('data-custom', 'yes');
    assert.dom(first).hasAttribute('title', 'first');
    assert.strictEqual(getComputedStyle(first).backgroundColor, 'rgb(255, 0, 0)');
    assert.strictEqual(first.style.position, 'absolute', 'the cell’s own style stays');
    assert.ok(first.style.width, 'with its width');
    assert.dom(cell(1, 0)).doesNotHaveClass('one-cell');
    assert.dom(cell(1, 0)).doesNotHaveAttribute('data-custom');
    assert.dom(cell(1, 0)).hasAttribute('data-test-subj', 'dataGridRowCell');
  });

  test('SCP2 new props replace the old ones: classes, style and attributes that are gone are removed', async function (assert) {
    const state = new State();
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Grid" @columns={{COLUMNS}} @rowCount={{3}} @toolbarVisibility={{false}}>
            <:cell as |c|>
              {{c.setCellProps (propsFor c.rowIndex c.columnId state.step)}}
              {{c.columnId}}{{c.rowIndex}}
            </:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    const first = cell(0, 0);
    state.step = 2;
    await settled();
    assert.strictEqual(cell(0, 0), first, 'the same cell');
    assert.dom(first).hasClass('two-cell').doesNotHaveClass('one-cell');
    assert.dom(first).hasAttribute('data-test-subj', 'dataGridRowCell');
    assert.dom(first).doesNotHaveAttribute('data-custom');
    assert.dom(first).hasAttribute('title', 'second');
    assert.strictEqual(getComputedStyle(first).backgroundColor, 'rgb(0, 0, 255)');
    assert.strictEqual(first.style.position, 'absolute');

    // a later render of the cell's own class (focus) keeps the props
    await click(first);
    assert.dom(first).hasClass('two-cell');
    assert.strictEqual(getComputedStyle(first).backgroundColor, 'rgb(0, 0, 255)');
    state.step = 1;
    await settled();
    assert.dom(first).hasClass('one-cell').doesNotHaveClass('two-cell');
    assert.dom(first).hasAttribute('data-custom', 'yes');
  });

  test('SCP3 isExpandable from setCellProps still changes what the cell renders', async function (assert) {
    class Expand {
      @tracked expandable = false;
    }
    const state = new Expand();
    const props = (rowIndex: number, expandable: boolean) =>
      rowIndex === 0 ? { isExpandable: expandable } : {};
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Grid" @columns={{COLUMNS}} @rowCount={{3}} @toolbarVisibility={{false}}>
            <:cell as |c|>
              {{c.setCellProps (props c.rowIndex state.expandable)}}
              {{c.columnId}}{{c.rowIndex}}
            </:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    await click(cell(0, 0));
    assert.dom('.euiDataGridRowCell__actions', cell(0, 0)).doesNotExist('isExpandable: false');
    state.expandable = true;
    await settled();
    assert.dom('.euiDataGridRowCell__actions', cell(0, 0)).exists('isExpandable: true');
  });

  test('SCP4 a custom body’s Cell with its own class and style: the props join the class as before', async function (assert) {
    const state = new State();
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid aria-label="Grid" @columns={{COLUMNS}} @rowCount={{2}} @toolbarVisibility={{false}}>
            <:customGridBody as |body|>
              {{#each (rowsOf body.visibleRowData) as |rowIndex|}}
                <div role="row">
                  {{#each body.visibleColumns as |_column colIndex|}}
                    <body.Cell
                      class="caller-class"
                      @colIndex={{colIndex}}
                      @visibleRowIndex={{rowIndex}}
                      as |c|
                    >
                      {{c.setCellProps (propsFor c.rowIndex c.columnId state.step)}}
                      {{c.columnId}}{{c.rowIndex}}
                    </body.Cell>
                  {{/each}}
                </div>
              {{/each}}
            </:customGridBody>
          </EuiDataGrid>
        </div>
      </template>
    );
    const first = cell(0, 0);
    assert.dom(first).hasClass('caller-class').hasClass('one-cell').hasClass('euiDataGridRowCell');
    assert.dom(first).hasAttribute('data-custom', 'yes');
    assert.strictEqual(getComputedStyle(first).backgroundColor, 'rgb(255, 0, 0)');
    state.step = 2;
    await settled();
    assert.dom(first).hasClass('caller-class').hasClass('two-cell').doesNotHaveClass('one-cell');
    assert.dom(first).doesNotHaveAttribute('data-custom');
    assert.strictEqual(getComputedStyle(first).backgroundColor, 'rgb(0, 0, 255)');
  });
});
