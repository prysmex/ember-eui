import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render } from '@ember/test-helpers';

import EuiButtonIcon from '#src/components/eui-button-icon.gts';

import type EuiConfigService from '#src/services/eui-config.ts';

module('Integration | Component | eui-button-icon', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders an icon button with an accessible label', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template><EuiButtonIcon @iconType="gear" aria-label="Settings" {{on "click" onClick}} /></template>
    );

    // Latest-only: no display/color/size modifier classes, and no aria-pressed
    // unless @isSelected is defined (upstream). Styles are covered in
    // eui-button-empty-icon-test.
    assert.dom('button.euiButtonIcon').hasAttribute('aria-label', 'Settings').doesNotHaveAttribute('aria-pressed');
    assert.strictEqual(getComputedStyle(this.element.querySelector('.euiButtonIcon')!).height, '24px', 'xs');
    assert.dom('button.euiButtonIcon svg.euiButtonIcon__icon').hasAttribute('aria-hidden', 'true');
    await click('button.euiButtonIcon');
    assert.strictEqual(clicks, 1);
  });

  test('display, color, size, selected, link and disabled', async function (assert) {
    await render(
      <template>
        <EuiButtonIcon @iconType="trash" @display="fill" @color="danger" @size="m" @isSelected={{true}} aria-label="a" class="fill" />
        <EuiButtonIcon @iconType="link" @href="#x" aria-label="b" class="link" />
        <EuiButtonIcon @iconType="link" @isDisabled={{true}} aria-label="c" class="disabled" />
      </template>
    );

    assert.dom('.fill').hasAttribute('aria-pressed', 'true');
    assert.strictEqual(getComputedStyle(this.element.querySelector('.fill')!).height, '40px', 'm');
    assert.notStrictEqual(getComputedStyle(this.element.querySelector('.fill')!).backgroundColor, 'rgba(0, 0, 0, 0)', 'fill');
    assert.dom('a.link').hasAttribute('href', '#x');
    assert.dom('button.disabled').isDisabled();
    assert.strictEqual(getComputedStyle(this.element.querySelector('.disabled')!).cursor, 'not-allowed');
  });

  test('the default size comes from the euiButtonIcon.size config', async function (assert) {
    const config = this.owner.lookup('service:eui-config') as EuiConfigService;

    config.updateConfig({ 'euiButtonIcon.size': 's' });

    await render(<template><EuiButtonIcon @iconType="gear" aria-label="Settings" /></template>);

    assert.strictEqual(getComputedStyle(this.element.querySelector('.euiButtonIcon')!).height, '32px', 'config size s');
  });
});
