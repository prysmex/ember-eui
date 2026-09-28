import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiScreenReaderOnly from '#src/components/eui-screen-reader-only.gts';

module('Integration | Component | eui-screen-reader-only', function (hooks) {
  setupRenderingTest(hooks);

  test('it hides its content visually', async function (assert) {
    await render(<template><EuiScreenReaderOnly class="sr">Sorted ascending</EuiScreenReaderOnly></template>);

    assert.dom('span.sr').hasClass('euiScreenReaderOnly').hasText('Sorted ascending');
  });

  test('@showOnFocus', async function (assert) {
    await render(
      <template>
        <EuiScreenReaderOnly @showOnFocus={{true}} class="sr"><a href="#main">Skip</a></EuiScreenReaderOnly>
      </template>
    );

    assert.dom('.sr').hasClass('euiScreenReaderOnly--showOnFocus').doesNotHaveClass('euiScreenReaderOnly');
    assert.dom('.sr a').exists();
  });
});
