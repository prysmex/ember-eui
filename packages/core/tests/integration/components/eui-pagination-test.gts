import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

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
  });
});
