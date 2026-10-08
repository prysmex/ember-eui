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
      .exists({ count: 98 }, 'every docs section is listed');
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

  test('tables scroll on their own, so narrow screens keep the page width', async function (assert) {
    await visit('/docs/core/docs/forms/combo-box');

    const tables = [...document.querySelectorAll('.euiPageBody table')];

    assert.ok(tables.length > 0, 'the API reference has tables');
    assert.deepEqual(
      tables.filter(
        (table) => !table.parentElement?.classList.contains('guideTableScroll'),
      ),
      [],
      'every table is in a scroll container (lib/docfy-scroll-tables.mjs)',
    );
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

  test('demo template and component tabs start with source code', async function (assert) {
    await visit('/docs/core/docs/navigation/tabs');

    const demo = document.querySelector('.docfy-demo')!;
    const buttons = demo.querySelectorAll<HTMLButtonElement>(
      '.docfy-demo__snippets__tabs__button',
    );

    for (const [index, prefix] of ['<EuiTabs>', 'import Component'].entries()) {
      await click(buttons[index]!);
      await waitUntil(() => demo.querySelector('.docfy-demo__snippet .token'));

      const source = demo.querySelector('.docfy-demo__snippet')!.textContent;
      assert.true(
        source?.startsWith(prefix),
        'no Copy label or leading blank lines',
      );
    }
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

  test('opening a playground submits a standalone project for the selected demo', async function (assert) {
    await visit('/docs/core/docs/display/card');
    await waitUntil(() => {
      const button = document.querySelector<HTMLButtonElement>(
        '[data-test-demo-playground]',
      );
      return button && !button.disabled;
    });

    // eslint-disable-next-line @typescript-eslint/unbound-method -- saved only to restore the prototype
    const originalSubmit = HTMLFormElement.prototype.submit;
    let submitted = false;
    HTMLFormElement.prototype.submit = function () {
      submitted = true;
      const fields = new FormData(this);
      const pkg = JSON.parse(
        fields.get('project[files][package.json]') as string,
      ) as { devDependencies: Record<string, string> };

      assert.strictEqual(this.action, 'https://stackblitz.com/run');
      assert.strictEqual(this.method, 'post');
      assert.strictEqual(this.target, '_blank');
      assert.strictEqual(this.rel, 'noopener noreferrer');
      assert.strictEqual(fields.get('project[template]'), 'node');
      assert.true(
        (
          fields.get('project[files][app/components/demo.hbs]') as string
        ).includes('<EuiCard'),
        'the selected card demo is included',
      );
      assert.true(fields.has('project[files][ember-cli-build.mjs]'));
      assert.true(fields.has('project[files][babel.config.mjs]'));
      assert.false(
        pkg.devDependencies['@ember-eui/core']!.startsWith('workspace:'),
      );
    };

    try {
      await click('[data-test-demo-playground]');
      assert.true(submitted, 'the button submits the project');
      assert.dom('form[action="https://stackblitz.com/run"]').doesNotExist();
    } finally {
      HTMLFormElement.prototype.submit = originalSubmit;
    }
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
