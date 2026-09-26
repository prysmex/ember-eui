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

    assert.dom('button.euiButtonIcon').hasClass('euiButtonIcon--empty').hasClass('euiButtonIcon--primary').hasClass('euiButtonIcon--xSmall').hasAttribute('aria-label', 'Settings').hasAttribute('aria-pressed', 'false');
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

    assert.dom('.fill').hasClass('euiButtonIcon--fill').hasClass('euiButtonIcon--danger').hasClass('euiButtonIcon--medium').hasAttribute('aria-pressed', 'true');
    assert.dom('a.link').hasAttribute('href', '#x');
    assert.dom('button.disabled').isDisabled().hasClass('euiButtonIcon-isDisabled');
  });

  test('the default size comes from the euiButtonIcon.size config', async function (assert) {
    const config = this.owner.lookup('service:eui-config') as EuiConfigService;

    config.updateConfig({ 'euiButtonIcon.size': 's' });

    await render(<template><EuiButtonIcon @iconType="gear" aria-label="Settings" /></template>);

    assert.dom('.euiButtonIcon').hasClass('euiButtonIcon--small');
  });
});
