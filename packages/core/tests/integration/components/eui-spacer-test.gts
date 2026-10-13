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

    assert.dom('.default').hasClass('euiBorealisSpacer');
    assert.strictEqual(
      getComputedStyle(this.element.querySelector('.default')!).blockSize,
      '24px'
    );
    assert.strictEqual(
      getComputedStyle(this.element.querySelector('.small')!).blockSize,
      '4px'
    );
  });
});
