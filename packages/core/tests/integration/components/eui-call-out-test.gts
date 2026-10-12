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
    // Upstream has no header wrapper: the title is a `p` by default.
    assert.dom('p.euiCallOutHeader__title').hasText('Heads up');
    assert.dom('.euiCallOut svg[aria-hidden="true"]').exists({ count: 1 }, 'the custom icon replaces the default one');
    assert.dom('.euiCallOut .euiNotificationIcon').doesNotExist();
    assert.dom('.euiCallOut .euiCallOut__additionalContent').hasText('Body text');
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

    // Upstream has no size modifier class; size is the `data-size` attribute.
    assert.dom('.euiCallOut').hasAttribute('data-size', 's');
    assert.dom('h3.euiCallOutHeader__title').hasText('Block title');
    assert.dom('.euiCallOut .euiCallOut__additionalContent').hasText('Block body');
  });
});
