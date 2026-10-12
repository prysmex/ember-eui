import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import { htmlSafe } from '@ember/template';
import { click, findAll, render, settled, triggerEvent } from '@ember/test-helpers';

import EuiBasicTable from '#src/components/eui-basic-table.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type {
  Criteria,
  EuiBasicTableColumn,
  EuiTableCellComponentArgs,
  EuiTableSelectionType,
  EuiTableSortingType,
  Pagination
} from '#src/components/eui-basic-table.gts';

interface User {
  id: number;
  name: string;
  age: number | null;
  online: boolean;
  joined: Date;
  address: { city: string };
}

const users: User[] = [
  { id: 1, name: 'Ann', age: 34, online: true, joined: new Date(2020, 0, 2, 3, 4), address: { city: 'Paris' } },
  { id: 2, name: 'Bob', age: null, online: false, joined: new Date(2021, 5, 6, 7, 8), address: { city: 'Berlin' } },
  { id: 3, name: 'Cid', age: 7, online: true, joined: new Date(2022, 10, 12, 13, 14), address: { city: 'Rome' } }
];

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function rgb(color: string): string {
  const probe = document.createElement('div');
  probe.style.color = color;
  document.body.appendChild(probe);
  const resolved = getComputedStyle(probe).color;
  probe.remove();
  return resolved;
}

function texts(selector: string, root?: Element): string[] {
  return (root ? [...root.querySelectorAll(selector)] : findAll(selector)).map((element) => element.textContent?.replace(/\s+/g, ' ').trim() ?? '');
}

const CityBadge: TemplateOnlyComponent<{ Args: EuiTableCellComponentArgs<User> }> = <template>
  <b data-city>{{@item.address.city}}</b>
</template>;

