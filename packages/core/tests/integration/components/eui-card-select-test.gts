import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiCardSelect from '#src/components/eui-card-select.gts';
import EuiCheckableCard from '#src/components/eui-checkable-card.gts';

module('Integration | Component | eui-card-select / checkable-card', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiCardSelect is a switch with a default label per state', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiCardSelect @onClick={{onClick}} class="idle" />
        <EuiCardSelect @isSelected={{true}} class="selected" />
        <EuiCardSelect @isDisabled={{true}} class="disabled" />
      </template>
    );

    assert.dom('.idle').hasAttribute('role', 'switch').hasAttribute('aria-checked', 'false').hasText('Select');
    assert.dom('.selected').hasAttribute('aria-checked', 'true').hasText('Selected');
    assert.dom('.selected svg.euiIcon').exists('check icon');
    assert.dom('.disabled').isDisabled().hasText('Unavailable');

    await click('.idle');
    assert.strictEqual(clicks, 1);
  });

  test('EuiCheckableCard wraps a radio or checkbox with a label', async function (assert) {
    await render(
      <template>
        <EuiCheckableCard @id="card-radio" @label="Radio card" @checked={{true}} />
        <EuiCheckableCard @id="card-check" @checkableType="checkbox" @label="Checkbox card" @disabled={{true}} />
      </template>
    );

    assert.dom('input#card-radio[type="radio"]').isChecked();
    assert.dom('label[for="card-radio"]').hasText('Radio card');
    assert.dom('.euiCheckableCard-isChecked input#card-radio').exists();
    assert.dom('input#card-check[type="checkbox"]').isDisabled();
    assert.dom('label[for="card-check"]').hasClass('euiCheckableCard__label-isDisabled');
  });
});
