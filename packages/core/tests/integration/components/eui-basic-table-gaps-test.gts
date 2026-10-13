import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { click, find, findAll, render, settled } from '@ember/test-helpers';

import EuiBasicTable from '#src/components/eui-basic-table.gts';
import EuiDataGrid from '#src/components/eui-data-grid.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiInMemoryTable from '#src/components/eui-in-memory-table.gts';
import EuiTablePagination from '#src/components/eui-table-pagination.gts';

import type { TOC } from '@ember/component/template-only';
import type EuiConfigService from '#src/services/eui-config.ts';
import type {
  EuiBasicTableColumn,
  EuiTableSelectionType,
  Pagination
} from '#src/components/eui-basic-table.gts';
import type { EuiDataGridColumn } from '#src/components/eui-data-grid.gts';

interface User {
  id: number;
  name: string;
  age: number;
}

const users: User[] = [
  { id: 1, name: 'Ann', age: 34 },
  { id: 2, name: 'Bob', age: 40 },
  { id: 3, name: 'Cid', age: 28 }
];

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

function markers(element: Element | null): Array<string | null> {
  return element
    ? Array.from(element.querySelectorAll(':scope > [data-tabular-copy-marker]')).map((marker) =>
        marker.getAttribute('data-tabular-copy-marker')
      )
    : [];
}

/** Rich action name: receives the row's item. */
const DeleteName: TOC<{ Args: { item: User } }> = <template>
  <span data-rich-name>Delete <strong>{{@item.name}}</strong></span>
</template>;

class EditName extends Component<{ Args: { item: User } }> {
  get label(): string {
    return `Edit ${this.args.item.name}`;
  }

  <template><em data-class-name>{{this.label}}</em></template>
}

