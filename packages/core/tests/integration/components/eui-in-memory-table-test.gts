import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, fillIn, find, findAll, render, settled } from '@ember/test-helpers';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiInMemoryTable from '#src/components/eui-in-memory-table.gts';

import type { Criteria, EuiBasicTableColumn } from '#src/components/eui-basic-table.gts';
import type { EuiSearchBarOnChangeArgs, SearchFilterConfig } from '#src/components/eui-search-bar.gts';

interface Repo {
  id: number;
  name: string;
  stars: number;
  language: string;
  archived: boolean;
}

const repos: Repo[] = [
  { id: 1, name: 'ember', stars: 22000, language: 'js', archived: false },
  { id: 2, name: 'glimmer', stars: 1100, language: 'ts', archived: false },
  { id: 3, name: 'eui', stars: 6000, language: 'ts', archived: false },
  { id: 4, name: 'old-thing', stars: 5, language: 'js', archived: true },
  { id: 5, name: 'a(b)c', stars: 70, language: 'css', archived: false }
];

const columns: Array<EuiBasicTableColumn<Repo>> = [
  { field: 'name', name: 'Name', sortable: true },
  { field: 'stars', name: 'Stars', dataType: 'number', sortable: true },
  { field: 'language', name: 'Language' },
  { name: 'Length', render: (repo: Repo) => repo.name.length, sortable: (repo: Repo) => repo.name.length }
];

/**
 * Text without the hidden tabular copy markers that `EuiBasicTable` adds
 * after its cells (upstream `tabularCopyMarkers`).
 */
function visibleText(element: Element | null): string {
  if (!element) return '';
  const clone = element.cloneNode(true) as Element;
  clone.querySelectorAll('[data-tabular-copy-marker]').forEach((marker) => marker.remove());
  return clone.textContent?.replace(/\s+/g, ' ').trim() ?? '';
}

function names(): string[] {
  return findAll('tbody tr th, tbody tr td:first-child').map((cell) => visibleText(cell));
}

async function search(text: string) {
  await fillIn('.euiSearchBar__searchHolder input', text);
}

