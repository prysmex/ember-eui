import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiTitle from '#src/components/eui-title.gts';

module('Integration | Component | eui-title', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders an h2 by default', async function (assert) {
    await render(<template><EuiTitle>Title</EuiTitle></template>);

    assert.dom('h2.euiTitle').hasText('Title');
    assert.dom('.euiTitle').doesNotHaveClass('euiTitle--medium');
  });

  test('@tagName, @size, @textTransform and forwarded attributes', async function (assert) {
    await render(
      <template>
        <EuiTitle @tagName="h1" @size="l" @textTransform="uppercase" id="big" class="extra">Big</EuiTitle>
      </template>
    );

    assert.dom('h1.euiTitle#big').hasClass('extra').hasText('Big');
    assert
      .dom('h1.euiTitle')
      .doesNotHaveClass('euiTitle--large')
      .doesNotHaveClass('euiTitle--uppercase');
    assert.dom('h2').doesNotExist();
  });
});
