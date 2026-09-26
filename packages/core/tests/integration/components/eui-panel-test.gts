import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiPanel from '#src/components/eui-panel.gts';

module('Integration | Component | eui-panel', function (hooks) {
  setupRenderingTest(hooks);

  test('default plain panel with shadow and medium padding', async function (assert) {
    await render(<template><EuiPanel>Content</EuiPanel></template>);

    assert.dom('.euiPanel').hasClass('euiPanel--plain').hasClass('euiPanel--hasShadow').hasClass('euiPanel--paddingMedium').hasClass('euiPanel--borderRadiusMedium').hasText('Content');
  });

  test('color, padding, border radius, border and grow', async function (assert) {
    await render(
      <template>
        <EuiPanel @color="subdued" @hasShadow={{false}} @paddingSize="l" @borderRadius="none" @grow={{false}} class="a" />
        <EuiPanel @hasBorder={{true}} class="b" />
      </template>
    );

    assert.dom('.a').hasClass('euiPanel--subdued').hasClass('euiPanel--noShadow').hasClass('euiPanel--paddingLarge').hasClass('euiPanel--borderRadiusNone').hasClass('euiPanel--flexGrowZero').doesNotHaveClass('euiPanel--hasShadow');
    assert.dom('.b').hasClass('euiPanel--hasBorder');
  });

  test('@onClick makes it a clickable button', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(<template><EuiPanel @onClick={{onClick}}>Click</EuiPanel></template>);

    assert.dom('.euiPanel').hasAttribute('role', 'button').hasClass('euiPanel--isClickable');
    await click('.euiPanel');
    assert.strictEqual(clicks, 1);
  });
});
