import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiHorizontalRule from '#src/components/eui-horizontal-rule.gts';

module('Integration | Component | eui-horizontal-rule', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders an hr with size and margin', async function (assert) {
    await render(
      <template>
        <EuiHorizontalRule class="default" />
        <EuiHorizontalRule @size="half" @margin="xs" class="custom" />
      </template>
    );

    assert.dom('hr.default').hasClass('euiHorizontalRule--full').hasClass('euiHorizontalRule--marginLarge');
    assert.dom('hr.custom').hasClass('euiHorizontalRule--half').hasClass('euiHorizontalRule--marginXSmall');
  });
});
