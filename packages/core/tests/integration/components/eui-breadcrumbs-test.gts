import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, waitUntil } from '@ember/test-helpers';

import EuiBreadcrumbs from '#src/components/eui-breadcrumbs.gts';

module('Integration | Component | eui-breadcrumbs', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders links, clickable and plain breadcrumbs', async function (assert) {
    let clicks = 0;
    const crumbs = [
      { text: 'Home', href: '#home' },
      { text: 'Section', onClick: () => clicks++ },
      { text: 'Current' }
    ];

    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} /></template>);

    assert.dom('nav.euiBreadcrumbs li.euiBreadcrumb').exists({ count: 3 });
    assert.dom('li:nth-child(1) a.euiBreadcrumb__content').hasAttribute('href', '#home').hasText('Home');
    assert.dom('nav').hasAttribute('aria-label', 'Breadcrumbs');
    assert.dom('li:nth-child(3) span.euiBreadcrumb__content').hasAttribute('aria-current', 'page').hasText('Current');

    await click('li:nth-child(2) .euiBreadcrumb__content');
    assert.strictEqual(clicks, 1);
  });

  test('@max collapses the middle breadcrumbs into a popover', async function (assert) {
    const crumbs = ['One', 'Two', 'Three', 'Four', 'Five'].map((text) => ({ text, href: '#' + text }));

    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @max={{3}} @responsive={{false}} /></template>);

    // The legacy `--collapsed` / `__inPopover` classes are gone; find the "…" item by its label.
    assert.dom('nav > ol > li.euiBreadcrumb').exists({ count: 4 });
    assert.dom('[aria-label="See collapsed breadcrumbs"]').exists({ count: 1 });

    await click('[aria-label="See collapsed breadcrumbs"]');
    await waitUntil(() => document.querySelector('.euiPopover__panel .euiBreadcrumbs'));

    assert.dom('.euiPopover__panel .euiBreadcrumbs li.euiBreadcrumb', document.body).exists({ count: 2 });
  });

  test('@truncate keeps the breadcrumbs on one line', async function (assert) {
    const crumbs = [{ text: 'A' }, { text: 'B' }];

    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @truncate={{true}} @responsive={{false}} /></template>);

    // Computed style instead of the removed legacy `euiBreadcrumbs--truncate` class.
    assert.strictEqual(getComputedStyle(document.querySelector('nav ol')!).flexWrap, 'nowrap');
  });
});
