import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiBetaBadge from '#src/components/eui-beta-badge.gts';

module('Integration | Component | eui-beta-badge', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the label', async function (assert) {
    await render(<template><EuiBetaBadge @label="Beta" /></template>);

    assert.dom('.euiBetaBadge').hasText('Beta').hasClass('euiBetaBadge--hollow');
  });

  test('single letter, color and size', async function (assert) {
    await render(<template><EuiBetaBadge @label="B" @color="accent" @size="s" /></template>);

    assert.dom('.euiBetaBadge').hasClass('euiBetaBadge--singleLetter').hasClass('euiBetaBadge--accent').hasClass('euiBetaBadge--small');
  });

  test('@iconType renders an icon only badge', async function (assert) {
    await render(<template><EuiBetaBadge @label="Lab" @iconType="beaker" /></template>);

    assert.dom('.euiBetaBadge').hasClass('euiBetaBadge--iconOnly');
    assert.dom('.euiBetaBadge svg.euiBetaBadge__icon').exists();
  });

  test('@onClick and @href make it clickable', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiBetaBadge @label="Click" @onClick={{onClick}} class="button-badge" />
        <EuiBetaBadge @label="Link" @href="#beta" class="link-badge" />
      </template>
    );

    assert.dom('button.button-badge').hasClass('euiBetaBadge-isClickable');
    await click('button.button-badge');
    assert.strictEqual(clicks, 1);
    assert.dom('a.link-badge').hasAttribute('href', '#beta');
  });
});
