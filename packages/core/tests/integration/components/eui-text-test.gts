import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiText from '#src/components/eui-text.gts';
import EuiTextAlign from '#src/components/eui-text-align.gts';
import EuiTextColor from '#src/components/eui-text-color.gts';

module('Integration | Component | eui-text', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders with size and grow', async function (assert) {
    await render(<template><EuiText @size="s" @grow={{false}}><p>Hello</p></EuiText></template>);

    assert.dom('.euiText').hasClass('euiText--small').hasClass('euiText--constrainedWidth');
    assert.dom('.euiText p').hasText('Hello');
  });

  test('@textAlign and @color wrap the content', async function (assert) {
    await render(<template><EuiText @textAlign="center" @color="danger">Alert</EuiText></template>);

    assert.dom('.euiText .euiTextAlign--center div.euiTextColor--danger').hasText('Alert');
  });

  test('EuiTextColor and EuiTextAlign on their own', async function (assert) {
    await render(
      <template>
        <EuiTextColor @color="subdued">span</EuiTextColor>
        <EuiTextColor @color="accent" @tagName="div">div</EuiTextColor>
        <EuiTextAlign @textAlign="right">right</EuiTextAlign>
      </template>
    );

    assert.dom('span.euiTextColor--subdued').hasText('span');
    assert.dom('div.euiTextColor--accent').hasText('div');
    assert.dom('.euiTextAlign--right').hasText('right');
  });
});
