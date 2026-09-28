import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiToken from '#src/components/eui-token.gts';

module('Integration | Component | eui-token', function (hooks) {
  setupRenderingTest(hooks);

  test('token icons come with their own shape and color', async function (assert) {
    await render(<template><EuiToken @iconType="tokenString" @title="String" /></template>);

    assert
      .dom('.euiToken')
      .hasClass('euiToken--square')
      .hasClass('euiToken--euiColorVis1')
      .hasClass('euiToken--light')
      .hasClass('euiToken--small');
    assert.dom('.euiToken .euiIcon').hasClass('euiIcon--medium', 'token icons are one size up at the small size');
  });

  test('shape, fill, color and size override the preset', async function (assert) {
    await render(
      <template><EuiToken @iconType="tokenString" @shape="circle" @fill="dark" @color="euiColorVis5" @size="l" /></template>
    );

    assert
      .dom('.euiToken')
      .hasClass('euiToken--circle')
      .hasClass('euiToken--dark')
      .hasClass('euiToken--euiColorVis5')
      .hasClass('euiToken--large');
  });

  test('a custom color is a solid background with readable text', async function (assert) {
    await render(
      <template>
        <EuiToken class="dark" @iconType="bolt" @color="#000000" />
        <EuiToken class="none" @iconType="bolt" @color="#ff0000" @fill="none" />
      </template>
    );

    assert.dom('.dark').hasClass('euiToken--dark').hasStyle({ backgroundColor: 'rgb(0, 0, 0)', color: 'rgb(255, 255, 255)' });
    assert.dom('.none').hasStyle({ color: 'rgb(255, 0, 0)' });
    assert.dom('.none').doesNotHaveClass('euiToken--dark');
  });
});
