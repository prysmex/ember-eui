import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiSkipLink from '#src/components/eui-skip-link.gts';

module('Integration | Component | eui-skip-link', function (hooks) {
  setupRenderingTest(hooks);

  test('it links to the destination and shows on focus', async function (assert) {
    await render(<template><EuiSkipLink @destinationId="main">Skip to content</EuiSkipLink></template>);

    assert
      .dom('a.euiSkipLink')
      .hasAttribute('href', '#main')
      .hasText('Skip to content');
    // Legacy `euiSkipLink--static` / `euiScreenReaderOnly--showOnFocus`
    // classes are gone; hiding and focus reveal are asserted on computed
    // styles in eui-utilities-test.
    assert.strictEqual(getComputedStyle(document.querySelector('a.euiSkipLink')!).clipPath, 'inset(50%)');
  });

  test('a fixed link is always reachable with the keyboard', async function (assert) {
    await render(
      <template><EuiSkipLink @destinationId="main" @position="fixed" @tabIndex={{-1}}>Skip</EuiSkipLink></template>
    );

    assert.dom('a.euiSkipLink').hasAttribute('tabindex', '0');
    assert.strictEqual(getComputedStyle(document.querySelector('a.euiSkipLink')!).position, 'fixed');
  });
});
