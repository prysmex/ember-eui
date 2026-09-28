import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiBeacon from '#src/components/eui-beacon.gts';

module('Integration | Component | eui-beacon', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a dot of the given size', async function (assert) {
    await render(
      <template>
        <EuiBeacon class="default" />
        <EuiBeacon @size={{20}} class="big" />
      </template>
    );

    assert.dom('.default').hasClass('euiBeacon').hasStyle({ width: '12px', height: '12px' });
    assert.dom('.big').hasStyle({ width: '20px', height: '20px' });
  });
});
