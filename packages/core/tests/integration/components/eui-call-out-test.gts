import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiCallOut from '#src/components/eui-call-out.gts';

module('Integration | Component | eui-call-out', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders title, icon and body', async function (assert) {
    await render(
      <template>
        <EuiCallOut @title="Heads up" @iconType="help" @color="warning">Body text</EuiCallOut>
      </template>
    );

    assert.dom('.euiCallOut').hasClass('euiCallOut--warning');
    assert.dom('.euiCallOutHeader__title').hasText('Heads up');
    assert.dom('.euiCallOutHeader svg.euiCallOutHeader__icon').exists();
    assert.dom('.euiCallOut .euiText').hasText('Body text');
  });

  test('named blocks and @heading', async function (assert) {
    await render(
      <template>
        <EuiCallOut @heading="h3" @size="s">
          <:title>Block title</:title>
          <:body>Block body</:body>
        </EuiCallOut>
      </template>
    );

    assert.dom('.euiCallOut').hasClass('euiCallOut--small');
    assert.dom('h3.euiCallOutHeader__title').hasText('Block title');
    assert.dom('.euiCallOut .euiText').hasText('Block body');
  });
});
