import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiSpacer from '#src/components/eui-spacer.gts';

module('Integration | Component | eui-spacer', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a spacer of the given size', async function (assert) {
    await render(
      <template>
        <EuiSpacer class="default" />
        <EuiSpacer @size="xs" class="small" />
      </template>
    );

    assert.dom('.default').hasClass('euiSpacer').hasClass('euiSpacer--l');
    assert.dom('.small').hasClass('euiSpacer--xs');
  });
});
