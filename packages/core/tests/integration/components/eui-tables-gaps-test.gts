import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import { hash } from '@ember/helper';
import { htmlSafe } from '@ember/template';
import { click, find, findAll, render, settled, triggerEvent } from '@ember/test-helpers';

import EuiBasicTable, { useEuiBasicTablePanelProps } from '#src/components/eui-basic-table.gts';
import EuiBasicTablePanel from '#src/components/eui-basic-table-panel.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFlexGroup from '#src/components/eui-flex-group.gts';
import EuiInMemoryTable from '#src/components/eui-in-memory-table.gts';
import EuiTable from '#src/components/eui-table.gts';
import EuiTableBody from '#src/components/eui-table-body.gts';
import EuiTableFooter from '#src/components/eui-table-footer.gts';
import EuiTableFooterCell from '#src/components/eui-table-footer-cell.gts';
import EuiTableHeader from '#src/components/eui-table-header.gts';
import EuiTableHeaderCell from '#src/components/eui-table-header-cell.gts';
import EuiTableRow from '#src/components/eui-table-row.gts';
import EuiTableRowCell from '#src/components/eui-table-row-cell.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type {
  Criteria,
  EuiBasicTableColumn,
  EuiTableSortingType
} from '#src/components/eui-basic-table.gts';

interface User {
  id: number;
  name: string;
  age: number;
  city: string;
  bio: string;
}

const LONG = 'Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua ut enim ad minim veniam quis nostrud exercitation';

const users: User[] = [
  { id: 1, name: 'Ann', age: 34, city: 'Paris', bio: LONG },
  { id: 2, name: 'Bob', age: 51, city: 'Berlin', bio: LONG },
  { id: 3, name: 'Cid', age: 7, city: 'Rome', bio: LONG }
];

const light = resolveBorealisTheme('light').euiTheme;

function rgb(color: string): string {
  const probe = document.createElement('div');
  probe.style.color = color;
  document.body.appendChild(probe);
  const resolved = getComputedStyle(probe).color;
  probe.remove();
  return resolved;
}

function texts(selector: string, root?: Element): string[] {
  return (root ? [...root.querySelectorAll(selector)] : findAll(selector)).map(
    (element) => element.textContent?.replace(/\s+/g, ' ').trim() ?? ''
  );
}

/** Lets ResizeObserver/IntersectionObserver callbacks and rAF run. */
async function frames(count = 3): Promise<void> {
  for (let i = 0; i < count; i++) {
    await new Promise((resolve) => requestAnimationFrame(resolve));
  }
  await settled();
}

const style = (selector: string | Element) =>
  getComputedStyle(typeof selector === 'string' ? find(selector)! : selector);

const RichName: TemplateOnlyComponent = <template><b data-rich-name>Rich</b> name</template>;

