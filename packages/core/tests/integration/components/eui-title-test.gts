import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiTitle from '#src/components/eui-title.gts';

module('Integration | Component | eui-title', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders an h2 by default', async function (assert) {
    await render(<template><EuiTitle>Title</EuiTitle></template>);

    assert.dom('h2.euiTitle').hasClass('euiTitle--medium').hasText('Title');
  });

  test('@tagName, @size and @textTransform', async function (assert) {
    await render(
      <template><EuiTitle @tagName="h1" @size="l" @textTransform="uppercase">Big</EuiTitle></template>
    );

    assert.dom('h1.euiTitle').hasClass('euiTitle--large').hasClass('euiTitle--uppercase');
  });
});
