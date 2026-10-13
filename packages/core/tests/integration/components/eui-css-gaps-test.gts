import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiButtonGroup from '#src/components/eui-button-group.gts';
import EuiDragDropContext from '#src/components/eui-drag-drop-context.gts';
import EuiFilterGroup from '#src/components/eui-filter-group.gts';
import EuiTable from '#src/components/eui-table.gts';
import EuiTableBody from '#src/components/eui-table-body.gts';
import EuiTableHeader from '#src/components/eui-table-header.gts';
import EuiTableHeaderCell from '#src/components/eui-table-header-cell.gts';
import EuiTablePagination from '#src/components/eui-table-pagination.gts';
import EuiTableRow from '#src/components/eui-table-row.gts';
import EuiTableRowCell from '#src/components/eui-table-row-cell.gts';

/** The element, a test fails when it is missing. */
function el(root: Element, selector: string): HTMLElement {
  const found = root.querySelector<HTMLElement>(selector);
  if (!found) throw new Error(`Missing ${selector}`);
  return found;
}

/** Emotion classes (a second one would mean a non-composed `css`). */
function generated(element: Element): string[] {
  return Array.from(element.classList).filter((name) =>
    name.startsWith('eui-spike-')
  );
}

// every component sets `box-sizing: border-box`; `@css` must win
const css = { boxSizing: 'content-box' };
const noop = () => {};
const options = [{ id: 'a', label: 'A' }];

module('Integration | Component | @css gaps', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiButtonGroup @css composes last into the fieldset class', async function (assert) {
    await render(
      <template>
        <EuiButtonGroup
          @legend="L"
          @options={{options}}
          @onChange={{noop}}
          @css={{css}}
          data-group
        />
      </template>
    );
    const group = el(this.element, '[data-group]');
    assert.strictEqual(getComputedStyle(group).boxSizing, 'content-box');
    assert.strictEqual(generated(group).length, 1, 'one Emotion class');
  });

  test('EuiFilterGroup @css composes last into the group class', async function (assert) {
    await render(
      <template><EuiFilterGroup @css={{css}} data-group /></template>
    );
    const group = el(this.element, '[data-group]');
    assert.strictEqual(getComputedStyle(group).boxSizing, 'content-box');
    assert.strictEqual(generated(group).length, 1, 'one Emotion class');
  });

  test('EuiDroppable and EuiDraggable @css compose last', async function (assert) {
    await render(
      <template>
        <EuiDragDropContext @onDragEnd={{noop}} as |dnd|>
          <dnd.Droppable @droppableId="l" @css={{css}} as |list|>
            <list.Draggable
              @draggableId="a"
              @index={{0}}
              @css={{css}}
              data-item
            >x</list.Draggable>
          </dnd.Droppable>
          <dnd.Droppable
            @droppableId="p"
            @withPanel={{true}}
            @css={{css}}
            as |list|
          >
            <list.Draggable @draggableId="b" @index={{0}}>y</list.Draggable>
          </dnd.Droppable>
        </EuiDragDropContext>
      </template>
    );
    const lists = this.element.querySelectorAll<HTMLElement>('[data-test-subj="droppable"]');
    const [plain, panel] = [lists[0]!, lists[1]!];
    assert.strictEqual(getComputedStyle(plain).boxSizing, 'content-box');
    assert.strictEqual(generated(plain).length, 1, 'one Emotion class on the list');
    assert.strictEqual(getComputedStyle(panel).boxSizing, 'content-box', 'with a panel');
    assert.strictEqual(generated(panel).length, 1, 'one Emotion class on the panel');
    const item = el(this.element, '[data-item]');
    assert.strictEqual(getComputedStyle(item).boxSizing, 'content-box');
    assert.strictEqual(generated(item).length, 1, 'one Emotion class on the item');
  });

  test('EuiTable @css composes last into the table class', async function (assert) {
    const tableCss = { tableLayout: 'auto' };
    await render(
      <template>
        <EuiTable @css={{tableCss}} data-table>
          <EuiTableBody>
            <EuiTableRow><EuiTableRowCell>x</EuiTableRowCell></EuiTableRow>
          </EuiTableBody>
        </EuiTable>
      </template>
    );
    const table = el(this.element, '[data-table]');
    assert.strictEqual(getComputedStyle(table).tableLayout, 'auto', 'wins over fixed');
    assert.strictEqual(generated(table).length, 1, 'one Emotion class');
  });

  test('EuiTablePagination @aria-label and @aria-labelledby name the navigation', async function (assert) {
    await render(
      <template>
        <EuiTablePagination
          @pageCount={{3}}
          @activePage={{0}}
          @aria-label="Pagination for table: Users"
          @aria-labelledby="named"
        />
      </template>
    );
    const nav = el(this.element, 'nav');
    assert.strictEqual(nav.getAttribute('aria-label'), 'Pagination for table: Users');
    assert.strictEqual(nav.getAttribute('aria-labelledby'), 'named');
  });

  test('EuiTableHeaderCell @tooltipProps: an icon tip, or the tooltip on the sort button', async function (assert) {
    const tip = { content: 'More about it', icon: 'help' };
    await render(
      <template>
        <EuiTable>
          <EuiTableHeader>
            <EuiTableHeaderCell data-plain @tooltipProps={{tip}}>Name</EuiTableHeaderCell>
            <EuiTableHeaderCell
              data-sort
              @onSort={{noop}}
              @tooltipProps={{tip}}
            >Size</EuiTableHeaderCell>
          </EuiTableHeader>
        </EuiTable>
      </template>
    );
    const plain = el(this.element, '[data-plain]');
    assert.ok(plain.querySelector('[tabindex="0"]'), 'focusable icon tip next to the name');
    assert.notOk(plain.querySelector('button'), 'no sort button');

    const sort = el(this.element, '[data-sort]');
    const icons = sort.querySelectorAll('.euiTableSortIcon');
    assert.strictEqual(icons.length, 2, 'tooltip icon and sortable icon inside the button');
    assert.ok(el(sort, 'button'), 'sort button');
  });
});
