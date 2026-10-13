import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';

import EuiDataGrid from '#src/components/eui-data-grid.gts';
import EuiButtonEmpty from '#src/components/eui-button-empty.gts';

import type { TOC } from '@ember/component/template-only';

import type {
  EuiDataGridCellPopoverElementProps,
  EuiDataGridCellValueSignature,
  EuiDataGridDisplaySelectorCustomRenderProps,
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
      await waitUntil(() => cell(0, 0).querySelector('[data-datagrid-cellcontent]')?.textContent?.trim() === '4');

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
      assert.dom('[data-datagrid-cellcontent]', cell(50, 0)).hasText('a50');

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
      assert.dom('[data-datagrid-cellcontent]', cell(2, 1)).hasText('b2');
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
      assert.dom('[data-datagrid-cellcontent]', cell(0, 0)).hasText('a-2', 'visible rows map to the page');
      assert.dom('.euiDataGridFooter [role=gridcell]').exists({ count: 3 });
      assert.dom('.euiDataGridFooter').includesText('total a');
      await click(cell(1, 2));
      assert.dom('.euiDataGridRowCell__actions', cell(1, 2)).doesNotExist('@isExpandable override');
    });
  });

  module('rowHeightsOptions.scrollAnchorRow', function () {
    class Heights {
      @tracked options: Record<string, unknown>;
      constructor(anchor?: 'start' | 'center') {
        this.options = anchor ? { scrollAnchorRow: anchor } : {};
      }
      growFirstRows(anchor?: 'start' | 'center') {
        this.options = {
          ...(anchor ? { scrollAnchorRow: anchor } : {}),
          rowHeights: { 0: { height: 120 }, 1: { height: 120 } }
        };
      }
    }

    async function renderGrid(heights: Heights) {
      await render(
        <template>
          <div style="width:400px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @rowCount={{100}}
              @height={{300}}
              @toolbarVisibility={{false}}
              @rowHeightsOptions={{heights.options}}
            >
              <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
    }

    async function scrollTo(outer: HTMLElement, top: number) {
      outer.scrollTop = top;
      await triggerEvent(outer, 'scroll');
    }

    test("'start' keeps the first visible row in place when rows above grow", async function (assert) {
      const heights = new Heights('start');
      await renderGrid(heights);
      const outer = el('.euiDataGrid__virtualized');
      const rowHeight = cell(0, 0).offsetHeight;
      await scrollTo(outer, rowHeight * 40);

      heights.growFirstRows('start');
      await settled();
      await frame();
      const growth = 2 * (120 - rowHeight);
      assert.strictEqual(outer.scrollTop, rowHeight * 40 + growth, 'scrolled by the layout shift');
      const firstVisible = cell(40, 0).closest<HTMLElement>('[role=row]')!;
      assert.strictEqual(
        parseFloat(firstVisible.style.top) - el('.euiDataGridHeader').offsetHeight,
        outer.scrollTop,
        'row 40 is still the first visible row'
      );
    });

    test("'center' compensates too; without an anchor the scroll position stays", async function (assert) {
      const centered = new Heights('center');
      await renderGrid(centered);
      let outer = el('.euiDataGrid__virtualized');
      const rowHeight = cell(0, 0).offsetHeight;
      await scrollTo(outer, rowHeight * 40);
      centered.growFirstRows('center');
      await settled();
      await frame();
      assert.strictEqual(outer.scrollTop, rowHeight * 40 + 2 * (120 - rowHeight));

      const unanchored = new Heights();
      await renderGrid(unanchored);
      outer = el('.euiDataGrid__virtualized');
      await scrollTo(outer, rowHeight * 40);
      unanchored.growFirstRows();
      await settled();
      await frame();
      assert.strictEqual(outer.scrollTop, rowHeight * 40, 'no compensation by default');
    });
  });

  module('tabular copy', function () {
    function copySelection(): { text: string; prevented: boolean } {
      const clipboardData = new DataTransfer();
      const event = new ClipboardEvent('copy', { clipboardData, bubbles: true, cancelable: true });
      document.dispatchEvent(event);
      return { text: clipboardData.getData('text/plain'), prevented: event.defaultPrevented };
    }

    function select(node: Node) {
      const range = document.createRange();
      range.selectNodeContents(node);
      const selection = window.getSelection()!;
      selection.removeAllRanges();
      selection.addRange(range);
    }

    test('a selection across cells copies as tab/newline separated text', async function (assert) {
      const controlColumns = [{ id: 'select', width: 40 }];
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @rowCount={{2}}
              @toolbarVisibility={{false}}
              @leadingControlColumns={{controlColumns}}
            >
              <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
              <:controlHeaderCell>Select</:controlHeaderCell>
              <:controlCell>[ ]</:controlCell>
            </EuiDataGrid>
          </div>
        </template>
      );

      // markers are hidden from screen readers and visually
      const markers = document.querySelectorAll('[data-tabular-copy-marker]');
      assert.ok(markers.length > 0);
      assert.ok(
        Array.from(markers).every((marker) => marker.getAttribute('aria-hidden') === 'true'),
        'aria-hidden markers'
      );
      assert.dom('[role=grid] > [data-tabular-copy-marker=boundary]').exists({ count: 2 });
      assert.dom('[data-tabular-copy-marker=newline]', header(3)).exists('last data column ends the row');
      assert.dom('[data-tabular-copy-marker=tab]', cell(0, 1)).exists();
      assert.dom('[data-tabular-copy-marker=no-copy]', cell(0, 0)).exists({ count: 2 }, 'control columns are not copied');

      select(el('[role=grid]'));
      const { text, prevented } = copySelection();
      assert.true(prevented);
      assert.strictEqual(text, 'A\tB\tC\na0\tb0\tc0\na1\tb1\tc1\n');

      // the focused cell's screen reader description is not copied either
      await click(cell(1, 2));
      select(el('[role=grid]'));
      assert.strictEqual(copySelection().text, 'A\tB\tC\na0\tb0\tc0\na1\tb1\tc1\n');
      window.getSelection()!.removeAllRanges();
    });

    test('copying without a selection still copies the focused cell', async function (assert) {
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid aria-label="Grid" @columns={{COLUMNS}} @rowCount={{2}} @toolbarVisibility={{false}}>
              <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      window.getSelection()!.removeAllRanges();
      await click(cell(1, 1));
      assert.strictEqual(copySelection().text, 'b1');
    });
  });

  module('other upstream props', function () {
    test('showDisplaySelector.additionalDisplaySettings and customRender', async function (assert) {
      const Extra: TOC<{ Args: Record<string, never> }> = <template>
        <p data-test-subj="extraSettings">Extra settings</p>
      </template>;
      const Custom: TOC<{ Args: EuiDataGridDisplaySelectorCustomRenderProps }> = <template>
        <div class="customDisplay">
          {{#if @additionalDisplaySettings}}<@additionalDisplaySettings />{{/if}}
          {{#if @rowHeightControl}}<@rowHeightControl />{{/if}}
          {{#if @densityControl}}<@densityControl />{{/if}}
          <span class="hasReset">{{if @resetButton "yes" "no"}}</span>
        </div>
      </template>;
      const onlyExtra = {
        showDisplaySelector: { allowDensity: false, allowRowHeight: false, additionalDisplaySettings: Extra }
      };
      const custom = { showDisplaySelector: { additionalDisplaySettings: Extra, customRender: Custom } };
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid id="extra" aria-label="A" @columns={{COLUMNS}} @rowCount={{1}} @toolbarVisibility={{onlyExtra}} />
            <EuiDataGrid id="custom" aria-label="B" @columns={{COLUMNS}} @rowCount={{1}} @toolbarVisibility={{custom}} />
          </div>
        </template>
      );

      await click('#extra [data-test-subj=dataGridDisplaySelectorButton]');
      assert.dom('[data-test-subj=extraSettings]', document.body).exists('the popover shows with only extra settings');
      assert.dom('[data-test-subj=densityButtonGroup]', document.body).doesNotExist();
      await click('#extra [data-test-subj=dataGridDisplaySelectorButton]');

      await click('#custom [data-test-subj=dataGridDisplaySelectorButton]');
      const custom2 = el('.customDisplay', document.body);
      const order = Array.from(
        custom2.querySelectorAll('[data-test-subj=extraSettings], [data-test-subj=rowHeightButtonGroup], [data-test-subj=densityButtonGroup]'),
        (node) => node.getAttribute('data-test-subj')
      );
      assert.deepEqual(order, ['extraSettings', 'rowHeightButtonGroup', 'densityButtonGroup']);
      assert.dom('.hasReset', custom2).hasText('no', 'no reset button before changes');
      await click(el('[data-test-subj=densityButtonGroup] .euiButtonGroupButton', custom2));
      assert.dom('.hasReset', custom2).hasText('yes');
      assert.dom('#custom').hasClass('euiDataGrid--fontSizeSmall', 'the controls keep working');
    });

    test('renderCellPopover gets cellActions and DefaultCellPopover', async function (assert) {
      const CellValue: TOC<EuiDataGridCellValueSignature> = <template>
        <span class="value" data-details={{if @isDetails "yes" "no"}}>{{@columnId}}{{@rowIndex}}</span>
      </template>;
      const Popover: TOC<{ Args: EuiDataGridCellPopoverElementProps; Blocks: { default: [] } }> = <template>
        <div class="customPopover">
          {{#let @DefaultCellPopover as |DefaultCellPopover|}}
            <DefaultCellPopover>{{yield}}</DefaultCellPopover>
          {{/let}}
        </div>
      </template>;
      const columns: EuiDataGridColumn[] = [
        {
          id: 'a',
          cellActions: [{ iconType: 'plusInCircle', label: 'Filter in', onClick: () => {}, 'data-test-subj': 'filterIn' }]
        },
        { id: 'json', schema: 'json' }
      ];
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{columns}}
              @rowCount={{1}}
              @toolbarVisibility={{false}}
              @renderCellValue={{CellValue}}
              @renderCellPopover={{Popover}}
            />
          </div>
        </template>
      );

      await click(cell(0, 0));
      await press('Enter');
      const popover = el('.customPopover', document.body);
      assert.dom('.euiText .value', popover).hasAttribute('data-details', 'yes', 'children in EuiText');
      assert.dom('.euiPopoverFooter [data-test-subj=filterIn]', popover).exists('cell actions footer');
      await press('Escape', popover.querySelector('button')!);
    });

    test('the <:cellPopover> block gets DefaultCellPopover (json schema)', async function (assert) {
      const columns: EuiDataGridColumn[] = [{ id: 'json', schema: 'json' }];
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid aria-label="Grid" @columns={{columns}} @rowCount={{1}} @toolbarVisibility={{false}}>
              <:cell>{"a":1}</:cell>
              <:cellPopover as |popover|>
                <div class="blockPopover"><popover.DefaultCellPopover /></div>
              </:cellPopover>
            </EuiDataGrid>
          </div>
        </template>
      );
      await click(cell(0, 0));
      await press('Enter');
      assert.dom('.blockPopover .euiCodeBlock', document.body).includesText('"a": 1');
    });

    test('virtualizationOptions className, style and initial scroll offsets', async function (assert) {
      const options = {
        className: 'myVirtualized',
        style: { outline: '1px solid red', zIndex: 3 },
        initialScrollTop: 340
      };
      await render(
        <template>
          <div style="width:400px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @rowCount={{100}}
              @height={{300}}
              @toolbarVisibility={{false}}
              @virtualizationOptions={{options}}
            >
              <:cell as |c|>{{c.columnId}}{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      await waitUntil(() => el('.euiDataGrid__virtualized').scrollTop === 340);
      const outer = el('.euiDataGrid__virtualized');
      assert.dom(outer).hasClass('myVirtualized');
      assert.strictEqual(outer.style.outlineStyle, 'solid');
      assert.strictEqual(outer.style.zIndex, '3');
      assert.strictEqual(outer.style.overflow, 'auto', 'own styles kept');
      assert.strictEqual(outer.scrollTop, 340);
    });
  });

  module('editing in the cell popover', function () {
    class Editor {
      api: EuiDataGridRefProps | null = null;
      @tracked rows = [{ a: 'one' }, { a: 'two' }];
      registerApi = (api: EuiDataGridRefProps) => {
        this.api = api;
      };
      save = (rowIndex: number, colIndex: number, event: SubmitEvent) => {
        event.preventDefault();
        const value = (new FormData(event.target as HTMLFormElement).get('value') as string | null) ?? '';
        this.rows = this.rows.map((row, i) => (i === rowIndex ? { a: value } : row));
        this.api!.closeCellPopover();
        this.api!.setFocusedCell({ rowIndex, colIndex });
      };
    }

    test('a form in <:cellPopover> edits the data; keys typed in it stay in the form', async function (assert) {
      const editor = new Editor();
      const columns: EuiDataGridColumn[] = [{ id: 'a', displayAsText: 'A' }, { id: 'b', displayAsText: 'B' }];
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{columns}}
              @rowCount={{2}}
              @toolbarVisibility={{false}}
              @registerApi={{editor.registerApi}}
            >
              <:cell as |c|>{{if (eqId c.columnId "a") (getA editor.rows c.rowIndex) "-"}}</:cell>
              <:cellPopover as |popover|>
                <form {{on "submit" (fn editor.save popover.rowIndex popover.colIndex)}}>
                  <input name="value" value={{getA editor.rows popover.rowIndex}} aria-label="Value" />
                  <button type="submit">Save</button>
                </form>
              </:cellPopover>
            </EuiDataGrid>
          </div>
        </template>
      );

      await click(cell(1, 0));
      await press('Enter');
      const field = el('[data-test-subj=euiDataGridExpansionPopover] input[name=value]', document.body) as HTMLInputElement;
      await waitUntil(() => document.activeElement === field);
      await press('ArrowRight', field);
      await press('ArrowDown', field);
      assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).exists('still editing');
      assert.strictEqual(document.activeElement, field, 'arrow keys in the form do not move grid focus');

      field.value = 'changed';
      await click(el('[data-test-subj=euiDataGridExpansionPopover] button[type=submit]', document.body));
      assert.deepEqual(editor.rows, [{ a: 'one' }, { a: 'changed' }]);
      assert.dom('[data-test-subj=euiDataGridExpansionPopover]', document.body).doesNotExist();
      assert.dom('[data-datagrid-cellcontent]', cell(1, 0)).hasText('changed');
      await waitUntil(() => document.activeElement === cell(1, 0));
      assert.ok(true, 'focus returned to the edited cell');
    });
  });
});

function eqId(a: string, b: string): boolean {
  return a === b;
}

function getA(rows: Array<{ a: string }>, index: number): string {
  return rows[index]?.a ?? '';
}
