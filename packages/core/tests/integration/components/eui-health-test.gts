import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiHealth from '#src/components/eui-health.gts';

module('Integration | Component | eui-health', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a colored dot and the label', async function (assert) {
    await render(<template><EuiHealth @color="success" @textSize="s">Healthy</EuiHealth></template>);

    assert.dom('.euiHealth').hasClass('euiHealth--textSizeS').hasText('Healthy');
    assert.dom('.euiHealth svg.euiIcon').hasClass('euiIcon--success');
  });
});
