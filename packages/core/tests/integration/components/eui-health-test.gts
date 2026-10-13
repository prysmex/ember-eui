import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiHealth from '#src/components/eui-health.gts';

module('Integration | Component | eui-health', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a colored dot and the label', async function (assert) {
    await render(<template><EuiHealth @color="success" @textSize="s">Healthy</EuiHealth></template>);

    // legacy euiHealth--textSizeS / euiIcon--success classes are upstream
    // emotion styles now; the family test checks the computed values
    assert.dom('.euiHealth').hasText('Healthy');
    assert.dom('.euiHealth svg.euiIcon').hasAttribute('data-icon-type', 'dot');
  });
});
