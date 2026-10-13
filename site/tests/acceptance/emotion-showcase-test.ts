import { module, test } from 'qunit';
import { click, currentURL, visit } from '@ember/test-helpers';
import { setupApplicationTest } from 'site/tests/helpers';

function styles(selector: string): CSSStyleDeclaration {
  return getComputedStyle(document.querySelector(selector)!);
}

module('Acceptance | Emotion showcase', function (hooks) {
  setupApplicationTest(hooks);

  test('the introduction links to the showcase and the original URL redirects', async function (assert) {
    await visit('/docs/introduction');
    assert.dom('.euiSideNav').containsText('Emotion showcase');
    assert
      .dom('.pageBody a[href="/docs/emotion"]')
      .hasText('Emotion showcase');
    const navButton = [
      ...document.querySelectorAll<HTMLButtonElement>('.euiSideNav button'),
    ].find((button) => button.textContent?.trim() === 'Emotion showcase')!;
    await click(navButton);
    assert.strictEqual(currentURL(), '/docs/emotion');
    assert.dom('[data-emotion-showcase] h1').hasText('Ember, meet Emotion.');
    await visit('/emotion-spike');
    assert.strictEqual(currentURL(), '/docs/emotion');
  });

  test('light and dark contexts coexist and stay fixed as the page changes', async function (assert) {
    await visit('/docs/emotion');
    assert.dom('[data-theme-light]').hasAttribute('aria-pressed', 'true');
    assert.strictEqual(
      styles('[data-save-changes]').backgroundColor,
      'rgb(0, 90, 158)',
    );
    assert.strictEqual(
      styles('[data-light-island] [data-island-primary]').backgroundColor,
      'rgb(0, 90, 158)',
    );
    assert.strictEqual(
      styles('[data-dark-island] [data-island-primary]').backgroundColor,
      'rgb(121, 184, 255)',
    );
    assert.strictEqual(
      styles('[data-light-island]').backgroundColor,
      'rgb(255, 255, 255)',
    );
    assert.strictEqual(
      styles('[data-dark-island]').backgroundColor,
      'rgb(29, 30, 36)',
    );
    assert.strictEqual(
      styles('[data-emotion-showcase] a[href="#scoped-themes"]').color,
      'rgb(255, 255, 255)',
      'filled link label stays visible',
    );
    await click('[data-theme-dark]');
    assert.dom('[data-emotion-showcase]').hasAttribute('data-mode', 'dark');
    assert.dom('[data-theme-dark]').hasAttribute('aria-pressed', 'true');
    assert.strictEqual(
      styles('[data-save-changes]').backgroundColor,
      'rgb(121, 184, 255)',
    );
    assert.strictEqual(
      styles('[data-light-island] [data-island-primary]').backgroundColor,
      'rgb(0, 90, 158)',
    );
    assert.strictEqual(
      styles('[data-dark-island] [data-island-primary]').backgroundColor,
      'rgb(121, 184, 255)',
    );
    assert.strictEqual(
      styles('[data-light-island] p').color,
      'rgb(26, 28, 33)',
      'light panel text stays readable on a dark page',
    );
    await click('[data-theme-light]');
    assert.dom('[data-emotion-showcase]').hasAttribute('data-mode', 'light');
  });

  test('branding controls update only the nested preview and actions remain interactive', async function (assert) {
    await visit('/docs/emotion');
    assert.strictEqual(
      styles('[data-brand-primary]').backgroundColor,
      'rgb(102, 51, 153)',
    );
    await click('[data-brand-forest]');
    assert.strictEqual(
      styles('[data-brand-primary]').backgroundColor,
      'rgb(0, 107, 69)',
    );
    assert.strictEqual(
      styles('[data-save-changes]').backgroundColor,
      'rgb(0, 90, 158)',
    );
    assert.strictEqual(styles('[data-brand-primary]').borderRadius, '20px');
    await click('[data-rounded]');
    assert.strictEqual(styles('[data-brand-primary]').borderRadius, '4px');
    await click('[data-save-changes]');
    assert.dom('[data-save-count]').hasText('1 change saved');
  });
});