module('Integration | Component | Borealis basic table', function (hooks) {
  setupRenderingTest(hooks);

  test('renders field, computed and component columns with upstream data types', async function (assert) {
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name', 'data-test-subj': 'nameCell', width: '30%' },
      { field: 'age', name: 'Age', dataType: 'number', description: 'Age in years' },
      { field: 'online', name: 'Online', dataType: 'boolean' },
      { field: 'joined', name: 'Joined', dataType: 'date' },
      { field: 'address.city', name: 'City', render: (city: string) => htmlSafe(`<i>${city}</i>`) },
      { name: 'Badge', component: CityBadge },
      { name: 'Initial', render: (user: User) => user.name[0], align: 'center' }
    ];
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiBasicTable @items={{users}} @columns={{columns}} @rowHeader="name" class="caller" data-test-subj="users" />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('div.euiBasicTable.caller').hasAttribute('data-test-subj', 'users');
    assert.dom('table.euiTable').hasAttribute('id');
    assert.deepEqual(texts('thead th .eui-textTruncate'), ['Name', 'Age', 'Online', 'Joined', 'City', 'Badge', 'Initial']);
    assert.dom('thead th:nth-child(2)').hasAttribute('data-test-subj', 'tableHeaderCell_age_1');
    assert.dom('thead th:nth-child(6)').hasAttribute('data-test-subj', 'tableHeaderCell_Badge_5');
    assert.dom('thead th:nth-child(1)').hasAttribute('style', /width: 30%/);
    assert.deepEqual(texts('tbody tr:first-child > *'), [
      'Ann',
      '34',
      'Yes',
      '2 Jan 2020 03:04',
      'Paris',
      'Paris',
      'A'
    ]);
    assert.deepEqual(texts('tbody tr:nth-child(2) > *').slice(1, 3), ['', 'No'], 'null number renders empty');
    assert.dom('tbody tr:first-child th').hasAttribute('scope', 'row', '@rowHeader makes a row header');
    assert.dom('tbody tr:first-child td i').hasText('Paris', 'render may return safe HTML');
    assert.dom('tbody tr:first-child [data-city]').exists('component cell');
    assert.dom('tbody tr:first-child th').hasAttribute('data-test-subj', 'nameCell');
    // numbers are right aligned (upstream data type profile), explicit align wins
    const content = (n: number) =>
      getComputedStyle(document.querySelector(`tbody tr:first-child > :nth-child(${n}) .euiTableCellContent`)!);
    assert.strictEqual(content(2).justifyContent, 'flex-end');
    assert.strictEqual(content(1).justifyContent, 'normal', 'left (the default)');
    assert.strictEqual(content(7).justifyContent, 'center');

    const caption = document.querySelector('caption.euiTableCaption') as HTMLElement;
    assert.dom(caption).hasClass('euiScreenReaderOnly').hasText('Data table,');
    assert.strictEqual(getComputedStyle(caption).position, 'relative', 'caption styles win over the sr-only position');
    assert.strictEqual(getComputedStyle(caption).clipPath, 'inset(50%)');
  });

  test('sorting: header buttons, criteria, reversing, computed and read-only columns', async function (assert) {
    const changes: Array<Criteria<User>> = [];
    class State {
      @tracked sorting: EuiTableSortingType<User> = { sort: { field: 'name', direction: 'asc' } };
    }
    const state = new State();
    const onChange = (criteria: Criteria<User>) => {
      changes.push(criteria);
      if (criteria.sort) state.sorting = { sort: criteria.sort };
    };
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name', sortable: true },
      { field: 'age', name: 'Age', sortable: true, readOnly: true },
      { field: 'online', name: 'Online' },
      { name: 'Length', render: (user: User) => user.name.length, sortable: (user: User) => user.name.length }
    ];
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiBasicTable @items={{users}} @columns={{columns}} @sorting={{state.sorting}} @onChange={{onChange}} />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('thead th:nth-child(1)').hasAttribute('aria-sort', 'ascending');
    assert.dom('thead th:nth-child(1) [data-icon-type="sortUp"]').exists();
    assert.dom('thead th:nth-child(2) button').doesNotExist('read-only columns show no button');
    assert.dom('thead th:nth-child(3)').doesNotHaveAttribute('aria-sort', 'not sortable');
    assert.dom('thead th:nth-child(4)').hasAttribute('aria-sort', 'none', 'sortable computed column');

    await click('thead th:nth-child(1) button');
    assert.deepEqual(changes[0], { page: undefined, sort: { field: 'name', direction: 'desc' } }, 'reverses the sorted column');
    assert.dom('thead th:nth-child(1)').hasAttribute('aria-sort', 'descending');

    await click('thead th:nth-child(4) button');
    assert.deepEqual(changes[1]?.sort, { field: 'Length', direction: 'asc' }, 'computed columns sort by name');
    assert.dom('thead th:nth-child(4)').hasAttribute('aria-sort', 'ascending');

    state.sorting = { sort: { field: 'name', direction: 'asc' }, enableAllColumns: true };
    await settled();
    assert.dom('thead th:nth-child(3) button').exists('enableAllColumns makes field columns sortable');

    state.sorting = { sort: { field: 'name', direction: 'asc' }, readOnly: true };
    await settled();
    assert.dom('thead button').doesNotExist('sorting.readOnly removes the buttons');
    assert.dom('thead th:nth-child(1)').hasAttribute('aria-sort', 'ascending');
  });

  test('pagination: bar, criteria, caption and staying in range', async function (assert) {
    const changes: Array<Criteria<User>> = [];
    class State {
      @tracked pagination: Pagination = { pageIndex: 0, pageSize: 2, totalItemCount: 5, pageSizeOptions: [2, 5] };
    }
    const state = new State();
    const onChange = (criteria: Criteria<User>) => changes.push(criteria);
    const columns: Array<EuiBasicTableColumn<User>> = [{ field: 'name', name: 'Name' }];
    const page = users.slice(0, 2);
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiBasicTable @items={{page}} @columns={{columns}} @pagination={{state.pagination}} @onChange={{onChange}} @tableCaption="Users" />
        </EuiEmotionProvider>
      </template>
    );
    assert.dom('caption').hasText('Users, Showing 2 of 5 data rows. Page 1 of 3.');
    const table = document.querySelector('table.euiTable')!;
    assert.dom('.euiPagination').exists();
    assert.dom('[data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 2');
    assert.dom('.euiPagination [aria-controls]').hasAttribute('aria-controls', table.id);

    await click('[data-test-subj="pagination-button-1"]');
    assert.deepEqual(changes[0], { page: { index: 1, size: 2 } });

    await click('[data-test-subj="tablePaginationPopoverButton"]');
    await click(document.querySelector('[data-test-subj="tablePagination-5-rows"]')!);
    assert.deepEqual(changes[1], { page: { index: 0, size: 5 } }, 'a new page size goes back to the first page');

    // the bar's padding (upstream xs/s) and no panelled background
    const bar = document.querySelector('.euiBasicTable > div:last-child') as HTMLElement;
    assert.strictEqual(getComputedStyle(bar).paddingTop, '4px');
    assert.strictEqual(getComputedStyle(bar).paddingLeft, '8px');
    assert.strictEqual(getComputedStyle(bar).backgroundColor, 'rgba(0, 0, 0, 0)');

    state.pagination = { pageIndex: 4, pageSize: 2, totalItemCount: 5 };
    await settled();
    assert.deepEqual(changes[2], { page: { index: 2, size: 2 } }, 'out of range pages move back to the last page');

    state.pagination = { pageIndex: 0, pageSize: 2, totalItemCount: 0 };
    await settled();
    assert.dom('.euiPagination').doesNotExist('no bar without items');
  });

  test('selection: checkboxes, select all, selectable items and disabled actions', async function (assert) {
    const changes: User[][] = [];
    const clicked: string[] = [];
    const selection: EuiTableSelectionType<User> = {
      onSelectionChange: (selected) => changes.push(selected),
      selectable: (user) => user.online,
      selectableMessage: (selectable, user) => (selectable ? '' : `${user.name} is offline`)
    };
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name' },
      {
        name: 'Actions',
        actions: [{ name: 'Edit', description: 'Edit user', onClick: (user: User) => clicked.push(user.name) }]
      }
    ];
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiBasicTable @items={{users}} @itemId="id" @columns={{columns}} @selection={{selection}} @responsiveBreakpoint={{false}} />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('thead [data-test-subj="checkboxSelectAll"]').hasAttribute('aria-label', 'Select all rows').isNotChecked();
    assert.dom('[data-test-subj="checkboxSelectRow-1"]').hasAttribute('aria-label', 'Select row 1').isNotDisabled();
    assert.dom('[data-test-subj="checkboxSelectRow-2"]').hasAttribute('aria-label', 'Bob is offline').isDisabled();
    assert.dom('tbody tr:nth-child(2)').doesNotHaveClass('euiTableRow-isSelectable');

    await click('[data-test-subj="checkboxSelectRow-1"]');
    assert.deepEqual(changes.at(-1)?.map((user) => user.id), [1]);
    assert.dom('tbody tr:first-child').hasClass('euiTableRow-isSelected');
    assert.true((document.querySelector('thead [data-test-subj="checkboxSelectAll"]') as HTMLInputElement).indeterminate);
    assert.dom('thead [data-test-subj="checkboxSelectAll"]').hasAttribute('aria-label', 'Deselect rows');
    assert.dom('tbody tr:first-child .euiButtonEmpty').isDisabled('row actions are disabled while rows are selected');

    await click('thead [data-test-subj="checkboxSelectAll"]');
    assert.deepEqual(changes.at(-1)?.map((user) => user.id), [], 'indeterminate select all deselects');
    await click('thead [data-test-subj="checkboxSelectAll"]');
    assert.deepEqual(changes.at(-1)?.map((user) => user.id), [1, 3], 'selects the selectable items');
    assert.dom('thead [data-test-subj="checkboxSelectAll"]').isChecked();

    await click('[data-test-subj="checkboxSelectRow-3"]');
    assert.deepEqual(changes.at(-1)?.map((user) => user.id), [1]);
    await click('[data-test-subj="checkboxSelectRow-1"]');
    await click('tbody tr:first-child .euiButtonEmpty');
    assert.deepEqual(clicked, ['Ann'], 'actions work again without a selection');

    // row selection styles (upstream selected background)
    await click('[data-test-subj="checkboxSelectRow-3"]');
    assert.strictEqual(
      getComputedStyle(document.querySelector('tbody tr:nth-child(3)')!).backgroundColor,
      rgb(light.components.tableRowBackgroundSelected)
    );
  });

  test('controlled and initial selection follow the items', async function (assert) {
    const changes: User[][] = [];
    class State {
      @tracked items = users;
      @tracked selected: User[] = [users[0]!, users[2]!];
    }
    const state = new State();
    const columns: Array<EuiBasicTableColumn<User>> = [{ field: 'name', name: 'Name' }];
    const controlled = {
      get selected() {
        return state.selected;
      },
      onSelectionChange: (selected: User[]) => changes.push(selected)
    };
    const initial: EuiTableSelectionType<User> = { initialSelected: [users[1]!] };
    await render(
      <template>
        <EuiEmotionProvider>
          <div class="controlled">
            <EuiBasicTable @items={{state.items}} @itemId="id" @columns={{columns}} @selection={{controlled}} />
          </div>
          <div class="initial">
            <EuiBasicTable @items={{users}} @itemId="id" @columns={{columns}} @selection={{initial}} />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    assert.dom('.controlled tbody tr.euiTableRow-isSelected').exists({ count: 2 });
    assert.dom('.initial [data-test-subj="checkboxSelectRow-2"]').isChecked();

    await click('.controlled [data-test-subj="checkboxSelectRow-2"]');
    assert.deepEqual(changes.at(-1)?.map((user) => user.id), [1, 3, 2]);
    assert.dom('.controlled [data-test-subj="checkboxSelectRow-2"]').isNotChecked('controlled: the parent decides');

    state.items = users.slice(0, 2);
    await settled();
    assert.deepEqual(changes.at(-1)?.map((user) => user.id), [1], 'items that left the table are unselected');
  });

  test('actions: inline, icon, collapsed menu, primary and custom actions', async function (assert) {
    const clicked: string[] = [];
    const Custom: TemplateOnlyComponent<{ Args: { item: User; enabled: boolean } }> = <template>
      <span data-custom>{{@item.name}} {{if @enabled "on" "off"}}</span>
    </template>;
    const two: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name' },
      {
        name: 'Actions',
        actions: [
          { name: 'Edit', description: 'Edit this user', onClick: (user: User) => clicked.push(`edit ${user.name}`), 'data-test-subj': 'edit' },
          {
            name: (user: User) => `Delete ${user.name}`,
            description: 'Delete',
            type: 'icon',
            icon: 'trash',
            color: 'danger',
            onClick: (user: User) => clicked.push(`delete ${user.name}`),
            enabled: (user: User) => user.online,
            'data-test-subj': (user: User) => `delete-${user.id}`
          }
        ]
      }
    ];
    const many: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name' },
      {
        name: 'Actions',
        actions: [
          { name: 'Edit', description: 'Edit', isPrimary: true, onClick: (user: User) => clicked.push(`edit ${user.name}`) },
          { name: 'Share', description: 'Share it', onClick: (user: User) => clicked.push(`share ${user.name}`), 'data-test-subj': 'share' },
          { name: 'Hidden', description: 'Hidden', onClick: () => {}, available: () => false },
          { component: Custom }
        ]
      }
    ];
    const one = users.slice(0, 2);
    await render(
      <template>
        <EuiEmotionProvider>
          <div class="two"><EuiBasicTable @items={{one}} @columns={{two}} /></div>
          <div class="many"><EuiBasicTable @items={{one}} @columns={{many}} /></div>
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('.two thead th:last-child').hasText('Actions');
    assert.dom('.two tbody tr:first-child').hasClass('euiTableRow-hasActions');
    assert.dom('.two tbody tr:first-child td:last-child').hasClass('euiTableRowCell--hasActions');
    await click('.two [data-test-subj="edit"]');
    assert.deepEqual(clicked, ['edit Ann']);
    assert.dom('.two [data-test-subj="delete-1"] [data-icon-type="trash"]').exists();
    const labelledBy = document.querySelector('.two [data-test-subj="delete-1"]')!.getAttribute('aria-labelledby');
    assert.dom(`#${labelledBy}`).hasText('Delete Ann', 'icon actions are labelled by their name');
    assert.dom('.two [data-test-subj="delete-2"]').isDisabled('enabled(item) false');
    await click('.two [data-test-subj="delete-1"]');
    assert.deepEqual(clicked, ['edit Ann', 'delete Ann']);

    await triggerEvent('.two [data-test-subj="edit"]', 'mouseover');
    assert.dom('.euiToolTip', document.body).hasText('Edit this user');
    await triggerEvent('.two [data-test-subj="edit"]', 'mouseout');

    // more than 2 actions: primary actions inline (on hover) and the menu
    assert.dom('.many tbody tr:first-child .euiButtonEmpty').hasText('Edit').hasClass('euiBasicTableAction-showOnHover');
    assert.dom('.many [data-custom]').doesNotExist('non primary actions are in the menu');
    const menu = '.many tbody tr:first-child [data-test-subj="euiCollapsedItemActionsButton"]';
    assert.dom(menu).hasAttribute('aria-label', 'All actions, row 1');
    await click(menu);
    assert.deepEqual(texts('.euiBasicTable__collapsedAction', document.body), ['Edit', 'Share'], 'unavailable actions are left out');
    assert.dom('.euiBasicTable__collapsedCustomAction [data-custom]', document.body).hasText('Ann on');
    await click(document.querySelector('[data-test-subj="share"]')!);
    assert.deepEqual(clicked.at(-1), 'share Ann');
    assert.dom('.euiBasicTable__collapsedAction', document.body).doesNotExist('clicking an action closes the menu');
  });

  test('expanded rows, row and cell props, empty, error and loading states', async function (assert) {
    class State {
      @tracked items = users;
      @tracked error?: string;
      @tracked loading = false;
    }
    const state = new State();
    const rowClicks: number[] = [];
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name' },
      { field: 'age', name: 'Age', mobileOptions: { only: true } }
    ];
    const expanded = { 1: 'Ann details', 3: { custom: true } };
    const rowProps = (user: User) => ({ 'data-test-subj': `row-${user.id}`, onClick: () => rowClicks.push(user.id) });
    const cellProps = { className: 'custom-cell' };
    const selection = {};
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiBasicTable
            @items={{state.items}}
            @itemId="id"
            @columns={{columns}}
            @itemIdToExpandedRowMap={{expanded}}
            @rowProps={{rowProps}}
            @cellProps={{cellProps}}
            @selection={{selection}}
            @error={{state.error}}
            @loading={{state.loading}}
            @responsiveBreakpoint={{false}}
          >
            <:expandedRow as |item itemId value|>
              {{#if value.custom}}<em data-expanded>{{item.name}} #{{itemId}}</em>{{else}}{{value}}{{/if}}
            </:expandedRow>
          </EuiBasicTable>
        </EuiEmotionProvider>
      </template>
    );
    assert.dom('tbody tr').exists({ count: 5 }, '3 rows and 2 expanded rows');
    assert.dom('tbody tr:first-child').hasAttribute('aria-owns', 'row_1_expansion').hasClass('euiTableRow-isExpandable');
    assert.dom('#row_1_expansion').hasClass('euiTableRow-isExpandedRow').hasText('Ann details');
    assert.dom('#row_1_expansion td').hasAttribute('colspan', '2', 'checkbox + columns - mobile only columns');
    assert.dom('#row_3_expansion [data-expanded]').hasText('Cid #3');
    assert.dom('[data-test-subj="row-2"]').hasClass('euiTableRow-isClickable');
    assert.dom('[data-test-subj="row-2"] td.custom-cell').exists();
    await click('[data-test-subj="row-2"] td.custom-cell');
    assert.deepEqual(rowClicks, [2]);

    state.loading = true;
    await settled();
    assert.dom('.euiBasicTable').hasClass('euiBasicTable-loading');
    const before = getComputedStyle(document.querySelector('tbody')!, '::before');
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      assert.ok(before.backgroundImage.startsWith('repeating-linear-gradient'), 'static stripes without motion');
      assert.strictEqual(before.animationName, 'none');
    } else {
      assert.strictEqual(before.backgroundColor, rgb(light.colors.primary), 'loading line');
      assert.notStrictEqual(before.animationName, 'none');
    }
    assert.strictEqual(before.height, '2px');
    assert.strictEqual(getComputedStyle(document.querySelector('table')!).position, 'relative', 'Safari workaround');

    state.loading = false;
    state.error = 'Could not load';
    await settled();
    assert.dom('tbody tr').exists({ count: 1 });
    assert.dom('tbody td').hasAttribute('colspan', '3').hasText('Could not load');
    assert.dom('tbody [data-icon-type="minusCircle"]').exists();

    state.error = undefined;
    state.items = [];
    await settled();
    assert.dom('tbody td').hasText('No items found');
    assert.dom('caption').hasText('Data table (empty), No items found,');
  });

  test('footers, panelled look, cards layout and provider colors', async function (assert) {
    const columns: Array<EuiBasicTableColumn<User>> = [
      { field: 'name', name: 'Name', footer: 'Total', sortable: true },
      { field: 'age', name: 'Age', align: 'right', footer: ({ items }) => String(items.reduce((sum, user) => sum + (user.age ?? 0), 0)) },
      { field: 'online', name: 'Online', mobileOptions: { header: 'Is online' } }
    ];
    const pagination = { pageIndex: 0, pageSize: 10, totalItemCount: 3 };
    const sorting = { sort: { field: 'name' as const, direction: 'asc' as const } };
    const selection = {};
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <div class="light">
            <EuiBasicTable @items={{users}} @itemId="id" @columns={{columns}} @panelled={{true}} @pagination={{pagination}} @onChange={{noop}} @responsiveBreakpoint={{false}} />
          </div>
          <EuiEmotionProvider @colorMode="dark">
            <div class="dark">
              <EuiBasicTable @items={{users}} @itemId="id" @columns={{columns}} @panelled={{true}} @pagination={{pagination}} @onChange={{noop}} @responsiveBreakpoint={{false}} />
            </div>
          </EuiEmotionProvider>
          <div class="cards">
            <EuiBasicTable @items={{users}} @itemId="id" @columns={{columns}} @sorting={{sorting}} @selection={{selection}} @onChange={{noop}} @responsiveBreakpoint={{true}} />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    assert.deepEqual(texts('.light tfoot td'), ['Total', '41', '']);
    assert.dom('.light tfoot td:nth-child(2) .euiTableCellContent').hasStyle({ justifyContent: 'flex-end' });

    const wrapper = (scope: string) =>
      getComputedStyle(document.querySelector(`.${scope} [data-test-subj="euiBasicTablePanelledWrapper"]`)!);
    assert.strictEqual(wrapper('light').borderTopColor, rgb(light.border.color));
    assert.strictEqual(wrapper('dark').borderTopColor, rgb(dark.border.color), 'nearest provider');
    assert.notStrictEqual(wrapper('light').borderTopLeftRadius, '0px', 'rounded top');
    assert.strictEqual(wrapper('light').borderBottomLeftRadius, '0px', 'square bottom above the bar');
    assert.strictEqual(wrapper('light').borderBottomWidth, '0px', 'joined with the pagination bar');
    const bar = (scope: string) => getComputedStyle(document.querySelector(`.${scope} .euiBasicTable > div:last-child`)!);
    assert.strictEqual(bar('light').backgroundColor, rgb(light.colors.backgroundBaseSubdued), 'panelled pagination bar');
    assert.strictEqual(bar('dark').backgroundColor, rgb(dark.colors.backgroundBaseSubdued));

    // cards: mobile header with select all and sorting, mobile cell headers
    assert.dom('.cards .euiTableHeaderMobile [data-test-subj="checkboxSelectAll"]').exists();
    assert.dom('.cards .euiTableHeaderMobile .euiCheckbox__label').hasText('Select all rows');
    assert.dom('.cards .euiTableSortMobile').exists();
    assert.deepEqual(texts('.cards tbody tr:first-child .euiTableRowCell__mobileHeader'), ['Name', 'Age', 'Is online']);
  });
});