module('Integration | Component | Borealis tables gaps', function (hooks) {
  setupRenderingTest(hooks);

  test('basic table: column valign, multi-line truncation and reactive changes', async function (assert) {
    class State {
      @tracked valign: 'top' | 'middle' | 'bottom' = 'top';
      @tracked lines = 2;
      get columns(): Array<EuiBasicTableColumn<User>> {
        return [
          { field: 'name', name: 'Name', valign: this.valign },
          { field: 'bio', name: 'Bio', truncateText: { lines: this.lines }, valign: this.valign },
          { name: 'Computed', render: (user: User) => user.city, valign: 'bottom', truncateText: true }
        ];
      }
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width: 600px">
            <EuiBasicTable @items={{users}} @columns={{state.columns}} @responsiveBreakpoint={{false}} />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const cell = (n: number) => find(`tbody tr:first-child > :nth-child(${n})`)!;
    assert.strictEqual(style(cell(1)).verticalAlign, 'top', 'valign top');
    assert.strictEqual(style(cell(3)).verticalAlign, 'bottom', 'computed column valign');
    assert.strictEqual(style('thead th').verticalAlign, 'middle', 'header keeps middle (valign is for body cells)');
    assert.dom(cell(1)).doesNotHaveAttribute('valign', 'valign is a style, not an attribute');

    // { lines: 2 }: the text span is clamped (upstream EuiTextBlockTruncate cloneElement)
    const clamped = cell(2).querySelector('.euiTableCellContent__text') as HTMLElement;
    assert.dom(clamped).hasClass('euiTextBlockTruncate');
    assert.strictEqual(clamped.style.getPropertyValue('-webkit-line-clamp'), '2');
    assert.strictEqual(getComputedStyle(clamped).overflow, 'hidden');
    assert.true(['-webkit-box', 'flow-root'].includes(getComputedStyle(clamped).display), 'line clamp box');
    const lineHeight = parseFloat(getComputedStyle(clamped).lineHeight);
    assert.ok(clamped.getBoundingClientRect().height <= lineHeight * 2 + 1, 'at most 2 lines tall');
    assert.ok(clamped.scrollHeight > clamped.clientHeight, 'long text overflows the clamp');
    const content = cell(2).querySelector('.euiTableCellContent')!;
    assert.strictEqual(getComputedStyle(content).whiteSpace, 'normal', 'a clamp neither truncates on one line…');
    assert.notStrictEqual(getComputedStyle(content).wordBreak, 'break-all', '…nor applies the word break styles');
    assert.strictEqual(style(cell(3).querySelector('.euiTableCellContent')!).whiteSpace, 'nowrap', 'truncateText: true');

    state.valign = 'bottom';
    state.lines = 3;
    await settled();
    assert.strictEqual(cell(2).querySelector('.euiTableCellContent__text'), clamped, 'same element after changes');
    assert.strictEqual(style(cell(1)).verticalAlign, 'bottom');
    assert.strictEqual(clamped.style.getPropertyValue('-webkit-line-clamp'), '3');
  });

  test('basic table: cellProps cell arguments are consumed, not rendered as attributes', async function (assert) {
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name', className: 'col-class', 'data-test-subj': 'col-subj' },
      { field: 'bio', name: 'Bio', truncateText: { lines: 1 } },
      { field: 'age', name: 'Age', dataType: 'number' }
    ];
    const clicks: string[] = [];
    const cellProps = (user: User, column: EuiBasicTableColumn<User>) => ({
      textOnly: false,
      // the column's own `truncateText` wins over cellProps (upstream order)
      truncateText: 'field' in column && column.field !== 'name' ? true : undefined,
      valign: 'top',
      align: 'center',
      className: 'from-cell-props',
      'data-cell': `${user.id}-${'field' in column ? String(column.field) : ''}`,
      onClick: () => clicks.push(user.name)
    });
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiBasicTable @items={{users}} @columns={{columns}} @cellProps={{cellProps}} @responsiveBreakpoint={{false}} />
        </EuiEmotionProvider>
      </template>
    );
    const first = find('tbody tr:first-child > :first-child')!;
    for (const attribute of ['textonly', 'textOnly', 'truncatetext', 'valign', 'align']) {
      assert.dom(first).doesNotHaveAttribute(attribute, `${attribute} is not leaked to the DOM`);
    }
    assert.dom(first).hasAttribute('data-cell', '1-name', 'other props stay attributes');
    assert.dom(first).hasClass('from-cell-props').hasClass('col-class');
    assert.dom(first).hasAttribute('data-test-subj', 'col-subj', 'the column wins (upstream spreads it after cellProps)');
    assert.dom(first.querySelector('.euiTableCellContent__text')).doesNotExist('textOnly: false renders without the text span');
    assert.strictEqual(style(first).verticalAlign, 'top', 'valign from cellProps');
    assert.strictEqual(style(first.querySelector('.euiTableCellContent')!).justifyContent, 'center', 'align from cellProps');
    assert.strictEqual(style('tbody tr:first-child > :nth-child(3) .euiTableCellContent').whiteSpace, 'nowrap', 'truncateText from cellProps');
    assert.dom('tbody tr:first-child > :nth-child(2) .euiTextBlockTruncate').exists('the column truncateText wins');
    await click(first);
    assert.deepEqual(clicks, ['Ann'], 'listeners still work');
  });

  test('basic table: rich column names in headers, cards and the mobile sort menu', async function (assert) {
    class State {
      @tracked responsive = false;
    }
    const state = new State();
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: RichName, sortable: true },
      { field: 'city', name: htmlSafe('<i data-safe>City</i>'), sortable: true },
      {
        field: 'age',
        name: 'Age',
        mobileOptions: { header: RichName },
        nameTooltip: { content: 'Years', iconProps: { className: 'age-tip' }, tooltipProps: { position: 'bottom' } }
      }
    ];
    const sorting = { sort: { field: 'city' as const, direction: 'asc' as const } };
    const changes: Array<Criteria<User>> = [];
    const onChange = (criteria: Criteria<User>) => changes.push(criteria);
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiBasicTable @items={{users}} @columns={{columns}} @sorting={{sorting}} @onChange={{onChange}} @responsiveBreakpoint={{state.responsive}} />
        </EuiEmotionProvider>
      </template>
    );
    assert.dom('thead th:first-child [data-rich-name]').hasText('Rich');
    assert.dom('thead th:first-child .eui-textTruncate').hasText('Rich name').hasAttribute('title', 'Rich name');
    assert.dom('thead th:first-child').hasAttribute('data-test-subj', 'tableHeaderCell_name_0');
    assert.dom('thead th:nth-child(2) [data-safe]').hasText('City');
    assert.dom('thead th:nth-child(2)').hasAttribute('aria-sort', 'ascending', 'a name sorted by field');
    await click('thead th:first-child button');
    assert.deepEqual(changes.at(-1)?.sort, { field: 'name', direction: 'asc' });
    assert.dom('thead th:nth-child(3) .age-tip').exists('nameTooltip.iconProps (upstream)');
    await triggerEvent('thead th:nth-child(3) .age-tip', 'mouseover');
    assert.dom('.euiToolTip', document.body).hasText('Years');
    assert.dom('.euiToolTip', document.body).hasAttribute('data-position', 'bottom', 'nameTooltip.tooltipProps.position');
    await triggerEvent('thead th:nth-child(3) .age-tip', 'mouseout');

    state.responsive = true;
    await settled();
    assert.dom('tbody tr:first-child td:first-child .euiTableRowCell__mobileHeader [data-rich-name]').exists('cards header from the name');
    assert.dom('tbody tr:first-child td:nth-child(2) .euiTableRowCell__mobileHeader [data-safe]').exists();
    assert.dom('tbody tr:first-child td:nth-child(3) .euiTableRowCell__mobileHeader [data-rich-name]').exists('mobileOptions.header component');
    await click('.euiTableSortMobile button');
    assert.dom('.euiTableSortMobileItem [data-rich-name]', document.body).exists('mobile sort item');
    assert.dom('.euiTableSortMobileItem:not([aria-label])', document.body).exists('no label from a component name');
  });

  test('basic table: sticky actions column with inline scrolling (header, cells, footer)', async function (assert) {
    class State {
      @tracked scrollableInline = true;
      @tracked responsive = false;
    }
    const state = new State();
    const clicked: string[] = [];
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name', minWidth: '300px', footer: 'Total' },
      { field: 'city', name: 'City', minWidth: '300px' },
      { field: 'bio', name: 'Bio', minWidth: '400px' },
      {
        name: 'Actions',
        sticky: true,
        actions: [
          { name: 'Edit', description: 'Edit', isPrimary: true, onClick: (user: User) => clicked.push(`edit ${user.name}`) },
          { name: 'Share', description: 'Share', onClick: (user: User) => clicked.push(`share ${user.name}`), 'data-test-subj': 'share' },
          { name: 'Delete', description: 'Delete', onClick: () => {} }
        ]
      }
    ];
    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width: 500px">
            <EuiBasicTable
              @items={{users}}
              @columns={{columns}}
              @tableLayout="auto"
              @scrollableInline={{state.scrollableInline}}
              @responsiveBreakpoint={{state.responsive}}
            />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const headerCell = find('thead th:last-child')!;
    const bodyCell = find('tbody tr:first-child td:last-child')!;
    const footerCell = find('tfoot td:last-child')!;
    for (const [label, element] of [['header', headerCell], ['cell', bodyCell], ['footer', footerCell]] as const) {
      assert.dom(element).hasAttribute('data-sticky', 'end', `${label} data-sticky`);
      assert.strictEqual(style(element).position, 'sticky', `${label} sticks`);
      assert.strictEqual(style(element).insetInlineEnd, '0px', `${label} at the end`);
    }
    assert.dom('thead th:first-child').doesNotHaveAttribute('data-sticky');
    assert.strictEqual(style(bodyCell).backgroundColor, rgb(light.colors.backgroundBasePlain), 'opaque background');

    const wrapper = find('.euiTable__wrapper') as HTMLElement;
    assert.ok(wrapper.scrollWidth > wrapper.clientWidth, 'the table overflows');
    // upstream scrolls with `overflow-inline`, which Chromium 130 does not support yet
    wrapper.style.overflowX = 'auto';
    wrapper.scrollLeft = 200;
    assert.strictEqual(wrapper.scrollLeft, 200);
    await frames(1);
    const right = (element: Element) => Math.round(element.getBoundingClientRect().right);
    assert.strictEqual(right(bodyCell), right(wrapper), 'the actions stay at the end while scrolling');

    // actions still work, including the collapsed menu
    await click('tbody tr:first-child [data-test-subj="euiCollapsedItemActionsButton"]');
    await click(document.querySelector('[data-test-subj="share"]')!);
    assert.deepEqual(clicked, ['share Ann']);

    state.scrollableInline = false;
    await settled();
    assert.dom('tbody tr:first-child td:last-child').doesNotHaveAttribute('data-sticky', 'only with inline scrolling (upstream)');
    assert.notStrictEqual(style('tbody tr:first-child td:last-child').position, 'sticky');

    state.scrollableInline = true;
    state.responsive = true;
    await settled();
    assert.dom('tbody tr:first-child td:last-child').doesNotHaveAttribute('data-sticky', 'not in the cards layout');
    assert.notStrictEqual(style('tbody tr:first-child td:last-child').position, 'sticky');
  });

  test('EuiTable stickyHeader: a hidden copy of the header with synced widths, order and inline scroll', async function (assert) {
    class State {
      @tracked showMiddle = false;
      @tracked responsive = false;
      @tracked sticky = true;
    }
    const state = new State();
    const sorted: string[] = [];
    const sortName = () => sorted.push('name');
    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width: 400px">
            <EuiTable
              @stickyHeader={{state.sticky}}
              @scrollableInline={{true}}
              @tableLayout="auto"
              @responsiveBreakpoint={{state.responsive}}
              data-test-subj="custom"
            >
              <EuiTableHeader>
                <EuiTableHeaderCell @minWidth="200px" @onSort={{sortName}} data-test-subj="nameHeader">Name</EuiTableHeaderCell>
                {{#if state.showMiddle}}
                  <EuiTableHeaderCell @width="150px">Middle</EuiTableHeaderCell>
                {{/if}}
                <EuiTableHeaderCell @minWidth="300px" @align="right" @sticky={{hash side="end"}}>Age</EuiTableHeaderCell>
              </EuiTableHeader>
              <EuiTableBody>
                {{#each users as |user|}}
                  <EuiTableRow>
                    <EuiTableRowCell>{{user.name}}</EuiTableRowCell>
                    {{#if state.showMiddle}}<EuiTableRowCell>m</EuiTableRowCell>{{/if}}
                    <EuiTableRowCell @align="right" @sticky={{hash side="end"}}>{{user.age}}</EuiTableRowCell>
                  </EuiTableRow>
                {{/each}}
              </EuiTableBody>
              <EuiTableFooter>
                <EuiTableFooterCell>Total</EuiTableFooterCell>
                {{#if state.showMiddle}}<EuiTableFooterCell />{{/if}}
                <EuiTableFooterCell @sticky={{hash side="end"}}>92</EuiTableFooterCell>
              </EuiTableFooter>
            </EuiTable>
          </div>
        </EuiEmotionProvider>
      </template>
    );
    await frames();
    const sticky = find('.euiTableStickyHeader')!;
    assert.dom(sticky).hasTagName('table');
    const outer = sticky.parentElement!.parentElement!;
    assert.dom(outer).hasAttribute('aria-hidden', 'true', 'hidden from assistive technologies');
    assert.ok(outer.nextElementSibling?.classList.contains('euiTable__wrapper'), 'rendered before the table wrapper');
    assert.strictEqual(getComputedStyle(outer).position, 'sticky');
    assert.strictEqual(getComputedStyle(outer).top, '0px');
    assert.strictEqual(getComputedStyle(outer).height, '0px', 'out of the document flow');
    assert.dom('table.euiTable').hasAttribute('data-test-subj', 'custom', 'attributes stay on the table');
    assert.dom(sticky.parentElement).hasClass('euiTableStickyHeader__container');

    const copies = () => [...sticky.querySelectorAll('thead > tr > *')] as HTMLElement[];
    const originals = () => findAll('table.euiTable thead > tr > *') as HTMLElement[];
    assert.deepEqual(copies().map((c) => c.textContent!.trim()), ['Name', 'Age']);
    assert.dom(copies()[1]).hasAttribute('data-sticky', 'end');
    const widths = (cells: HTMLElement[]) => cells.map((c) => Math.round(c.getBoundingClientRect().width));
    assert.deepEqual(widths(copies()), widths(originals()), 'widths follow the table');
    assert.strictEqual(getComputedStyle(copies()[0]!).fontWeight, getComputedStyle(originals()[0]!).fontWeight, 'header cell styles');

    // the copy's sort button works (it covers the original)
    await click(sticky.querySelector('button')!);
    assert.deepEqual(sorted, ['name']);

    // inline scroll sync (upstream's `overflow-inline` is not in Chromium 130 yet)
    const wrapper = find('.euiTable__wrapper') as HTMLElement;
    wrapper.style.overflowX = 'auto';
    (sticky.parentElement as HTMLElement).style.overflowX = 'hidden';
    wrapper.scrollLeft = 60;
    assert.strictEqual(wrapper.scrollLeft, 60, "the table scrolls");
    await triggerEvent(wrapper, 'scroll');
    assert.strictEqual(sticky.parentElement!.scrollLeft, wrapper.scrollLeft, 'the copy scrolls with the table');
    assert.strictEqual(Math.round(parseFloat((sticky as HTMLElement).style.minWidth)), Math.round(find('table.euiTable')!.clientWidth));

    // a cell added in the middle keeps the copies in order
    state.showMiddle = true;
    await frames();
    assert.deepEqual(copies().map((c) => c.textContent!.trim()), ['Name', 'Middle', 'Age']);
    assert.deepEqual(widths(copies()), widths(originals()));

    // cards: no sticky header (upstream), and no copies
    state.responsive = true;
    await settled();
    assert.dom('.euiTableStickyHeader').doesNotExist();
    state.responsive = false;
    await frames();
    assert.deepEqual(texts('.euiTableStickyHeader thead th'), ['Name', 'Middle', 'Age'], 'back after the cards layout');

    state.sticky = false;
    await settled();
    assert.dom('.euiTableStickyHeader').doesNotExist();
    assert.dom('table.euiTable thead th').exists({ count: 3 });
  });

  test('EuiTable stickyScrollbar: shown while the table overflows inline, drags the table', async function (assert) {
    class State {
      @tracked width = 300;
      get style() {
        return htmlSafe(`width: ${this.width}px`);
      }
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider>
          <div style={{state.style}} class="host">
            <EuiTable @scrollableInline={{true}} @stickyScrollbar={{true}} @tableLayout="auto">
              <EuiTableBody>
                <EuiTableRow>
                  <EuiTableRowCell @minWidth="400px">A</EuiTableRowCell>
                  <EuiTableRowCell @minWidth="400px">B</EuiTableRowCell>
                </EuiTableRow>
              </EuiTableBody>
            </EuiTable>
          </div>
          <div class="plain">
            <EuiTable @stickyScrollbar={{true}}>
              <EuiTableBody><EuiTableRow><EuiTableRowCell>A</EuiTableRowCell></EuiTableRow></EuiTableBody>
            </EuiTable>
          </div>
        </EuiEmotionProvider>
      </template>
    );
    await frames();
    assert.dom('.plain [data-test-subj="euiTableStickyScrollbar"]').doesNotExist('requires @scrollableInline');
    const bar = find('.host [data-test-subj="euiTableStickyScrollbar"]')!;
    assert.dom(bar).hasAttribute('aria-hidden', 'true');
    assert.ok(bar.previousElementSibling?.classList.contains('euiTable__wrapper'), 'after the wrapper');
    assert.strictEqual(getComputedStyle(bar).position, 'sticky');
    assert.strictEqual(getComputedStyle(bar).bottom, '0px');
    const wrapper = find('.host .euiTable__wrapper') as HTMLElement;
    wrapper.style.overflowX = 'auto'; // upstream's `overflow-inline` (not in Chromium 130)
    const track = find('[data-test-subj="euiTableStickyScrollbarTrack"]') as HTMLElement;
    const expected = (wrapper.clientWidth / wrapper.scrollWidth) * 100;
    assert.ok(Math.abs(parseFloat(track.style.inlineSize) - expected) < 0.5, 'track size from the overflow ratio');

    // dragging the track scrolls the table
    const start = track.getBoundingClientRect();
    await triggerEvent(track, 'pointerdown', { clientX: start.left + 2, pointerId: 1 });
    await triggerEvent(track, 'pointermove', { clientX: start.left + 22, pointerId: 1 });
    await triggerEvent(track, 'pointerup', { pointerId: 1 });
    assert.ok(wrapper.scrollLeft > 0, 'the table scrolled');
    await triggerEvent(wrapper, 'scroll');
    await frames(2);
    assert.ok(parseFloat(track.style.marginInlineStart) > 0, 'the track follows the scroll');

    state.width = 1200;
    await frames();
    assert.dom('.host [data-test-subj="euiTableStickyScrollbar"]').doesNotExist('nothing to scroll');
  });

  test('basic and in-memory tables: sticky header with sorting, selection, pagination, expanded rows and actions', async function (assert) {
    class State {
      @tracked sorting: EuiTableSortingType<User> = { sort: { field: 'name', direction: 'asc' } };
      @tracked responsive = false;
      selected: User[] = [];
    }
    const state = new State();
    const changes: Array<Criteria<User>> = [];
    const onChange = (criteria: Criteria<User>) => {
      changes.push(criteria);
      if (criteria.sort) state.sorting = { sort: criteria.sort };
    };
    const selection = { onSelectionChange: (items: User[]) => (state.selected = items) };
    const pagination = { pageIndex: 0, pageSize: 2, totalItemCount: 3 };
    const expanded = { 2: 'Bob details' };
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name', sortable: true, valign: 'top' },
      { field: 'bio', name: 'Bio', truncateText: { lines: 2 } },
      {
        name: 'Actions',
        sticky: true,
        actions: [
          { name: 'One', description: 'One', onClick: () => {} },
          { name: 'Two', description: 'Two', onClick: () => {} },
          { name: 'Three', description: 'Three', onClick: () => {}, 'data-test-subj': 'three' }
        ]
      }
    ];
    await render(
      <template>
        <EuiEmotionProvider>
          <div class="basic">
            <EuiBasicTable
              @items={{users}}
              @itemId="id"
              @columns={{columns}}
              @sorting={{state.sorting}}
              @selection={{selection}}
              @pagination={{pagination}}
              @itemIdToExpandedRowMap={{expanded}}
              @onChange={{onChange}}
              @stickyHeader={{true}}
              @scrollableInline={{true}}
              @stickyScrollbar={{true}}
              @responsiveBreakpoint={{state.responsive}}
            />
          </div>
          <div class="memory">
            <EuiInMemoryTable @items={{users}} @columns={{columns}} @sorting={{true}} @stickyHeader={{true}} @responsiveBreakpoint={{false}} />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    await frames();
    const copy = '.basic .euiTableStickyHeader';
    assert.deepEqual(texts(`${copy} thead > tr > *`).slice(1), ['Name', 'Bio', 'Actions']);
    assert.dom(`${copy} [data-test-subj="checkboxSelectAll"]`).exists('the select all checkbox is copied');
    assert.dom(`${copy} thead th:nth-child(2)`).hasAttribute('aria-sort', 'ascending');
    assert.dom(`${copy} thead th:last-child`).hasAttribute('data-sticky', 'end');

    // sorting from the copy
    await click(`${copy} thead th:nth-child(2) button`);
    assert.deepEqual(changes.at(-1), { page: { index: 0, size: 2 }, sort: { field: 'name', direction: 'desc' } });
    assert.dom(`${copy} thead th:nth-child(2)`).hasAttribute('aria-sort', 'descending', 'the copy follows the sort');
    assert.dom('.basic table.euiTable thead th:nth-child(2)').hasAttribute('aria-sort', 'descending');

    // selection from the copy and from rows
    await click(`${copy} [data-test-subj="checkboxSelectAll"]`);
    assert.deepEqual(state.selected.map((user) => user.id), [1, 2, 3]);
    assert.dom('.basic [data-test-subj="checkboxSelectRow-1"]').isChecked();
    await click('.basic [data-test-subj="checkboxSelectRow-1"]');
    assert.deepEqual(state.selected.map((user) => user.id), [2, 3]);

    // pagination (clears the selection, upstream), expanded rows and collapsed actions keep working
    await click('.basic [data-test-subj="pagination-button-1"]');
    assert.deepEqual(changes.at(-1)?.page, { index: 1, size: 2 });
    assert.deepEqual(state.selected, []);
    assert.dom('.basic #row_2_expansion').hasText('Bob details');
    assert.dom('.basic tbody tr:first-child td:last-child').hasAttribute('data-sticky', 'end');
    await click('.basic tbody tr:first-child [data-test-subj="euiCollapsedItemActionsButton"]');
    assert.dom('[data-test-subj="three"]', document.body).exists('collapsed actions menu');

    // in-memory table forwards the sticky header and sorts from the copy
    assert.dom('.memory .euiTableStickyHeader').exists();
    await click('.memory .euiTableStickyHeader thead th:first-child button');
    assert.deepEqual(texts('.memory tbody tr > :first-child'), ['Ann', 'Bob', 'Cid']);
    await click('.memory .euiTableStickyHeader thead th:first-child button');
    assert.deepEqual(texts('.memory tbody tr > :first-child'), ['Cid', 'Bob', 'Ann']);

    // cards: no sticky header or sticky cells, mobile header and sort still work
    state.responsive = true;
    await settled();
    assert.dom('.basic .euiTableStickyHeader').doesNotExist();
    assert.dom('.basic [data-sticky]').doesNotExist();
    assert.dom('.basic .euiTableHeaderMobile [data-test-subj="checkboxSelectAll"]').exists();
    assert.dom('.basic .euiTableSortMobile').exists();
    assert.dom('.basic tbody .euiTextBlockTruncate').exists('the clamp also applies to cards');
  });

  test('in-memory table custom panels: EuiBasicTablePanel, useEuiBasicTablePanelProps and the childrenBetween block', async function (assert) {
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name', sortable: true },
      { field: 'city', name: 'City' }
    ];
    const search = { box: { incremental: true } };
    const panel = useEuiBasicTablePanelProps();
    const padding = { padding: '12px' };
    await render(
      <template>
        <EuiEmotionProvider>
          <div class="memory">
            <EuiInMemoryTable @items={{users}} @columns={{columns}} @search={{search}} @panelled={{true}} @pagination={{true}}>
              <:childrenBetween as |Panel props|>
                <EuiFlexGroup class={{props.className}} @css={{props.css}} data-test-subj="zero">Zero</EuiFlexGroup>
                <Panel @css={{padding}} data-test-subj="first">First</Panel>
                <Panel data-test-subj="second">Second</Panel>
                <Panel data-test-subj="third">Third</Panel>
              </:childrenBetween>
            </EuiInMemoryTable>
          </div>
          <div class="plain">
            <EuiBasicTablePanel data-test-subj="plain">Plain</EuiBasicTablePanel>
            <EuiBasicTable @items={{users}} @columns={{columns}} @panelled={{true}} />
          </div>
          <EuiFlexGroup class={{panel.className}} @css={{panel.css}} data-test-subj="hook">Hook</EuiFlexGroup>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(panel.className, 'euiBasicTablePanel');
    for (const subj of ['zero', 'first', 'second', 'plain', 'hook']) {
      const element = find(`[data-test-subj="${subj}"]`)!;
      assert.dom(element).hasClass('euiBasicTablePanel');
      assert.strictEqual(getComputedStyle(element).backgroundColor, rgb(light.colors.backgroundBaseSubdued), `${subj} background`);
      assert.strictEqual(getComputedStyle(element).borderBottomWidth, '0px', `${subj} open bottom`);
    }
    assert.strictEqual(style('[data-test-subj="first"]').paddingTop, '12px', '@css composed last');
    assert.notStrictEqual(style('[data-test-subj="second"]').borderTopLeftRadius, '0px', 'a panel is rounded');
    assert.strictEqual(style('[data-test-subj="third"]').borderTopLeftRadius, '0px', 'consecutive (same style) panels join');
    const wrapper = (scope: string) => style(`.${scope} [data-test-subj="euiBasicTablePanelledWrapper"]`);
    assert.strictEqual(wrapper('memory').borderTopLeftRadius, '0px', 'the table joins the panel above');
    assert.strictEqual(wrapper('plain').borderTopLeftRadius, '0px');
    assert.dom('.memory [data-test-subj="first"]').hasText('First');
  });
});
