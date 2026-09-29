import { module, test } from 'qunit';
import { click, currentURL, visit, waitUntil } from '@ember/test-helpers';

import { setupApplicationTest } from 'site/tests/helpers';

import type DocfyService from '@docfy/ember/services/docfy';

const themeLink = () =>
  document.getElementById('eui-theme') as HTMLLinkElement | null;

module('Acceptance | docs', function (hooks) {
  setupApplicationTest(hooks);

  test('/ redirects to the introduction with the side nav', async function (assert) {
    await visit('/');

    assert.strictEqual(currentURL(), '/docs/introduction');
    assert.dom('.euiSideNav').exists();
    assert
      .dom('.euiSideNavItem')
      .exists({ count: 91 }, 'every docs section is listed');
  });

  test('every docs page renders with its demos', async function (assert) {
    const docfy = this.owner.lookup('service:docfy') as DocfyService;
    const pages = docfy.flat.filter((page) => !page.frontmatter['disabled']);

    for (const page of pages) {
      await visit(page.url);

      assert.strictEqual(currentURL(), page.url, `${page.url} renders`);
    }

    // demos with a fixed control bar or bottom bar clean up when leaving
    await visit('/docs/introduction');
    assert.strictEqual(document.body.style.paddingBottom, '');
  });

  test('every docs page renders with its demos', async function (assert) {
    const docfy = this.owner.lookup('service:docfy') as DocfyService;
    const pages = docfy.flat.filter((page) => !page.frontmatter['disabled']);

    for (const page of pages) {
      await visit(page.url);

      assert.strictEqual(currentURL(), page.url, `${page.url} renders`);
    }

    // demos with a fixed control bar or bottom bar clean up when leaving
    await visit('/docs/introduction');
    assert.strictEqual(document.body.style.paddingBottom, '');
  });

  test('a component page renders its demos and code tabs', async function (assert) {
    await visit('/docs/core/docs/display/card');

    assert.dom('.euiPageHeader').containsText('Card');
    assert.dom('.docfy-demo .docfy-demo__example').exists({ count: 9 });
    assert.dom('.docfy-demo__snippet').doesNotExist('code is collapsed');

    await click('.docfy-demo__snippets__tabs__button');

    assert.dom('.docfy-demo__snippet').exists('the tab opens the code');
    assert.dom('.docfy-demo .euiCodeBlock').exists();
  });

  test('prose components are auto-imported into strict page templates', async function (assert) {
    await visit('/docs/core/docs/display/icons');

    assert
      .dom('.euiPageHeader')
      .containsText('Icons', '<EuiPageHeader> in the markdown prose renders');
    assert
      .dom('.iconGallery')
      .exists('the site component <IconGallery> in the prose renders');
  });

  test('switching theme swaps the EUI stylesheet', async function (assert) {
    await visit('/docs/introduction');

    assert.strictEqual(themeLink()?.dataset['theme'], 'light');

    await click('.euiHeader .euiButton');
    await waitUntil(() => document.querySelector('.euiContextMenuItem'));
    const dark = [...document.querySelectorAll('.euiContextMenuItem')].find(
      (item) => item.textContent?.trim() === 'Dark',
    ) as HTMLElement;

    await click(dark);

    assert.strictEqual(themeLink()?.dataset['theme'], 'dark');
    assert.true(
      themeLink()!.href.includes('eui_theme_dark'),
      'dark stylesheet',
    );
  });

  test("the changelog renders core's CHANGELOG.md", async function (assert) {
    await visit('/docs/package/changelog');

    assert.dom('.euiMarkdownFormat').containsText('@ember-eui/core');
  });
});
