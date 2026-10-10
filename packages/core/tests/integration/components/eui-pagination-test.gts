import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiPagination from '#src/components/eui-pagination.gts';

module('Integration | Component | eui-pagination', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders page buttons and the skipped range label', async function (assert) {
    await render(
      <template><EuiPagination @pageCount={{20}} @activePage={{0}} /></template>
    );

    assert.dom('nav.euiPagination').exists();
    assert.dom('.euiPaginationButton').exists({ count: 6 });
    // uses the `add` / `sub` helpers: last range is (lastPageInRange + 1) .. (pageCount - 1)
    assert
      .dom('li.euiPaginationButton-isPlaceholder')
      .hasAttribute('aria-label', /^Skipping pages \d+ to 19$/);
  });

  test('it calls onPageClick with the page index', async function (assert) {
    const clicked: number[] = [];
    const onPageClick = (index: number) => clicked.push(index);

    await render(
      <template>
        <EuiPagination
          @pageCount={{5}}
          @activePage={{0}}
          @onPageClick={{onPageClick}}
        />
      </template>
    );

    // button labels come from `add @pageIndex 1` / `add @activePage 2`
    await click('button[aria-label="Page 3 of 5"]');
    await click('button[aria-label="Next page, 2"]');

    assert.deepEqual(clicked, [2, 1]);
    assert.dom('[aria-current="true"]').hasText('1', 'ignored callbacks leave the controlled page unchanged');
  });

  test('owner updates synchronize the active page, navigation and page-count boundaries', async function (assert) {
    const state = new (class {
      @tracked activePage = 0;
      @tracked pageCount = 5;
      clicked: number[] = [];
      select = (page: number) => {
        this.clicked.push(page);
        this.activePage = page;
      };
    })();

    await render(<template><EuiPagination @pageCount={{state.pageCount}} @activePage={{state.activePage}} @onPageClick={{state.select}} /></template>);

    assert.dom('[aria-label="Previous page"]').isDisabled();
    await click('[aria-label="Page 3 of 5"]');
    assert.deepEqual(state.clicked, [2]);
    assert.dom('[aria-current="true"]').hasText('3');
    assert.dom('[aria-label="Next page, 4"]').isNotDisabled();
    assert.dom('[aria-label="Previous page, 2"]').isNotDisabled();

    state.activePage = 4;
    await rerender();
    assert.dom('[aria-current="true"]').hasText('5');
    assert.dom('[aria-label="Next page"]').isDisabled();

    state.activePage = 0;
    state.pageCount = 1;
    await rerender();
    assert.dom('.euiPaginationButton').exists({ count: 1 });
    assert.dom('[aria-label="Next page"]').isDisabled();
    assert.dom('[aria-label="Previous page"]').isDisabled();

    state.pageCount = 0;
    await rerender();
    assert.dom('.euiPaginationButton').doesNotExist();
    assert.dom('[aria-label^="Next page"]').isDisabled();
    assert.dom('[aria-label^="Previous page"]').isDisabled();
    assert.deepEqual(state.clicked, [2], 'external updates do not emit page clicks');
  });
});
