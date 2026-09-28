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
      .hasClass('euiSkipLink--static')
      .hasClass('euiScreenReaderOnly--showOnFocus')
      .hasClass('euiButton--fill')
      .hasText('Skip to content');
  });

  test('a fixed link is always reachable with the keyboard', async function (assert) {
    await render(
      <template><EuiSkipLink @destinationId="main" @position="fixed" @tabIndex={{-1}}>Skip</EuiSkipLink></template>
    );

    assert.dom('a.euiSkipLink').hasClass('euiSkipLink--fixed').hasAttribute('tabindex', '0');
  });
});