module('Integration | Component | Borealis in-memory table', function (hooks) {
  setupRenderingTest(hooks);

  test('searches, filters, sorts and pages in memory', async function (assert) {
    const tableChanges: Array<Criteria<Repo>> = [];
    const onTableChange = (criteria: Criteria<Repo>) => tableChanges.push(criteria);
    const filters: SearchFilterConfig[] = [
      { type: 'is', field: 'archived', name: 'Archived' },
      {
        type: 'field_value_selection',
        field: 'language',
        name: 'Language',
        options: [{ value: 'js' }, { value: 'ts' }, { value: 'css' }]
      }
    ];
    const searchConfig = { box: { incremental: false }, filters };
    const pagination = { pageSizeOptions: [2, 3, 0], initialPageSize: 2 };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiInMemoryTable
            @items={{repos}}
            @columns={{columns}}
            @search={{searchConfig}}
            @sorting={{true}}
            @pagination={{pagination}}
            @onTableChange={{onTableChange}}
            @rowHeader="name"
            @responsiveBreakpoint={{false}}
            class="caller"
          />
        </EuiEmotionProvider>
      </template>
    );
    assert.dom('.euiBasicTable.caller').exists('attributes go to the table');
    assert.deepEqual(names(), ['ember', 'glimmer'], 'first page of 2');
    assert.strictEqual(visibleText(find('caption')), 'Data table, Showing 2 of 5 data rows. Page 1 of 3.');

    await click('[data-test-subj="pagination-button-1"]');
    assert.deepEqual(names(), ['eui', 'old-thing']);
    assert.deepEqual(tableChanges.at(-1), { page: { index: 1, size: 2 }, sort: { field: undefined, direction: undefined } });

    await search('language:ts');
    assert.deepEqual(names(), ['glimmer', 'eui'], 'search resets to the first page');
    assert.strictEqual(visibleText(find('caption')), 'Data table, Showing 2 of 2 data rows.');

    await search('');
    await click('thead th:nth-child(2) button');
    assert.deepEqual(names(), ['old-thing', 'a(b)c'], 'first page of the items sorted by stars');
    assert.deepEqual(tableChanges.at(-1)?.sort, { field: 'stars', direction: 'asc' }, 'reports the field');
    assert.dom('thead th:nth-child(2)').hasAttribute('aria-sort', 'ascending');
    await click('[data-test-subj="tablePaginationPopoverButton"]');
    await click(document.querySelector('[data-test-subj="tablePagination-0-rows"]')!);
    assert.deepEqual(names(), ['old-thing', 'a(b)c', 'glimmer', 'eui', 'ember'], 'all rows, by stars');

    await click('thead th:nth-child(2) button');
    assert.deepEqual(names(), ['ember', 'eui', 'glimmer', 'a(b)c', 'old-thing'], 'descending');
    await click('thead th:nth-child(2) button');
    assert.deepEqual(names(), ['ember', 'glimmer', 'eui', 'old-thing', 'a(b)c'], 'back to neutral');
    assert.deepEqual(tableChanges.at(-1)?.sort, { field: '', direction: 'asc' });
    assert.dom('thead th:nth-child(2)').hasAttribute('aria-sort', 'none');

    await click('thead th:nth-child(4) button');
    assert.deepEqual(names(), ['eui', 'ember', 'a(b)c', 'glimmer', 'old-thing'], 'computed column sorter (stable)');

    await click(findAll('.euiFilterButton')[0]!);
    assert.deepEqual(names(), ['old-thing'], 'is:archived filter');
    assert.dom('.euiSearchBar__searchHolder input').hasValue('is:archived');
  });

  test('initial sort and pagination options, neutral sort opt-out and page size validation', async function (assert) {
    const sorting = { sort: { field: 'stars' as const, direction: 'desc' as const } };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiInMemoryTable
            @items={{repos}}
            @columns={{columns}}
            @sorting={{sorting}}
            @allowNeutralSort={{false}}
            @pagination={{true}}
            @responsiveBreakpoint={{false}}
          />
        </EuiEmotionProvider>
      </template>
    );
    assert.deepEqual(names(), ['ember', 'eui', 'glimmer', 'a(b)c', 'old-thing']);
    assert.dom('thead th:nth-child(2)').hasAttribute('aria-sort', 'descending');
    assert.dom('[data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 10');
    await click('thead th:nth-child(2) button');
    await click('thead th:nth-child(2) button');
    assert.dom('thead th:nth-child(2)').hasAttribute('aria-sort', 'descending', 'no neutral step');

  });

  test('rejects an initial page size missing from the options', async function (assert) {
    const invalid = { pageSizeOptions: [5, 10], initialPageSize: 7 };
    await assert.rejects(
      render(<template><EuiInMemoryTable @items={{repos}} @columns={{columns}} @pagination={{invalid}} /></template>),
      /initialPageSize 7, which wasn't provided within pageSizeOptions/
    );
  });

  test('controlled search query, onChange gating and the derived schema', async function (assert) {
    const changes: EuiSearchBarOnChangeArgs[] = [];
    class State {
      @tracked query = 'language:js';
      @tracked allow = true;
    }
    const state = new State();
    const searchConfig = {
      get query() {
        return state.query;
      },
      box: { schema: true },
      onChange: (args: EuiSearchBarOnChangeArgs) => {
        changes.push(args);
        return state.allow;
      }
    };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiInMemoryTable @items={{repos}} @columns={{columns}} @search={{searchConfig}} @responsiveBreakpoint={{false}}>
            <:toolsLeft><button type="button" data-left>Tool</button></:toolsLeft>
            <:childrenBetween><p data-between>Between</p></:childrenBetween>
          </EuiInMemoryTable>
        </EuiEmotionProvider>
      </template>
    );
    assert.deepEqual(names(), ['ember', 'old-thing'], 'controlled query filters');
    assert.dom('[data-left]').exists();
    assert.dom('[data-between]').exists();
    assert.dom('.euiFlexGroup > .euiFlexItem').exists({ count: 2 }, 'no empty right tools item');

    state.query = 'language:css';
    await settled();
    assert.deepEqual(names(), ['a(b)c']);
    assert.dom('.euiSearchBar__searchHolder input').hasValue('language:css');

    await search('owner:me');
    assert.ok(changes.at(-1)?.error?.message.includes('Unknown field `owner`'), 'schema: true is strict on the columns');
    await search('stars>1000');
    assert.strictEqual(changes.at(-1)?.error, null);
    assert.deepEqual(names(), ['ember', 'glimmer', 'eui'], 'numbers from the column data types');

    state.allow = false;
    await search('glimmer');
    assert.deepEqual(names(), ['ember', 'glimmer', 'eui'], 'onChange returning false skips the in-memory search');
  });

  test('plain text search and external items', async function (assert) {
    class State {
      @tracked items = repos;
    }
    const state = new State();
    const pagination = { initialPageSize: 10, initialPageIndex: 0, pageSizeOptions: [2, 10] };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiInMemoryTable
            @items={{state.items}}
            @columns={{columns}}
            @search={{true}}
            @searchFormat="text"
            @pagination={{pagination}}
            @responsiveBreakpoint={{false}}
          />
        </EuiEmotionProvider>
      </template>
    );
    assert.dom('.euiFilterGroup').doesNotExist('text search has no filters');
    await fillIn('input[type="search"]', 'a(b)');
    assert.deepEqual(names(), ['a(b)c'], 'reserved characters are plain text');
    await fillIn('input[type="search"]', 'language:js');
    assert.dom('tbody td').hasText('No items found', 'no query syntax');
    await fillIn('input[type="search"]', '');
    assert.strictEqual(names().length, 5);

    state.items = repos.slice(0, 2);
    await settled();
    assert.deepEqual(names(), ['ember', 'glimmer'], 'new items replace the old ones');
  });
});
