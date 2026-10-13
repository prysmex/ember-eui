import { module, test } from 'qunit';
import { click, currentURL, visit } from '@ember/test-helpers';
import { setupApplicationTest } from 'site/tests/helpers';

const styles = (selector: string) =>
  getComputedStyle(document.querySelector(selector)!);

module('Acceptance | Latest EUI showcase', function (hooks) {
  setupApplicationTest(hooks);

  test('discovery and pinned upstream versions', async function (assert) {
    await visit('/docs/introduction');
    assert.dom('.euiSideNav').containsText('Latest EUI showcase');
    assert
      .dom('.pageBody a[href="/docs/eui-latest"]')
      .hasText('Latest EUI showcase');
    const navButton = [
      ...document.querySelectorAll<HTMLButtonElement>('.euiSideNav button'),
    ].find((button) => button.textContent?.trim() === 'Latest EUI showcase')!;
    await click(navButton);
    assert.strictEqual(currentURL(), '/docs/eui-latest');
    assert.dom('[data-latest-back]').hasAttribute('href', '/docs/introduction');
    assert.strictEqual(
      document.getElementById('eui-theme'),
      null,
      'no legacy stylesheet anywhere on the site',
    );
    assert
      .dom('[data-eui-latest-showcase] h1')
      .hasText('Borealis, component by component.');
    assert
      .dom('[data-latest-versions]')
      .hasText('EUI 123.1.0 · Borealis 8.1.0 · theme-common 10.1.0');
    assert
      .dom('[data-eui-latest-showcase] a[href="/docs/emotion"]')
      .hasText('original Emotion showcase');
    await visit('/docs/introduction');
    assert.strictEqual(
      getComputedStyle(document.documentElement).fontSize,
      '14px',
      'the docs shell keeps the Borealis global styles',
    );
  });

  test('native upstream surfaces and buttons keep independent theme contexts', async function (assert) {
    await visit('/docs/eui-latest');
    const light = styles('[data-latest-light-action]').backgroundColor;
    const dark = styles('[data-latest-dark-action]').backgroundColor;
    assert.notStrictEqual(light, dark);
    assert.notStrictEqual(
      styles('[data-latest-light-island]').backgroundColor,
      styles('[data-latest-dark-island]').backgroundColor,
    );
    assert.strictEqual(styles('[data-latest-light-action]').height, '40px');
    assert.strictEqual(
      styles('[data-latest-light-action]').borderRadius,
      '8px',
      'native Borealis control radius',
    );
    await click('[data-latest-dark]');
    assert.dom('[data-eui-latest-showcase]').hasAttribute('data-mode', 'dark');
    assert.dom('[data-latest-dark]').hasAttribute('aria-pressed', 'true');
    assert.strictEqual(
      styles('[data-latest-light-action]').backgroundColor,
      light,
    );
    assert.strictEqual(
      styles('[data-latest-dark-action]').backgroundColor,
      dark,
    );
    await click('[data-latest-light]');
    assert.dom('[data-latest-light]').hasAttribute('aria-pressed', 'true');
  });

  test('nested overrides, contrast and native action controls stay reactive', async function (assert) {
    await visit('/docs/eui-latest');
    assert.strictEqual(
      styles('[data-latest-override-button]').borderRadius,
      '8px',
    );
    assert.strictEqual(
      styles('[data-latest-override-panel]').borderRadius,
      '12px',
    );
    await click('[data-latest-rounded]');
    assert.strictEqual(
      styles('[data-latest-override-button]').borderRadius,
      '24px',
    );
    assert.strictEqual(
      styles('[data-latest-override-panel]').borderRadius,
      '24px',
    );
    assert.strictEqual(
      styles('[data-latest-light-action]').borderRadius,
      '8px',
      'other island unaffected',
    );
    await click('[data-contrast-preferred]');
    assert
      .dom('[data-contrast-preferred]')
      .hasAttribute('aria-pressed', 'true');
    assert.strictEqual(
      styles('[data-latest-light-action]').borderTopStyle,
      'solid',
    );
    await click('[data-contrast-forced]');
    assert.dom('[data-contrast-forced]').hasAttribute('aria-pressed', 'true');
    await click('[data-contrast-standard]');
    assert.dom('[data-contrast-standard]').hasAttribute('aria-pressed', 'true');
    await click('[data-latest-save]');
    assert.dom('[data-latest-save-count]').hasText('1 change saved');
    await click('[data-latest-save]');
    assert.dom('[data-latest-save-count]').hasText('2 changes saved');
    assert.dom('[data-latest-disabled]').isDisabled();
    assert.dom('[data-latest-loading]').isNotDisabled();
    await click('[data-latest-toggle-loading]');
    assert
      .dom('[data-latest-loading]')
      .isDisabled()
      .hasAttribute('aria-busy', 'true');
    assert.dom('[data-latest-loading] .euiButtonContent__spinner').exists();
    await click('[data-latest-toggle-loading]');
    assert
      .dom('[data-latest-loading]')
      .isNotDisabled()
      .doesNotHaveAttribute('aria-busy');
    assert.dom('[data-latest-variant]').exists({ count: 7 });
  });
});
