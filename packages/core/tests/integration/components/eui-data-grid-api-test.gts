import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  focus,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import type { EuiDataGridColumn } from '#src/components/eui-data-grid.gts';

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function header(col: number): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-index="${col}"]`);
}

function headerIds(): string[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>('[role=columnheader]'),
    (cell) => cell.dataset['gridcellColumnId'] ?? ''
  );
}

const frame = () => new Promise((resolve) => requestAnimationFrame(() => resolve(undefined)));

async function press(key: string, target: Element = document.activeElement!) {
  await triggerKeyEvent(target, 'keydown', key);
}

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'a', displayAsText: 'A' },
  { id: 'b', displayAsText: 'B' },
  { id: 'c', displayAsText: 'C' }
];

class Visibility {
  @tracked visibleColumns = ['a', 'b', 'c'];
  canDragAndDropColumns = true;
  setVisibleColumns = (ids: string[]) => {
    this.visibleColumns = ids;
  };
}

module('Integration | Component | EuiDataGrid API', function (hooks) {
  setupRenderingTest(hooks);

  module('header column drag and drop', function () {
    test('renders draggable header cells with instructions and the drag icon', async function (assert) {
      const visibility = new Visibility();
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @columnVisibility={{visibility}}
              @rowCount={{3}}
              @toolbarVisibility={{false}}
            >
              <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );

      assert.dom('[data-test-subj=euiDataGridHeaderDroppable]').exists();
      assert.dom('[data-test-subj=euiDataGridHeaderDroppable] .euiDraggable').exists({ count: 3 });
      assert.strictEqual(
        getComputedStyle(el('[data-test-subj=euiDataGridHeaderDroppable]')).display,
        'flex'
      );
      assert.dom('.euiDataGridHeaderCell__draggableIcon').exists({ count: 3 });
      const describedBy = header(0).getAttribute('aria-describedby')!;
      const instructions = document.getElementById(describedBy);
      assert.ok(instructions?.hidden, 'hidden drag instructions');
      assert.dom(instructions).includesText('space bar');
      assert.dom(header(0)).hasAttribute('role', 'columnheader', 'the handle keeps its grid role');
      assert.dom('.euiDraggable[role]').doesNotExist('the draggable wrappers have no role');
      assert.dom('.euiDataGridHeaderCellDraggable .euiDataGridColumnResizer').exists(
        { count: 3 },
        'resizers sit next to the handles'
      );
      assert.dom('.euiDataGridHeaderCell .euiDataGridColumnResizer').doesNotExist();

      // header cells keep the header's shade and a single leading border
      const first = getComputedStyle(header(0));
      const second = getComputedStyle(header(1));
      assert.notStrictEqual(first.borderLeftStyle, 'none');
      assert.strictEqual(second.borderLeftStyle, 'none');
      assert.notStrictEqual(second.backgroundColor, 'rgba(0, 0, 0, 0)');
    });

    test('keyboard: Space lifts, arrows move, Space drops and focus follows the column', async function (assert) {
      const visibility = new Visibility();
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @columnVisibility={{visibility}}
              @rowCount={{3}}
              @toolbarVisibility={{false}}
            >
              <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );

      await focus(header(0));
      await press(' ');
      assert.dom(header(0)).hasAttribute('data-column-moving', 'true', 'lifted with the keyboard');
      await press('ArrowRight');
      assert.strictEqual(document.activeElement, header(0), 'arrows move the column, not grid focus');
      await press('ArrowRight');
      await press(' ');
      await settled();
      await waitUntil(() => document.activeElement === header(2));
      assert.deepEqual(visibility.visibleColumns, ['b', 'c', 'a']);
      assert.deepEqual(headerIds(), ['b', 'c', 'a']);
      assert.strictEqual(document.activeElement?.getAttribute('data-gridcell-column-id'), 'a');
      assert.dom(header(2)).doesNotHaveAttribute('data-column-moving');

      // Escape cancels
      await press(' ');
      await press('ArrowLeft');
      await press('Escape');
      await settled();
      await waitUntil(() => document.activeElement === header(2));
      assert.deepEqual(visibility.visibleColumns, ['b', 'c', 'a'], 'cancelled drags keep the order');

      // grid navigation works again after dropping
      await press('ArrowLeft');
      assert.strictEqual(document.activeElement, header(1));
    });

    test('Enter keeps opening the column actions instead of lifting', async function (assert) {
      const visibility = new Visibility();
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @columnVisibility={{visibility}}
              @rowCount={{3}}
              @toolbarVisibility={{false}}
            />
          </div>
        </template>
      );

      await focus(header(1));
      await press('Enter');
      await settled();
      assert.dom(header(1)).doesNotHaveAttribute('data-column-moving');
      assert.dom(header(1)).hasClass('euiDataGridHeaderCell--isActionsPopoverOpen');
      assert.deepEqual(visibility.visibleColumns, ['a', 'b', 'c']);
    });

    test('dragging a header with the pointer reorders the columns', async function (assert) {
      const visibility = new Visibility();
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @columnVisibility={{visibility}}
              @rowCount={{3}}
              @toolbarVisibility={{false}}
            />
          </div>
        </template>
      );

      const dataTransfer = new DataTransfer();
      const fire = (element: Element, type: string, clientX: number) =>
        element.dispatchEvent(
          new DragEvent(type, {
            bubbles: true,
            cancelable: true,
            dataTransfer,
            clientX,
            clientY: element.getBoundingClientRect().top + 5
          })
        );
      const first = header(0);
      const last = header(2);
      const right = last.getBoundingClientRect().right - 2;

      // native drags start on the draggable element, from a point over its handle
      fire(first.closest('.euiDraggable')!, 'dragstart', first.getBoundingClientRect().left + 5);
      await frame();
      await frame();
      fire(last, 'dragenter', right);
      fire(last, 'dragover', right);
      await frame();
      await frame();
      fire(last, 'drop', right);
      await frame();
      await settled();

      assert.deepEqual(visibility.visibleColumns, ['b', 'c', 'a']);
      await waitUntil(() => document.activeElement === header(2));
      assert.ok(true, 'the dropped column header is focused');
    });

    test('without canDragAndDropColumns the header cells are static', async function (assert) {
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid aria-label="Grid" @columns={{COLUMNS}} @rowCount={{3}} @toolbarVisibility={{false}} />
          </div>
        </template>
      );
      assert.dom('[data-test-subj=euiDataGridHeaderDroppable]').doesNotExist();
      assert.dom('.euiDataGridHeaderCell__draggableIcon').doesNotExist();
      assert.dom('.euiDataGridHeaderCell .euiDataGridColumnResizer').exists({ count: 3 });
      await click(header(0));
      await press(' ');
      assert.dom(header(0)).doesNotHaveAttribute('data-column-moving');
    });
  });
});
