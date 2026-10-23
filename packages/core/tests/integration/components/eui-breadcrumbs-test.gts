import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { array, hash } from '@ember/helper';
import { click, render, triggerEvent, waitUntil } from '@ember/test-helpers';

import EuiBreadcrumbs from '#src/components/eui-breadcrumbs.gts';
import type { EuiBreadcrumb } from '#src/components/eui-breadcrumbs.gts';
import type { TOC } from '@ember/component/template-only';

const Label: TOC<{ Args: { label: string } }> = <template>
  <b class="label">{{@label}}</b>
</template>;

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

  test('a breadcrumb text can be a curried component', async function (assert) {
    await render(
      <template>
        <EuiBreadcrumbs
          @breadcrumbs={{array
            (hash text=(component Label label="Home") href="#home")
            (hash text=(component Label label="Current"))
          }}
          @responsive={{false}}
        />
      </template>
    );

    assert.dom('li:nth-child(1) a.euiBreadcrumb__content b.label').hasText('Home');
    assert.dom('li:nth-child(1) a.euiBreadcrumb__content').hasAttribute('href', '#home');
    assert.dom('li:nth-child(2) span.euiBreadcrumb__content b.label').hasText('Current');
  });

  test('a component text of a popover breadcrumb is shown in its tooltip too', async function (assert) {
    const crumbs: EuiBreadcrumb[] = [{ text: Label, popoverContent: 'Pick one' }, { text: 'Home' }];

    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} /></template>);

    assert.dom('li:nth-child(1) button.euiBreadcrumb__content b.label').exists();

    await triggerEvent('li:nth-child(1) .euiToolTipAnchor', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip b.label', document.body).exists();
  });

  test('a string text of a popover breadcrumb is its tooltip', async function (assert) {
    const crumbs = [{ text: 'Deployment', popoverContent: 'Pick one' }, { text: 'Home' }];

    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} /></template>);

    await triggerEvent('li:nth-child(1) .euiToolTipAnchor', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).hasText('Deployment');
  });
});
