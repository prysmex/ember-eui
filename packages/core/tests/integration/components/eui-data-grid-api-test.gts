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
import { hash } from '@ember/helper';

import EuiDataGrid from '#src/components/eui-data-grid.gts';
import EuiButtonEmpty from '#src/components/eui-button-empty.gts';

import type { TOC } from '@ember/component/template-only';

import type {
  EuiDataGridCellValueSignature,
  EuiDataGridColumn,
  EuiDataGridCustomBodyProps,
  EuiDataGridCustomToolbarProps,
  EuiDataGridRefProps
} from '#src/components/eui-data-grid.gts';

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function header(col: number): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-index="${col}"]`);
}

function cell(row: number, col: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${col}"]`
  );
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

  module('imperative API (@registerApi)', function () {
    class ApiState {
      api: EuiDataGridRefProps | null = null;
      fullScreen: boolean[] = [];
      @tracked pageIndex = 0;
      registerApi = (api: EuiDataGridRefProps) => {
        this.api = api;
      };
      onFullScreenChange = (isFullScreen: boolean) => this.fullScreen.push(isFullScreen);
      private self = this;
      pagination = {
        self: this.self,
        // read lazily so the grid sees page changes
        get pageIndex(): number {
          return this.self.pageIndex;
        },
        pageSize: 2,
        pageSizeOptions: [2],
        onChangePage: (pageIndex: number) => {
          this.pageIndex = pageIndex;
        },
        onChangeItemsPerPage: () => {}
      };
    }

    test('setFocusedCell, cell popovers and fullscreen', async function (assert) {
      const state = new ApiState();
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @rowCount={{4}}
              @registerApi={{state.registerApi}}
              @onFullScreenChange={{state.onFullScreenChange}}
            >
              <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      const api = state.api!;
      assert.ok(api, 'the API is registered after render');
      assert.deepEqual(
        Object.keys(api).sort(),
        ['closeCellPopover', 'openCellPopover', 'scrollTo', 'scrollToItem', 'setFocusedCell', 'setIsFullScreen']
      );

      api.setFocusedCell({ rowIndex: 2, colIndex: 1 });
      await settled();
      assert.strictEqual(document.activeElement, cell(2, 1));
      assert.dom(cell(2, 1)).hasAttribute('tabindex', '0');

      api.openCellPopover({ rowIndex: 1, colIndex: 2 });
      await settled();
      assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).hasText('c1');
      assert.dom(cell(1, 2)).hasClass('euiDataGridRowCell--open');
      api.closeCellPopover();
      await settled();
      assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).doesNotExist();

      api.setIsFullScreen(true);
      await settled();
      assert.dom('.euiDataGrid').hasClass('euiDataGrid--fullScreen');
      api.setIsFullScreen(false);
      await settled();
      assert.dom('.euiDataGrid').doesNotHaveClass('euiDataGrid--fullScreen');
      assert.deepEqual(state.fullScreen, [true, false]);

      assert.throws(
        () => api.setFocusedCell({ rowIndex: 4, colIndex: 0 }),
        /Row 4 is not a valid row. The maximum visible row index is 3./
      );
      assert.throws(
        () => api.openCellPopover({ rowIndex: 0, colIndex: 3 }),
        /Column 3 is not a valid column. The maximum visible column index is 2./
      );
    });

    test('targets rows on other pages and sorted rows by their data index', async function (assert) {
      const state = new ApiState();
      const sorting = { columns: [{ id: 'a', direction: 'desc' as const }], onSort: () => {} };
      const inMemory = { level: 'sorting' as const };
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @rowCount={{5}}
              @sorting={{sorting}}
              @inMemory={{inMemory}}
              @pagination={{state.pagination}}
              @registerApi={{state.registerApi}}
            >
              <:cell as |c|>{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      await waitUntil(() => cell(0, 0).textContent?.trim() === '4');

      // descending: data row 4 is visible row 0, data row 1 is visible row 3 (page 2)
      state.api!.setFocusedCell({ rowIndex: 4, colIndex: 0 });
      await settled();
      assert.strictEqual(document.activeElement, cell(0, 0));

      state.api!.setFocusedCell({ rowIndex: 1, colIndex: 1 });
      await settled();
      assert.strictEqual(state.pageIndex, 1, 'moved to the page of the row');
      await waitUntil(() => document.activeElement === cell(1, 1));
      assert.dom(document.activeElement).hasAttribute('data-gridcell-row-index', '1');
    });

    test('scrollTo and scrollToItem scroll the virtualized body', async function (assert) {
      const state = new ApiState();
      await render(
        <template>
          <div style="width:400px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @rowCount={{100}}
              @height={{300}}
              @toolbarVisibility={{false}}
              @registerApi={{state.registerApi}}
            >
              <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      const outer = el('.euiDataGrid__virtualized');
      const rowHeight = cell(0, 0).offsetHeight;

      state.api!.scrollTo!({ scrollTop: rowHeight * 10 });
      await settled();
      assert.strictEqual(outer.scrollTop, rowHeight * 10);
      assert.dom(cell(10, 0)).exists('rows in the new window render');

      state.api!.scrollToItem!({ rowIndex: 50, align: 'start' });
      await settled();
      assert.strictEqual(outer.scrollTop, rowHeight * 50, "'start' puts the row under the header");
      assert.dom(cell(50, 0)).hasText('a50');

      state.api!.scrollToItem!({ rowIndex: 49 });
      await settled();
      assert.strictEqual(outer.scrollTop, rowHeight * 49, "'auto' scrolls just enough");

      state.api!.scrollToItem!({ rowIndex: 0, align: 'smart' });
      await settled();
      assert.strictEqual(outer.scrollTop, 0, "'smart' centers far rows (clamped)");
    });
  });

  module('renderCustomToolbar', function () {
    const AddButton: TOC<{ Args: Record<string, never> }> = <template>
      <EuiButtonEmpty @size="xs" data-test-subj="addButton">Add</EuiButtonEmpty>
    </template>;
    const RightButton: TOC<{ Args: Record<string, never> }> = <template>
      <EuiButtonEmpty @size="xs" data-test-subj="rightButton">Right</EuiButtonEmpty>
    </template>;

    test('the <:customToolbar> block lays out the yielded controls', async function (assert) {
      const sorting = { columns: [], onSort: () => {} };
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid aria-label="Grid" @columns={{COLUMNS}} @rowCount={{2}} @sorting={{sorting}}>
              <:customToolbar as |toolbar|>
                <div class="myToolbar" data-room={{if toolbar.hasRoomForGridControls "yes" "no"}}>
                  <toolbar.fullScreenControl />
                  <toolbar.keyboardShortcutsControl />
                  <toolbar.displayControl />
                  <toolbar.columnSortingControl />
                  <toolbar.columnControl />
                </div>
              </:customToolbar>
            </EuiDataGrid>
          </div>
        </template>
      );

      assert.dom('[data-test-subj=dataGridControls]').doesNotExist('replaces the default toolbar');
      assert.dom('.myToolbar').hasAttribute('data-room', 'yes');
      const order = Array.from(
        el('.myToolbar').querySelectorAll('[data-test-subj$=Button]'),
        (button) => button.getAttribute('data-test-subj')
      );
      assert.deepEqual(order, [
        'dataGridFullScreenButton',
        'dataGridKeyboardShortcutsButton',
        'dataGridDisplaySelectorButton',
        'dataGridColumnSortingButton',
        'dataGridColumnSelectorButton'
      ]);
      await click('[data-test-subj=dataGridFullScreenButton]');
      assert.dom('.euiDataGrid').hasClass('euiDataGrid--fullScreen', 'the controls keep working');
      await click('[data-test-subj=dataGridFullScreenButton]');
      await click('[data-test-subj=dataGridColumnSelectorButton]');
      assert.dom('[data-test-subj=dataGridColumnSelectorPopover]', document.body).exists();
    });

    test('@renderCustomToolbar gets hidden controls as undefined and additional controls', async function (assert) {
      const received: Partial<EuiDataGridCustomToolbarProps>[] = [];
      const record = (props: Partial<EuiDataGridCustomToolbarProps>) => {
        received.push(props);
        return '';
      };
      const CustomToolbar: TOC<{ Args: EuiDataGridCustomToolbarProps }> = <template>
        <div class="myToolbar">
          {{record
            (hash
              displayControl=@displayControl
              columnSortingControl=@columnSortingControl
              additionalControls=@additionalControls
            )
          }}
          {{#if @additionalControls.leftPrepend}}<@additionalControls.leftPrepend />{{/if}}
          {{#if @columnControl}}<@columnControl />{{/if}}
          {{#if @displayControl}}<@displayControl />{{/if}}
          {{#if @additionalControls.right}}<@additionalControls.right />{{/if}}
          <@keyboardShortcutsControl />
        </div>
      </template>;
      const visibility = {
        showDisplaySelector: false,
        showKeyboardShortcuts: false,
        additionalControls: { left: { prepend: AddButton }, right: RightButton }
      };
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @rowCount={{2}}
              @toolbarVisibility={{visibility}}
              @renderCustomToolbar={{CustomToolbar}}
            />
          </div>
        </template>
      );

      assert.dom('[data-test-subj=dataGridControls]').doesNotExist();
      assert.dom('.myToolbar [data-test-subj=addButton]').exists();
      assert.dom('.myToolbar [data-test-subj=rightButton]').exists();
      assert.dom('.myToolbar [data-test-subj=dataGridColumnSelectorButton]').exists();
      assert.dom('.myToolbar [data-test-subj=dataGridDisplaySelectorButton]').doesNotExist();
      assert.dom('.myToolbar .euiScreenReaderOnly-showOnFocus [data-test-subj=dataGridKeyboardShortcutsButton]').exists(
        'hidden keyboard shortcuts stay reachable'
      );
      const props = received.at(-1)!;
      assert.strictEqual(props.displayControl, undefined);
      assert.strictEqual(props.columnSortingControl, undefined, 'no sort control without @sorting');
      assert.strictEqual(props.additionalControls?.leftAppend, undefined);
    });

    test('the default toolbar renders additionalControls components', async function (assert) {
      const single = { additionalControls: AddButton };
      const positioned = { additionalControls: { left: { prepend: AddButton }, right: RightButton } };
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid id="single" aria-label="A" @columns={{COLUMNS}} @rowCount={{1}} @toolbarVisibility={{single}} />
            <EuiDataGrid id="positioned" aria-label="B" @columns={{COLUMNS}} @rowCount={{1}} @toolbarVisibility={{positioned}} />
          </div>
        </template>
      );
      const left = el('#single .euiDataGrid__leftControls');
      assert.strictEqual(
        left.lastElementChild?.getAttribute('data-test-subj'),
        'addButton',
        'a single component is appended to the left side'
      );
      assert.strictEqual(
        el('#positioned .euiDataGrid__leftControls').firstElementChild?.getAttribute('data-test-subj'),
        'addButton'
      );
      assert.strictEqual(
        el('#positioned .euiDataGrid__rightControls').firstElementChild?.getAttribute('data-test-subj'),
        'rightButton'
      );
    });
  });

  module('renderCustomGridBody', function () {
    const rowsOf = (data: EuiDataGridCustomBodyProps['visibleRowData']) =>
      Array.from({ length: data.visibleRowCount }, (_, i) => i);

    test('the <:customGridBody> block renders cells without virtualization', async function (assert) {
      const bodyProps = { className: 'myBody', 'data-test-subj': 'myBody', style: { maxHeight: 400 } };
      const calls: string[] = [];
      const onScroll = () => calls.push('scroll');
      const props = { ...bodyProps, onScroll };
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid aria-label="Grid" @columns={{COLUMNS}} @rowCount={{3}} @toolbarVisibility={{false}}>
              <:customGridBody as |body|>
                {{body.setCustomGridBodyProps props}}
                <body.headerRow />
                {{#each (rowsOf body.visibleRowData) as |rowIndex|}}
                  <div role="row" class="myRow">
                    {{#each body.visibleColumns as |_column colIndex|}}
                      <body.Cell @colIndex={{colIndex}} @visibleRowIndex={{rowIndex}} as |cell|>
                        {{cell.columnId}}{{cell.rowIndex}}
                      </body.Cell>
                    {{/each}}
                  </div>
                {{/each}}
              </:customGridBody>
            </EuiDataGrid>
          </div>
        </template>
      );

      assert.dom('.euiDataGrid__virtualized').doesNotExist();
      assert.dom('.euiDataGrid__customRenderBody').hasClass('myBody');
      assert.dom('.euiDataGrid__customRenderBody').hasAttribute('data-test-subj', 'myBody');
      assert.strictEqual(el('.euiDataGrid__customRenderBody').style.maxHeight, '400px');
      assert.strictEqual(getComputedStyle(el('.euiDataGrid__customRenderBody')).overflowY, 'auto');
      el('.euiDataGrid__customRenderBody').dispatchEvent(new Event('scroll'));
      assert.deepEqual(calls, ['scroll'], 'on* props become listeners');

      assert.dom('[role=grid] .euiDataGridHeader[role=row]').exists();
      assert.dom('.myRow').exists({ count: 3 });
      assert.dom('[role=gridcell]').exists({ count: 9 });
      assert.dom(cell(2, 1)).hasText('b2');
      assert.notStrictEqual(cell(0, 0).style.position, 'absolute', 'cells flow in the consumer rows');
      assert.ok(cell(0, 0).offsetHeight > 20, 'cells keep the row height');
      assert.strictEqual(cell(0, 1).style.width, header(1).style.width, 'columns share widths');

      // grid keyboard navigation and expansion still work
      await click(cell(0, 0));
      await press('ArrowDown');
      assert.strictEqual(document.activeElement, cell(1, 0));
      await press('ArrowRight');
      assert.strictEqual(document.activeElement, cell(1, 1));
      await press('Enter');
      assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).hasText('b1');
    });

    test('@renderCustomGridBody gets header/footer rows and follows pagination', async function (assert) {
      const CellValue: TOC<EuiDataGridCellValueSignature> = <template>
        <span class="value">{{@columnId}}-{{@rowIndex}}</span>
      </template>;
      const Footer: TOC<EuiDataGridCellValueSignature> = <template>total {{@columnId}}</template>;
      const Body: TOC<{ Args: EuiDataGridCustomBodyProps }> = <template>
        {{#if @headerRow}}<@headerRow />{{/if}}
        <div class="rows" data-start={{@visibleRowData.startRow}} data-end={{@visibleRowData.endRow}}>
          {{#each (rowsOf @visibleRowData) as |rowIndex|}}
            <div role="row">
              {{#each @visibleColumns as |_column colIndex|}}
                <@Cell @colIndex={{colIndex}} @visibleRowIndex={{rowIndex}} @isExpandable={{false}} />
              {{/each}}
            </div>
          {{/each}}
        </div>
        {{#if @footerRow}}<@footerRow />{{/if}}
      </template>;
      const pagination = {
        pageIndex: 1,
        pageSize: 2,
        pageSizeOptions: [2],
        onChangePage: () => {},
        onChangeItemsPerPage: () => {}
      };
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @rowCount={{5}}
              @pagination={{pagination}}
              @toolbarVisibility={{false}}
              @headerVisibility={{false}}
              @renderCellValue={{CellValue}}
              @renderFooterCellValue={{Footer}}
              @renderCustomGridBody={{Body}}
            />
          </div>
        </template>
      );

      assert.dom('[role=columnheader]').doesNotExist('no header row with @headerVisibility=false');
      assert.dom('.rows').hasAttribute('data-start', '2');
      assert.dom('.rows').hasAttribute('data-end', '4');
      assert.dom('.rows [role=gridcell]').exists({ count: 6 });
      assert.dom(cell(0, 0)).hasText('a-2', 'visible rows map to the page');
      assert.dom('.euiDataGridFooter [role=gridcell]').exists({ count: 3 });
      assert.dom('.euiDataGridFooter').includesText('total a');
      await click(cell(1, 2));
      assert.dom('.euiDataGridRowCell__actions', cell(1, 2)).doesNotExist('@isExpandable override');
    });
  });
});
