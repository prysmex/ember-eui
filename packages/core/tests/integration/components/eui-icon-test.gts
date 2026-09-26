import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiIcon from '#src/components/eui-icon.gts';

module('Integration | Component | eui-icon', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a named EUI icon as an inline svg', async function (assert) {
    await render(<template><EuiIcon @type="arrowDown" /></template>);

    assert.dom('svg').exists();
    assert.dom('svg').hasClass('euiIcon');
    assert.dom('svg path').exists();
  });
});
