import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import Component from '@glimmer/component';
import { click, render, settled, triggerEvent, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { on } from '@ember/modifier';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import type {
  EuiDataGridCellPopoverElementProps,
  EuiDataGridCellValueElementProps,
  EuiDataGridColumn,
  EuiDataGridControlColumn,
  EuiDataGridRefProps,
  EuiDataGridRowTreeRowInfo,
  EuiDataGridScrollEvent
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

async function userScroll(top: number, left = 0) {
  const outer = el('.euiDataGrid__virtualized');
  outer.scrollTop = top;
  outer.scrollLeft = left;
  await triggerEvent(outer, 'scroll');
}

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'a', displayAsText: 'A' },
  { id: 'b', displayAsText: 'B' },
  { id: 'c', displayAsText: 'C' }
];

const WIDE_COLUMNS: EuiDataGridColumn[] = Array.from({ length: 20 }, (_, i) => ({
  id: `col${i}`,
  initialWidth: 120
}));

function pick(event: EuiDataGridScrollEvent) {
  return {
    top: event.scrollTop,
    left: event.scrollLeft,
    vertical: event.verticalScrollDirection,
    horizontal: event.horizontalScrollDirection,
    requested: event.scrollUpdateWasRequested
  };
}

module('Integration | Component | EuiDataGrid upstream gaps', function (hooks) {
  setupRenderingTest(hooks);

  module('virtualizationOptions.onScroll (react-window arguments)', function () {
    test('reports the mount, directions and user scrolling', async function (assert) {
      const scrolls: EuiDataGridScrollEvent[] = [];
      const options = { onScroll: (event: EuiDataGridScrollEvent) => scrolls.push(event) };
      await render(
        <template>
          <div style="width:500px">
            <EuiDataGrid
              @height={{300}}
              @columns={{WIDE_COLUMNS}}
              @rowCount={{500}}
              @toolbarVisibility={{false}}
              @virtualizationOptions={{options}}
            >
              <:cell as |c|>{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );

      assert.strictEqual(scrolls.length, 1, 'called once when the body mounts (react-window componentDidMount)');
      assert.deepEqual(pick(scrolls[0]!), {
        top: 0,
        left: 0,
        vertical: 'forward',
        horizontal: 'forward',
        requested: false
      });
      assert.true(scrolls[0]!.isScrolledToBlockStart);
      assert.ok(scrolls[0]!.scrollHeight > scrolls[0]!.clientHeight, 'DOM sizes are reported too');

      await userScroll(400);
      assert.deepEqual(pick(scrolls.at(-1)!), {
        top: 400,
        left: 0,
        vertical: 'forward',
        horizontal: 'backward',
        requested: false
      }, 'scrolling down: forward; unchanged axis: backward (react-window compares prev < next)');

      await userScroll(100, 200);
      assert.deepEqual(pick(scrolls.at(-1)!), {
        top: 100,
        left: 200,
        vertical: 'backward',
        horizontal: 'forward',
        requested: false
      });

      const count = scrolls.length;
      await triggerEvent(el('.euiDataGrid__virtualized'), 'scroll');
      assert.strictEqual(scrolls.length, count, 'a scroll event at the same position is not reported');
    });

    test('scrolls requested by the grid report scrollUpdateWasRequested', async function (assert) {
      const scrolls: EuiDataGridScrollEvent[] = [];
      let api: EuiDataGridRefProps | undefined;
      const registerApi = (value: EuiDataGridRefProps) => (api = value);
      const options = { onScroll: (event: EuiDataGridScrollEvent) => scrolls.push(event) };
      await render(
        <template>
          <div style="width:500px">
            <EuiDataGrid
              @height={{300}}
              @columns={{COLUMNS}}
              @rowCount={{500}}
              @toolbarVisibility={{false}}
              @virtualizationOptions={{options}}
              @registerApi={{registerApi}}
            >
              <:cell as |c|>{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      await waitUntil(() => api);

      api!.scrollTo!({ scrollTop: 600 });
      await settled();
      const requested = scrolls.filter((event) => event.scrollUpdateWasRequested);
      assert.strictEqual(requested.length, 1, 'one requested scroll');
      assert.strictEqual(requested[0]!.scrollTop, 600);
      assert.strictEqual(requested[0]!.verticalScrollDirection, 'forward');
      const count = scrolls.length;
      // the browser's own scroll event for that position is not reported again
      await triggerEvent(el('.euiDataGrid__virtualized'), 'scroll');
      assert.strictEqual(scrolls.length, count);

      api!.scrollToItem!({ rowIndex: 2, align: 'start' });
      await settled();
      assert.deepEqual(
        { requested: scrolls.at(-1)!.scrollUpdateWasRequested, vertical: scrolls.at(-1)!.verticalScrollDirection },
        { requested: true, vertical: 'backward' }
      );

      // keyboard focus scrolls the cell into view (upstream: react-window scrollTo)
      await userScroll(0);
      cell(0, 0).focus();
      await settled();
      await triggerKeyEvent(cell(0, 0), 'keydown', 'End', { ctrlKey: true });
      await waitUntil(() => el('.euiDataGrid__virtualized').scrollTop > 0);
      const last = scrolls.at(-1)!;
      assert.true(last.scrollUpdateWasRequested, 'focus scrolling is requested');
      assert.strictEqual(last.verticalScrollDirection, 'forward');
    });

    test('a requested position past the end reports the clamped position next', async function (assert) {
      const scrolls: EuiDataGridScrollEvent[] = [];
      let api: EuiDataGridRefProps | undefined;
      const registerApi = (value: EuiDataGridRefProps) => (api = value);
      const options = { onScroll: (event: EuiDataGridScrollEvent) => scrolls.push(event) };
      await render(
        <template>
          <div style="width:500px">
            <EuiDataGrid
              @height={{300}}
              @columns={{COLUMNS}}
              @rowCount={{20}}
              @toolbarVisibility={{false}}
              @virtualizationOptions={{options}}
              @registerApi={{registerApi}}
            >
              <:cell as |c|>{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      await waitUntil(() => api);
      api!.scrollTo!({ scrollTop: 100000 });
      await settled();
      const outer = el('.euiDataGrid__virtualized');
      const max = outer.scrollHeight - outer.clientHeight;
      const tail = scrolls.slice(-2).map((event) => event.scrollUpdateWasRequested);
      assert.deepEqual(tail, [true, false], 'requested, then the clamped DOM position');
      assert.strictEqual(scrolls.at(-1)!.scrollTop, max);
      assert.true(scrolls.at(-1)!.isScrolledToBlockEnd);
      assert.strictEqual(scrolls.at(-1)!.verticalScrollDirection, 'backward');
    });

    test('initialScrollTop is reported once as the mount position', async function (assert) {
      const scrolls: EuiDataGridScrollEvent[] = [];
      const options = {
        initialScrollTop: 200,
        onScroll: (event: EuiDataGridScrollEvent) => scrolls.push(event)
      };
      await render(
        <template>
          <div style="width:500px">
            <EuiDataGrid
              @height={{300}}
              @columns={{COLUMNS}}
              @rowCount={{500}}
              @toolbarVisibility={{false}}
              @virtualizationOptions={{options}}
            >
              <:cell as |c|>{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      await triggerEvent(el('.euiDataGrid__virtualized'), 'scroll');
      assert.strictEqual(el('.euiDataGrid__virtualized').scrollTop, 200);
      assert.strictEqual(scrolls.length, 1);
      assert.deepEqual(pick(scrolls[0]!), {
        top: 200,
        left: 0,
        vertical: 'forward',
        horizontal: 'forward',
        requested: false
      });
    });
  });

  module('virtualizationOptions.estimatedRowHeight', function () {
    test('rows not laid out yet count with the estimate', async function (assert) {
      const options = { estimatedRowHeight: 100, overscanRowCount: 1 };
      let api: EuiDataGridRefProps | undefined;
      const registerApi = (value: EuiDataGridRefProps) => (api = value);
      await render(
        <template>
          <div style="width:500px">
            <EuiDataGrid
              @height={{300}}
              @columns={{COLUMNS}}
              @rowCount={{1000}}
              @toolbarVisibility={{false}}
              @virtualizationOptions={{options}}
              @registerApi={{registerApi}}
            >
              <:cell as |c|>{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      await waitUntil(() => api);
      const outer = el('.euiDataGrid__virtualized');
      const inner = outer.firstElementChild as HTMLElement;
      const rowHeight = el('.euiDataGridRow').offsetHeight;
      const header = el('.euiDataGridHeader').offsetHeight;
      const rendered = document.querySelectorAll('.euiDataGridRow').length;
      assert.strictEqual(
        inner.offsetHeight,
        header + rendered * rowHeight + (1000 - rendered) * 100,
        'laid out rows are exact, the others use the estimate'
      );

      api!.scrollToItem!({ rowIndex: 499, align: 'start' });
      await settled();
      const measured = Math.max(
        500,
        ...Array.from(document.querySelectorAll('.euiDataGridRow')).map(
          (row) => Number(row.getAttribute('data-grid-visible-row-index')) + 1
        )
      );
      assert.strictEqual(
        inner.offsetHeight,
        header + measured * rowHeight + (1000 - measured) * 100,
        'scrolling lays out the rows up to the target'
      );
      assert.ok(
        document.querySelector('.euiDataGridRow[data-grid-visible-row-index="499"]'),
        'the target row renders'
      );
      assert.strictEqual(
        outer.scrollTop,
        499 * rowHeight,
        'rows keep their exact positions'
      );

      api!.scrollToItem!({ rowIndex: 999 });
      await settled();
      assert.strictEqual(inner.offsetHeight, header + 1000 * rowHeight, 'every row laid out: exact');
    });

    test('without it the scrollable height is exact', async function (assert) {
      await render(
        <template>
          <div style="width:500px">
            <EuiDataGrid
              @height={{300}}
              @columns={{COLUMNS}}
              @rowCount={{1000}}
              @toolbarVisibility={{false}}
            >
              <:cell as |c|>{{c.rowIndex}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      const inner = el('.euiDataGrid__virtualized').firstElementChild as HTMLElement;
      const rowHeight = el('.euiDataGridRow').offsetHeight;
      const header = el('.euiDataGridHeader').offsetHeight;
      assert.strictEqual(inner.offsetHeight, header + 1000 * rowHeight);
    });
  });

  test('footerCellProps: className and style on control column footer cells', async function (assert) {
    const leading: EuiDataGridControlColumn[] = [
      {
        id: 'select',
        width: 40,
        footerCellProps: {
          className: 'customFooter',
          style: { backgroundColor: 'rgb(1, 2, 3)', width: 999, top: 7, paddingInlineStart: 3 }
        }
      }
    ];
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            @columns={{COLUMNS}}
            @rowCount={{2}}
            @toolbarVisibility={{false}}
            @leadingControlColumns={{leading}}
          >
            <:cell as |c|>{{c.columnId}}</:cell>
            <:footerCell as |c|>total {{c.columnId}}</:footerCell>
          </EuiDataGrid>
        </div>
      </template>
    );
    const footer = el('.euiDataGridFooter [data-gridcell-column-id=select]');
    assert.dom(footer).hasClass('customFooter');
    const style = getComputedStyle(footer);
    assert.strictEqual(style.backgroundColor, 'rgb(1, 2, 3)', 'style applies');
    assert.strictEqual(style.paddingInlineStart, '3px');
    assert.strictEqual(footer.style.width, '40px', "the column width wins over the style's");
    assert.strictEqual(footer.style.top, '0px', 'a `top` becomes 0, as upstream');
    const dataFooter = el('.euiDataGridFooter [data-gridcell-column-id=a]');
    assert.notOk(dataFooter.getAttribute('style')?.includes('rgb(1, 2, 3)'), 'data columns are unaffected');
    assert.dom(cell(0, 0)).doesNotHaveClass('customFooter', 'body cells are unaffected');
  });

  module('row tree state for renderers (Ember EUI extension)', function () {
    interface FileRow {
      id: string;
      name: string;
      children?: FileRow[];
    }
    const FILES: FileRow[] = [
      {
        id: 'src',
        name: 'src',
        children: [
          { id: 'app', name: 'app.ts' },
          { id: 'utils', name: 'utils', children: [{ id: 'keys', name: 'keys.ts' }] }
        ]
      },
      { id: 'readme', name: 'README.md' }
    ];
    const TREE_COLUMNS: EuiDataGridColumn[] = [
      { id: 'name', displayAsText: 'Name' },
      { id: 'kind', displayAsText: 'Kind' }
    ];

    const describe = (info: EuiDataGridRowTreeRowInfo | undefined) =>
      info
        ? `${info.id}|d${info.depth}|${info.hasChildren ? (info.isExpanded ? 'open' : 'closed') : 'leaf'}|${info.posInSet}/${info.setSize}|${info.parentId ?? '-'}|${info.isToggleCell ? 'toggle' : 'plain'}`
        : 'none';

    class NameCell extends Component<{ Args: EuiDataGridCellValueElementProps }> {
      get icon() {
        const info = this.args.rowTree;
        if (!info?.hasChildren) return 'file';
        return info.isExpanded ? 'folderOpen' : 'folderClosed';
      }

      get state() {
        return describe(this.args.rowTree);
      }

      <template>
        <span data-icon={{this.icon}} data-state={{this.state}}>{{@row.name}}</span>
        {{#if @rowTree.hasChildren}}
          <button type="button" data-toggle={{@rowTree.id}} {{on "click" @rowTree.toggle}}>toggle</button>
        {{/if}}
      </template>
    }

    test('component renderers get @rowTree (depth, expanded, siblings, toggle)', async function (assert) {
      const changes: string[][] = [];
      const tree = {
        rows: FILES,
        defaultExpandedRowIds: ['src'],
        onExpandedChange: (ids: string[]) => changes.push(ids)
      };
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              @columns={{TREE_COLUMNS}}
              @rowTree={{tree}}
              @toolbarVisibility={{false}}
              @renderCellValue={{NameCell}}
            />
          </div>
        </template>
      );
      const states = () =>
        Array.from(document.querySelectorAll<HTMLElement>('[data-gridcell-column-id=name] [data-state]')).map(
          (node) => node.dataset['state']
        );
      assert.deepEqual(states(), [
        'src|d0|open|1/2|-|toggle',
        'app|d1|leaf|1/2|src|toggle',
        'utils|d1|closed|2/2|src|toggle',
        'readme|d0|leaf|2/2|-|toggle'
      ]);
      assert.dom('[data-gridcell-column-id=kind] [data-state]').hasAttribute(
        'data-state',
        'src|d0|open|1/2|-|plain',
        'other columns: isToggleCell false'
      );
      assert.dom('[data-gridcell-column-id=name] [data-icon]').hasAttribute('data-icon', 'folderOpen');

      await click('[data-gridcell-column-id=name] [data-toggle=utils]');
      assert.deepEqual(changes.at(-1), ['src', 'utils'], 'toggle() calls onExpandedChange');
      assert.deepEqual(states(), [
        'src|d0|open|1/2|-|toggle',
        'app|d1|leaf|1/2|src|toggle',
        'utils|d1|open|2/2|src|toggle',
        'keys|d2|leaf|1/1|utils|toggle',
        'readme|d0|leaf|2/2|-|toggle'
      ], 'uncontrolled expansion updates the renderers');

      await click('[data-gridcell-column-id=name] [data-toggle=src]');
      assert.deepEqual(states(), ['src|d0|closed|1/2|-|toggle', 'readme|d0|leaf|2/2|-|toggle']);
    });

    test('the <:cell> block and popovers get rowTree; grouped rows count group levels', async function (assert) {
      const people = [
        { id: 1, name: 'Ana', country: 'France' },
        { id: 2, name: 'Bo', country: 'USA' }
      ];
      const columns: EuiDataGridColumn[] = [
        { id: 'name', displayAsText: 'Name' },
        { id: 'country', displayAsText: 'Country' }
      ];
      const grouping = { groupBy: ['country'], rows: people, defaultExpandedGroupIds: 'all' as const };
      const popovers: Array<EuiDataGridRowTreeRowInfo | undefined> = [];
      class Popover extends Component<{ Args: EuiDataGridCellPopoverElementProps }> {
        get state() {
          popovers.push(this.args.rowTree);
          return describeInfo(this.args.rowTree);
        }

        <template><p data-popover-state>{{this.state}}</p></template>
      }
      const describeInfo = describe;
      let api: EuiDataGridRefProps | undefined;
      const registerApi = (value: EuiDataGridRefProps) => (api = value);
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              @columns={{columns}}
              @grouping={{grouping}}
              @toolbarVisibility={{false}}
              @renderCellPopover={{Popover}}
              @registerApi={{registerApi}}
            >
              <:cell as |c|><span data-cell-state>{{describeInfo c.rowTree}}</span></:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      const states = Array.from(
        document.querySelectorAll<HTMLElement>('[data-gridcell-column-id=name] [data-cell-state]')
      ).map((node) => node.textContent);
      assert.strictEqual(states.length, 2, 'group rows render no value');
      assert.strictEqual(states[0], '0|d1|leaf|1/1|group:["France"]|toggle');
      assert.strictEqual(states[1], '1|d1|leaf|1/1|group:["USA"]|toggle');

      await waitUntil(() => api);
      api!.openCellPopover({ rowIndex: 0, colIndex: 1 });
      await waitUntil(() => document.querySelector('[data-popover-state]'));
      assert.dom('[data-popover-state]', document.body).hasText('0|d1|leaf|1/1|group:["France"]|plain');
      assert.strictEqual(popovers.at(-1)?.id, '0');
    });

    test('without @rowTree / @grouping renderers get no rowTree', async function (assert) {
      class Probe extends Component<{ Args: EuiDataGridCellValueElementProps }> {
        get has() {
          return 'rowTree' in this.args && this.args.rowTree !== undefined ? 'yes' : 'no';
        }

        <template><span data-probe>{{this.has}}</span></template>
      }
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              @columns={{COLUMNS}}
              @rowCount={{1}}
              @toolbarVisibility={{false}}
              @renderCellValue={{Probe}}
            />
            <EuiDataGrid @columns={{COLUMNS}} @rowCount={{1}} @toolbarVisibility={{false}}>
              <:cell as |c|><span data-block-probe>{{if c.rowTree "yes" "no"}}</span></:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      assert.dom('[data-probe]').hasText('no');
      assert.dom('[data-block-probe]').hasText('no');
    });
  });
});
