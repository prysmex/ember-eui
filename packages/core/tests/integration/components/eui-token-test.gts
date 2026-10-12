import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiToken from '#src/components/eui-token.gts';

module('Integration | Component | eui-token', function (hooks) {
  setupRenderingTest(hooks);

  test('token icons come with their own shape and color', async function (assert) {
    await render(<template><EuiToken @iconType="tokenString" @title="String" /></template>);

    // legacy euiToken--square/--euiColorVis1/--light/--small classes are now
    // upstream emotion styles: assert what they render
    const token = getComputedStyle(this.element.querySelector('.euiToken')!);
    assert.strictEqual(token.borderRadius, '4px', 'square');
    assert.strictEqual(token.width, '16px', 'small');
    assert.notStrictEqual(token.backgroundColor, 'rgba(0, 0, 0, 0)', 'light fill');
    assert.dom('.euiToken .euiIcon').hasStyle({ width: '16px' }, 'token icons are one size up at the small size (m), capped by the token');
    assert.dom('.euiToken .euiIcon').hasAttribute('role', 'img');
  });

  test('shape, fill, color and size override the preset', async function (assert) {
    await render(
      <template><EuiToken @iconType="tokenString" @shape="circle" @fill="dark" @color="euiColorVis5" @size="l" /></template>
    );

    const token = getComputedStyle(this.element.querySelector('.euiToken')!);
    assert.strictEqual(token.borderRadius, '50%', 'circle');
    assert.strictEqual(token.width, '32px', 'large');
    // dark fill: the vis color itself behind the text
    assert.strictEqual(token.backgroundColor, 'rgb(255, 199, 219)', 'euiColorVis5 dark');
  });

  test('a custom color is a solid background with readable text', async function (assert) {
    await render(
      <template>
        <EuiToken class="dark" @iconType="bolt" @color="#000000" />
        <EuiToken class="none" @iconType="bolt" @color="#ff0000" @fill="none" />
      </template>
    );

    assert.dom('.dark').hasStyle({ backgroundColor: 'rgb(0, 0, 0)', color: 'rgb(255, 255, 255)' });
    assert.dom('.none').hasStyle({ color: 'rgb(255, 0, 0)', backgroundColor: 'rgba(0, 0, 0, 0)' });
  });
});
