import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiSwitch from '#src/components/eui-switch.gts';

module('Integration | Component | eui-switch', function (hooks) {
  setupRenderingTest(hooks);

  test('it toggles through @onChange, from the button and the label', async function (assert) {
    class State {
      @tracked checked = false;
      onChange = (e: Event) => (this.checked = (e.target as HTMLInputElement).checked);
    }
    const state = new State();

    await render(<template><EuiSwitch @label="Dark mode" @checked={{state.checked}} @onChange={{state.onChange}} /></template>);

    assert.dom('button.euiSwitch__button').hasAttribute('role', 'switch').hasAttribute('aria-checked', 'false');
    assert.dom('button').hasAttribute('aria-labelledby', document.querySelector('.euiSwitch__label')!.id);

    await click('button.euiSwitch__button');
    assert.true(state.checked);
    assert.dom('button').hasAttribute('aria-checked', 'true');

    await click('.euiSwitch__label');
    assert.false(state.checked);
  });

  test('disabled switches do not change', async function (assert) {
    let calls = 0;
    const onChange = () => calls++;

    await render(<template><EuiSwitch @label="Off" @checked={{false}} @disabled={{true}} @onChange={{onChange}} /></template>);

    assert.dom('button').isDisabled();
    await click('.euiSwitch__label');
    assert.strictEqual(calls, 0);
  });

  test('@showLabel={{false}} uses the label as aria-label; compressed has no icons', async function (assert) {
    await render(<template><EuiSwitch @label="Hidden" @showLabel={{false}} @checked={{true}} @compressed={{true}} /></template>);

    assert.dom('.euiSwitch').hasClass('euiSwitch--compressed');
    assert.dom('button').hasAttribute('aria-label', 'Hidden').doesNotHaveAttribute('aria-labelledby');
    assert.dom('.euiSwitch__label').doesNotExist();
    assert.dom('.euiSwitch__icon').doesNotExist();
  });
});
