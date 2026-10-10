import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiTable from '#src/components/eui-table.gts';
import EuiTableBody from '#src/components/eui-table-body.gts';
import EuiTableFooter from '#src/components/eui-table-footer.gts';
import EuiTableFooterCell from '#src/components/eui-table-footer-cell.gts';
import EuiTableHeader from '#src/components/eui-table-header.gts';
import EuiTableHeaderButton from '#src/components/eui-table-header-button.gts';
import EuiTableHeaderCell from '#src/components/eui-table-header-cell.gts';
import EuiTableHeaderCellCheckbox from '#src/components/eui-table-header-cell-checkbox.gts';
import EuiTableHeaderMobile from '#src/components/eui-table-header-mobile.gts';
import EuiTablePagination from '#src/components/eui-table-pagination.gts';
import EuiTableRow from '#src/components/eui-table-row.gts';
import EuiTableRowCell from '#src/components/eui-table-row-cell.gts';
import EuiTableRowCellCheckbox from '#src/components/eui-table-row-cell-checkbox.gts';
import EuiTableSortMobile from '#src/components/eui-table-sort-mobile.gts';

module('Integration | Component | eui-table', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a table from its parts', async function (assert) {
    const mobile = { header: 'Name' };

    await render(
      <template>
        <EuiTable @compressed={{true}} @tableLayout="auto">
          <EuiTableHeader>
            <EuiTableHeaderCellCheckbox @width={{32}}><input type="checkbox" aria-label="All" /></EuiTableHeaderCellCheckbox>
            <EuiTableHeaderCell @width="40%">Name</EuiTableHeaderCell>
            <EuiTableHeaderCell @align="right" @description="In euros">Amount</EuiTableHeaderCell>
          </EuiTableHeader>
          <EuiTableBody>
            <EuiTableRow @isSelected={{true}} @isSelectable={{true}}>
              <EuiTableRowCellCheckbox><input type="checkbox" aria-label="Select" /></EuiTableRowCellCheckbox>
              <EuiTableRowCell @setScopeRow={{true}} @mobileOptions={{mobile}}>Alice</EuiTableRowCell>
              <EuiTableRowCell @align="right" @truncateText={{true}}>1,200</EuiTableRowCell>
            </EuiTableRow>
          </EuiTableBody>
          <EuiTableFooter>
            <EuiTableFooterCell />
            <EuiTableFooterCell>Total</EuiTableFooterCell>
            <EuiTableFooterCell @align="right">1,200</EuiTableFooterCell>
          </EuiTableFooter>
        </EuiTable>
      </template>
    );

    assert.dom('table.euiTable').hasClass('euiTable--compressed').hasClass('euiTable--auto').hasClass('euiTable--responsive');
    assert.dom('thead tr th').exists({ count: 3 });
    assert.dom('th.euiTableHeaderCellCheckbox').hasAttribute('scope', 'col').hasStyle({ width: '32px' });
    assert.dom('th.euiTableHeaderCell').hasAttribute('scope', 'col').hasAttribute('role', 'columnheader');
    assert.dom('th.euiTableHeaderCell:nth-child(2)').hasAttribute('style', 'width: 40%');
    assert.dom('th.euiTableHeaderCell:nth-child(3) .euiTableCellContent').hasClass('euiTableCellContent--alignRight');
    assert.dom('th.euiTableHeaderCell:nth-child(3) .euiTableCellContent__text').hasAttribute('title', 'Amount; In euros');
    assert.dom('tr.euiTableRow').hasClass('euiTableRow-isSelected').hasClass('euiTableRow-isSelectable');
    assert.dom('th.euiTableRowCell').hasAttribute('scope', 'row');
    assert.dom('th.euiTableRowCell .euiTableRowCell__mobileHeader').hasText('Name');
    assert.dom('td.euiTableRowCell:last-child .euiTableCellContent').hasClass('euiTableCellContent--truncateText');
    assert.dom('td.euiTableRowCell').hasClass('euiTableRowCell--middle');
    assert.dom('tfoot tr td.euiTableFooterCell').exists({ count: 3 });
  });

  test('sortable headers', async function (assert) {
    let sorts = 0;
    const onSort = () => sorts++;

    await render(
      <template>
        <EuiTable>
          <EuiTableHeader>
            <EuiTableHeaderCell class="sorted" @onSort={{onSort}} @isSorted={{true}} @isSortAscending={{true}}>Name</EuiTableHeaderCell>
            <EuiTableHeaderCell class="unsorted" @onSort={{onSort}}>Date</EuiTableHeaderCell>
            <EuiTableHeaderCell class="readonly" @onSort={{onSort}} @isSorted={{true}} @readOnly={{true}}>Size</EuiTableHeaderCell>
          </EuiTableHeader>
        </EuiTable>
      </template>
    );

    assert.dom('.sorted').hasAria('sort', 'ascending');
    assert.dom('.sorted button.euiTableHeaderButton').hasClass('euiTableHeaderButton-isSorted');
    assert.dom('.sorted .euiTableSortIcon').exists();
    assert.dom('.unsorted').hasAria('sort', 'none');
    assert.dom('.unsorted .euiTableSortIcon').doesNotExist();
    assert.dom('.readonly').hasAria('sort', 'descending');
    assert.dom('.readonly button').doesNotExist('read-only headers are not buttons');

    await click('.unsorted button');
    assert.strictEqual(sorts, 1);
  });

  test('clickable rows, actions and hover content', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiTable>
          <EuiTableBody>
            <EuiTableRow @onClick={{onClick}} @hasActions={{true}}>
              <EuiTableRowCell @textOnly={{false}}><button type="button">Edit</button></EuiTableRowCell>
              <EuiTableRowCell @hasActions={{true}} @showOnHover={{true}}>Delete</EuiTableRowCell>
            </EuiTableRow>
          </EuiTableBody>
        </EuiTable>
      </template>
    );

    assert.dom('tr').hasClass('euiTableRow-isClickable').hasClass('euiTableRow-hasActions').hasAttribute('tabindex', '0');
    assert.dom('td:first-child .euiTableCellContent').hasClass('euiTableCellContent--overflowingContent');
    assert.dom('td:last-child').hasClass('euiTableRowCell--hasActions');
    assert.dom('td:last-child .euiTableCellContent__hoverItem').exists();

    await click('tr');
    await triggerKeyEvent('tr', 'keyup', 'Enter');
    assert.strictEqual(clicks, 2, 'click and Enter');
  });

  test('header button, mobile header and mobile sort', async function (assert) {
    let sorted = '';
    const items = [
      { name: 'Name', isSorted: true, isSortAscending: true, onSort: () => (sorted = 'name') },
      { name: 'Date', onSort: () => (sorted = 'date') },
    ];

    await render(
      <template>
        <EuiTableHeaderButton @iconType="arrowDown">Columns</EuiTableHeaderButton>
        <EuiTableHeaderMobile><EuiTableSortMobile @items={{items}} /></EuiTableHeaderMobile>
      </template>
    );

    assert.dom('button.euiTableHeaderButton span').hasAttribute('title', 'Columns');
    assert.dom('.euiTableHeaderButton__icon').exists();

    await click('.euiTableSortMobile button');
    await waitUntil(() => document.querySelector('.euiTableSortMobileItem'));
    assert.dom('.euiTableSortMobileItem', document.body).exists({ count: 2 });
    assert.dom('.euiTableSortMobileItem-isSorted', document.body).hasText('Name');

    await click(document.querySelectorAll('.euiTableSortMobileItem')[1]!);
    assert.strictEqual(sorted, 'date');
  });

  test('table pagination', async function (assert) {
    const pages: number[] = [];
    const sizes: number[] = [];
    const state = new (class {
      @tracked page = 0;
      @tracked size = 20;
    })();
    const onChangePage = (page: number) => {
      pages.push(page);
      state.page = page;
    };
    const onChangeItemsPerPage = (size: number) => {
      sizes.push(size);
      state.size = size;
    };

    await render(
      <template>
        <EuiTablePagination
          @activePage={{state.page}}
          @pageCount={{5}}
          @itemsPerPage={{state.size}}
          @onChangePage={{onChangePage}}
          @onChangeItemsPerPage={{onChangeItemsPerPage}}
        />
      </template>
    );

    assert.dom('[data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 20');

    await click('[data-test-subj="tablePaginationPopoverButton"]');
    await waitUntil(() => document.querySelector('[data-test-subj="tablePagination-50-rows"]'));
    await click(document.querySelector('[data-test-subj="tablePagination-50-rows"]') as Element);
    assert.deepEqual(sizes, [50]);
    assert.dom('[data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 50');

    await click('.euiPagination [aria-label^="Next"]');
    assert.deepEqual(pages, [1]);
    assert.dom('[aria-current="true"]').hasText('2');

    state.page = 4;
    state.size = 10;
    await rerender();
    assert.dom('[aria-current="true"]').hasText('5');
    assert.dom('[aria-label="Next page"]').isDisabled();
    assert.dom('[data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 10');
    assert.deepEqual(sizes, [50]);
    assert.deepEqual(pages, [1], 'external updates do not emit callbacks');
  });
});