module('Integration | Component | EuiBasicTable upstream gaps', function (hooks) {
  setupRenderingTest(hooks);

  module('action `name` as rich content', function () {
    test('components (with @item), functions of the item, text and htmlSafe', async function (assert) {
      const clicked: string[] = [];
      const columns: Array<EuiBasicTableColumn<User>> = [
        { field: 'name', name: 'Name' },
        {
          name: 'Actions',
          actions: [
            {
              name: DeleteName,
              description: 'Delete this user',
              onClick: (user: User) => clicked.push(`delete ${user.name}`),
              'data-test-subj': 'deleteAction'
            },
            {
              name: (user: User) => (user.id === 1 ? EditName : `Edit #${user.id}`),
              description: 'Edit this user',
              type: 'icon',
              icon: 'pencil',
              onClick: (user: User) => clicked.push(`edit ${user.name}`),
              'data-test-subj': 'editAction'
            }
          ]
        }
      ];
      await render(
        <template>
          <EuiEmotionProvider>
            <EuiBasicTable @items={{users}} @columns={{columns}} />
          </EuiEmotionProvider>
        </template>
      );
      const firstRow = find('tbody tr:first-child')!;
      assert.dom('[data-test-subj=deleteAction] [data-rich-name]', firstRow).hasText('Delete Ann', 'button content');
      assert.dom('[data-test-subj=deleteAction] strong', firstRow).hasText('Ann');

      // icon actions: the name is the screen reader label, referenced by id
      const editButton = find('tbody tr:first-child [data-test-subj=editAction]')!;
      const labelId = editButton.getAttribute('aria-labelledby')!;
      assert.dom(`#${labelId} [data-class-name]`).hasText('Edit Ann', 'a component class from a function');
      const secondLabel = find('tbody tr:nth-child(2) [data-test-subj=editAction]')!.getAttribute('aria-labelledby')!;
      assert.dom(`#${secondLabel}`).hasText('Edit #2', 'text from a function');

      await click('tbody tr:nth-child(2) [data-test-subj=deleteAction]');
      assert.deepEqual(clicked, ['delete Bob']);
    });

    test('collapsed actions render rich names in the menu', async function (assert) {
      const columns: Array<EuiBasicTableColumn<User>> = [
        { field: 'name', name: 'Name' },
        {
          name: 'Actions',
          actions: [
            { name: DeleteName, description: 'Delete', onClick: () => undefined, 'data-test-subj': 'a1' },
            { name: htmlSafe('<b data-safe>Safe</b>'), description: 'Safe', onClick: () => undefined, 'data-test-subj': 'a2' },
            { name: 'Plain', description: 'Plain', onClick: () => undefined, 'data-test-subj': 'a3' }
          ]
        }
      ];
      await render(
        <template>
          <EuiEmotionProvider>
            <EuiBasicTable @items={{users}} @columns={{columns}} />
          </EuiEmotionProvider>
        </template>
      );
      await click('tbody tr:first-child [data-test-subj=euiCollapsedItemActionsButton]');
      assert.dom('[data-test-subj=a1] [data-rich-name]', document.body).hasText('Delete Ann');
      assert.dom('[data-test-subj=a2] [data-safe]', document.body).hasText('Safe');
      assert.dom('[data-test-subj=a3]', document.body).hasText('Plain');
    });
  });

  test('a column forwards other <td> attributes, listeners and style to its cells', async function (assert) {
    const clicks: string[] = [];
    const columns: Array<EuiBasicTableColumn<User>> = [
      {
        field: 'name',
        name: 'Name',
        width: '200px',
        readOnly: true,
        title: 'The name',
        'data-col': 'name',
        'aria-describedby': 'nameHelp',
        style: { backgroundColor: 'rgb(1, 2, 3)', width: '999px' },
        onClick: (event: Event) =>
          clicks.push((event.currentTarget as HTMLElement).textContent!.trim().slice(0, 3))
      },
      {
        name: 'Age',
        render: (user: User) => String(user.age),
        tabIndex: -1,
        style: 'color: rgb(4, 5, 6)'
      },
      { field: 'id', name: 'Id' }
    ];
    const cellProps = (_item: User, column: EuiBasicTableColumn<User>) =>
      'field' in column && column.field === 'id'
        ? { style: { color: 'rgb(7, 8, 9)' }, 'data-from': 'cellProps' }
        : { style: { color: 'rgb(9, 9, 9)' }, title: 'from cellProps' };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiBasicTable @items={{users}} @columns={{columns}} @cellProps={{cellProps}} />
        </EuiEmotionProvider>
      </template>
    );
    const nameCell = find('tbody tr:first-child td:nth-child(1)') as HTMLElement;
    assert.dom(nameCell).hasAttribute('title', 'The name', 'the column wins over cellProps (upstream spread order)');
    assert.dom(nameCell).hasAttribute('data-col', 'name');
    assert.dom(nameCell).hasAttribute('aria-describedby', 'nameHelp');
    assert.dom(nameCell).doesNotHaveAttribute('readonly', 'column options are not attributes');
    assert.dom(nameCell).doesNotHaveAttribute('field');
    assert.strictEqual(getComputedStyle(nameCell).backgroundColor, 'rgb(1, 2, 3)');
    assert.strictEqual(nameCell.style.width, '200px', 'the column width wins over its style');
    assert.notOk(nameCell.style.color, "the column's style replaces cellProps' style");
    assert.dom('thead th:first-child').doesNotHaveAttribute('data-col', 'header cells are unaffected');

    await click(nameCell);
    assert.deepEqual(clicks, ['Ann'], 'on* functions become listeners');

    const ageCell = find('tbody tr:first-child td:nth-child(2)') as HTMLElement;
    assert.dom(ageCell).hasAttribute('tabindex', '-1');
    assert.strictEqual(getComputedStyle(ageCell).color, 'rgb(4, 5, 6)', 'string styles');

    const idCell = find('tbody tr:first-child td:nth-child(3)') as HTMLElement;
    assert.strictEqual(getComputedStyle(idCell).color, 'rgb(7, 8, 9)', 'cellProps style objects apply too');
    assert.dom(idCell).hasAttribute('data-from', 'cellProps');
  });

  module('copy-to-clipboard tabular markers', function () {
    test('markers after each cell, around the table and the caption', async function (assert) {
      const columns: Array<EuiBasicTableColumn<User>> = [
        { field: 'name', name: 'Name' },
        { field: 'age', name: 'Age', dataType: 'number' }
      ];
      await render(
        <template>
          <EuiEmotionProvider>
            <EuiBasicTable @items={{users}} @columns={{columns}} @tableCaption="Users" />
          </EuiEmotionProvider>
        </template>
      );
      const all = findAll('[data-tabular-copy-marker]');
      assert.ok(all.every((marker) => marker.getAttribute('aria-hidden') === 'true'), 'hidden from screen readers');
      assert.ok(all.every((marker) => marker.classList.contains('euiScreenReaderOnly')), 'and visually');
      assert.deepEqual(markers(find('.euiBasicTable')), ['boundary', 'boundary'], 'bounds around the table');
      const table = find('table.euiTable')!;
      const wrapper = table.closest('.euiTable__wrapper') ?? table;
      assert.strictEqual(wrapper.previousElementSibling?.getAttribute('data-tabular-copy-marker'), 'boundary');
      assert.strictEqual(wrapper.nextElementSibling?.getAttribute('data-tabular-copy-marker'), 'boundary');
      assert.deepEqual(markers(find('caption')), ['no-copy', 'no-copy']);
      assert.deepEqual(markers(find('thead th:nth-child(1)')), ['tab']);
      assert.deepEqual(markers(find('thead th:nth-child(2)')), ['newline'], 'the last column ends the row');
      assert.deepEqual(markers(find('tbody tr:first-child td:nth-child(1)')), ['tab']);
      assert.deepEqual(markers(find('tbody tr:first-child td:nth-child(2)')), ['newline']);
      assert.dom('tbody tr:first-child td:nth-child(1) .euiTableCellContent').hasText('Ann', 'content is unchanged');

      select(table);
      const { text, prevented } = copySelection();
      assert.true(prevented, 'the copy handler rewrites the clipboard');
      assert.strictEqual(text, 'Name\tAge\nAnn\t34\nBob\t40\nCid\t28\n');
    });

    test('selection, actions and expanded rows', async function (assert) {
      const columns: Array<EuiBasicTableColumn<User>> = [
        { field: 'name', name: 'Name' },
        { name: 'Actions', actions: [{ name: 'Edit', description: 'Edit', onClick: () => undefined }] }
      ];
      const selection: EuiTableSelectionType<User> = { onSelectionChange: () => undefined };
      const expanded = { 1: 'Ann details' };
      await render(
        <template>
          <EuiEmotionProvider>
            <EuiBasicTable
              @items={{users}}
              @itemId="id"
              @columns={{columns}}
              @selection={{selection}}
              @itemIdToExpandedRowMap={{expanded}}
            />
          </EuiEmotionProvider>
        </template>
      );
      assert.deepEqual(markers(find('thead .euiTableHeaderCellCheckbox')), ['tab']);
      assert.deepEqual(markers(find('tbody tr:first-child .euiTableRowCellCheckbox')), ['tab']);
      assert.deepEqual(markers(find('tbody tr:first-child td:last-child')), ['newline'], 'actions cell');
      assert.deepEqual(markers(find('#row_1_expansion td')), ['newline'], 'expanded row');
    });

    test('the sticky header copy keeps the markers', async function (assert) {
      const columns: Array<EuiBasicTableColumn<User>> = [
        { field: 'name', name: 'Name' },
        { field: 'age', name: 'Age' }
      ];
      await render(
        <template>
          <EuiEmotionProvider>
            <EuiBasicTable @items={{users}} @columns={{columns}} @stickyHeader={{true}} />
          </EuiEmotionProvider>
        </template>
      );
      const copies = findAll('.euiTableStickyHeader thead th');
      assert.strictEqual(copies.length, 2);
      assert.deepEqual(markers(copies[1]!), ['newline']);
    });
  });

  module('page size defaults (euiConfig componentDefaults)', function () {
    test('EuiBasicTable, its pagination bar and EuiTablePagination', async function (assert) {
      const config = this.owner.lookup('service:eui-config') as EuiConfigService;
      config.updateConfig({
        componentDefaults: {
          EuiTablePagination: { itemsPerPage: 2, itemsPerPageOptions: [2, 3] }
        }
      });
      class State {
        @tracked pagination: Pagination = { pageIndex: 0, totalItemCount: 3 };
      }
      const state = new State();
      const columns: Array<EuiBasicTableColumn<User>> = [{ field: 'name', name: 'Name' }];
      await render(
        <template>
          <EuiEmotionProvider>
            <div class="basic">
              <EuiBasicTable @items={{users}} @columns={{columns}} @pagination={{state.pagination}} @onChange={{noop}} />
            </div>
            <div class="standalone">
              <EuiTablePagination @pageCount={{4}} />
            </div>
          </EuiEmotionProvider>
        </template>
      );
      assert.dom('.basic [data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 2');
      assert.dom('.basic [data-test-subj="pagination-button-1"]').exists('3 items / 2 per page: 2 pages');
      assert.dom('.basic [data-test-subj="pagination-button-2"]').doesNotExist();
      await click('.basic [data-test-subj="tablePaginationPopoverButton"]');
      assert.dom('[data-test-subj="tablePagination-3-rows"]', document.body).exists('default options');
      assert.dom('[data-test-subj="tablePagination-10-rows"]', document.body).doesNotExist();

      assert.dom('.standalone [data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 2');

      config.updateConfig({ componentDefaults: { EuiTablePagination: { showPerPageOptions: false } } });
      await settled();
      assert.dom('[data-test-subj="tablePaginationPopoverButton"]').doesNotExist('reactive: the menu is hidden');

      state.pagination = { pageIndex: 0, pageSize: 3, totalItemCount: 3, showPerPageOptions: true, pageSizeOptions: [3] };
      await settled();
      assert.dom('.basic [data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 3', 'args win');
    });

    test('EuiInMemoryTable and EuiDataGrid', async function (assert) {
      const config = this.owner.lookup('service:eui-config') as EuiConfigService;
      config.setConfig({
        componentDefaults: { EuiTablePagination: { itemsPerPage: 2, itemsPerPageOptions: [2, 4] } }
      });
      const columns: Array<EuiBasicTableColumn<User>> = [{ field: 'name', name: 'Name' }];
      const gridColumns: EuiDataGridColumn[] = [{ id: 'name' }];
      const gridPagination = { pageIndex: 0, onChangePage: noop, onChangeItemsPerPage: noop };
      await render(
        <template>
          <EuiEmotionProvider>
            <div class="memory">
              <EuiInMemoryTable @items={{users}} @columns={{columns}} @pagination={{true}} />
            </div>
            <div class="grid" style="width:400px">
              <EuiDataGrid
                @columns={{gridColumns}}
                @rowCount={{5}}
                @toolbarVisibility={{false}}
                @pagination={{gridPagination}}
              >
                <:cell as |c|>{{c.rowIndex}}</:cell>
              </EuiDataGrid>
            </div>
          </EuiEmotionProvider>
        </template>
      );
      assert.strictEqual(findAll('.memory tbody tr').length, 2, 'in-memory pages by the default size');
      assert.dom('.memory [data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 2');
      assert.strictEqual(findAll('.grid .euiDataGridRow').length, 2, 'the grid pages by the default size');
      assert.dom('.grid [data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 2');
      await click('.grid [data-test-subj="tablePaginationPopoverButton"]');
      assert.dom('[data-test-subj="tablePagination-4-rows"]', document.body).exists();
    });

    test('without componentDefaults the upstream defaults apply', async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider>
            <EuiTablePagination @pageCount={{4}} />
          </EuiEmotionProvider>
        </template>
      );
      assert.dom('[data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 10');
      await click('[data-test-subj="tablePaginationPopoverButton"]');
      assert.deepEqual(
        Array.from(
          document.querySelectorAll('[data-test-subj^="tablePagination-"][data-test-subj$="-rows"]')
        ).map((item) =>
          item.getAttribute('data-test-subj')
        ),
        ['tablePagination-10-rows', 'tablePagination-25-rows', 'tablePagination-50-rows']
      );
    });
  });
});

function noop() {}
