import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiText from '#src/components/eui-text.gts';
import EuiTextAlign from '#src/components/eui-text-align.gts';
import EuiTextColor from '#src/components/eui-text-color.gts';

module('Integration | Component | eui-text', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a div with its content and forwarded attributes', async function (assert) {
    await render(
      <template>
        <EuiText @size="s" @grow={{false}} data-test-text>
          <p>Hello</p>
        </EuiText>
      </template>
    );

    assert.dom('div.euiText[data-test-text]').exists({ count: 1 });
    assert.dom('.euiText > p').hasText('Hello');
    assert
      .dom('.euiText')
      .doesNotHaveClass('euiText--small')
      .doesNotHaveClass('euiText--constrainedWidth');
  });

  test('@textAlign and @color compose on one element without wrappers', async function (assert) {
    await render(
      <template>
        <EuiText @textAlign="center" @color="danger" data-test-text>Alert</EuiText>
      </template>
    );

    assert.dom('div.euiText[data-test-text]').hasText('Alert');
    assert.dom('.euiText *').doesNotExist('no nested align/color wrappers');
    assert.dom('.euiTextAlign').doesNotExist();
    assert.dom('.euiTextColor').doesNotExist();
  });

  test('EuiTextColor and EuiTextAlign on their own', async function (assert) {
    await render(
      <template>
        <EuiTextColor @color="subdued" data-test-span>span</EuiTextColor>
        <EuiTextColor @color="accent" @tagName="div" data-test-div>div</EuiTextColor>
        <EuiTextColor @color="danger" @tagName="p" data-test-p>p</EuiTextColor>
        <EuiTextAlign @textAlign="right" data-test-align>right</EuiTextAlign>
        <EuiTextAlign @tagName="span" data-test-align-span>inline</EuiTextAlign>
      </template>
    );

    assert.dom('span.euiTextColor[data-test-span]').hasText('span');
    assert.dom('div.euiTextColor[data-test-div]').hasText('div');
    assert.dom('p.euiTextColor[data-test-p]').hasText('p');
    assert.dom('div.euiTextAlign[data-test-align]').hasText('right');
    assert.dom('span.euiTextAlign[data-test-align-span]').hasText('inline');
    assert.dom('.euiTextColor--subdued').doesNotExist();
    assert.dom('.euiTextAlign--right').doesNotExist();
  });
});
