import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiBadge from '#src/components/eui-badge.gts';

module('Integration | Component | eui-badge', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a default badge', async function (assert) {
    await render(<template><EuiBadge>Default</EuiBadge></template>);

    assert.dom('.euiBadge').hasText('Default');
    assert.dom('.euiBadge .euiBadge__text').exists();
  });

  test('named colors get a class, custom colors an inline background', async function (assert) {
    await render(
      <template>
        <EuiBadge @color="hollow" class="hollow">Hollow</EuiBadge>
        <EuiBadge @color="#ff0000" class="custom">Custom</EuiBadge>
      </template>
    );

    assert.dom('.hollow').hasClass('euiBadge--hollow');
    assert.dom('.custom').hasStyle({ backgroundColor: 'rgb(255, 0, 0)' });
  });

  test('@onClick renders a button', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template><EuiBadge @onClick={{onClick}} @onClickAriaLabel="Open">Click</EuiBadge></template>
    );

    assert.dom('button.euiBadge').hasClass('euiBadge-isClickable').hasAttribute('aria-label', 'Open');
    await click('button.euiBadge');
    assert.strictEqual(clicks, 1);
  });

  test('@href renders a link', async function (assert) {
    await render(<template><EuiBadge @href="#here">Link</EuiBadge></template>);

    assert.dom('a.euiBadge').hasAttribute('href', '#here');
  });

  test('@href with @iconType keeps @target', async function (assert) {
    await render(
      <template>
        <EuiBadge @href="https://example.com" @target="_blank" @iconType="check">Docs</EuiBadge>
      </template>
    );

    assert.dom('a.euiBadge__childButton').hasAttribute('href', 'https://example.com');
    assert.dom('a.euiBadge__childButton').hasAttribute('target', '_blank');
  });

  test('@iconType with @iconSide', async function (assert) {
    await render(<template><EuiBadge @iconType="check" @iconSide="right">Done</EuiBadge></template>);

    assert.dom('.euiBadge').hasClass('euiBadge--iconRight');
    assert.dom('.euiBadge svg.euiIcon').exists();
  });

  test('a disabled badge with @href is a disabled button, as links cannot be disabled', async function (assert) {
    await render(
      <template>
        <EuiBadge @href="#here" @isDisabled={{true}} class="plain">Off</EuiBadge>
        <EuiBadge @href="#here" @isDisabled={{true}} @iconType="check" class="icon">Off</EuiBadge>
      </template>
    );

    assert.dom('button.plain').isDisabled().hasClass('euiBadge-isDisabled');
    assert.dom('.icon button.euiBadge__childButton').isDisabled();
    assert.dom('a').doesNotExist();
  });
});
