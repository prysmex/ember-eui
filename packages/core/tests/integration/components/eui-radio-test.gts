import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiRadio from '#src/components/eui-radio.gts';
import EuiRadioGroup from '#src/components/eui-radio-group.gts';

const OPTIONS = [
  { id: 'small', label: 'Small', value: 's' },
  { id: 'large', label: 'Large', value: 'l' },
  { id: 'huge', label: 'Huge', value: 'h', disabled: true }
];

module('Integration | Component | eui-radio', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiRadio renders a labelled radio', async function (assert) {
    await render(
      <template>
        <EuiRadio @id="r1" @name="size" @label="Medium" @checked={{true}} />
        <EuiRadio @id="r2" @name="size" @disabled={{true}} @compressed={{true}} />
      </template>
    );

    assert.dom('#r1[type="radio"]').isChecked().hasAttribute('name', 'size');
    assert.dom('label[for="r1"]').hasClass('euiRadio__label').hasText('Medium');
    assert.dom('#r2').isDisabled();
    assert.dom('.euiRadio--noLabel.euiRadio--compressed #r2').exists();
  });

  test('EuiRadioGroup checks @idSelected and calls @onChange(id, value)', async function (assert) {
    class State {
      @tracked idSelected = 'small';
    }
    const state = new State();
    const calls: string[][] = [];
    const onChange = (id: string, value: string) => {
      calls.push([id, value]);
      state.idSelected = id;
    };

    await render(
      <template><EuiRadioGroup @name="size" @options={{OPTIONS}} @idSelected={{state.idSelected}} @onChange={{onChange}} /></template>
    );

    const inputs = () => [...document.querySelectorAll('input.euiRadioGroup__item')] as HTMLInputElement[];

    assert.strictEqual(inputs().length, 3);
    assert.true(inputs()[0]!.checked);
    assert.true(inputs()[2]!.disabled);

    await click(inputs()[1]!);

    assert.deepEqual(calls, [['large', 'l']]);
    assert.true(inputs()[1]!.checked);
  });

  test('EuiRadioGroup keeps an option className as a separate class', async function (assert) {
    const options = [{ id: 'x', label: 'X', className: 'custom' }];
    const noop = () => {};

    await render(<template><EuiRadioGroup @idSelected="x" @options={{options}} @onChange={{noop}} /></template>);

    assert.dom('input.euiRadioGroup__item').hasClass('custom');
  });

  test('EuiRadioGroup names its radios, also with a @legend', async function (assert) {
    const options = [
      { id: 'a', label: 'A' },
      { id: 'b', label: 'B' }
    ];
    const noop = () => {};

    await render(
      <template>
        <div class="named">
          <EuiRadioGroup @options={{options}} @name="letters" @legend="Letters" @onChange={{noop}} />
        </div>
        <div class="generated">
          <EuiRadioGroup @options={{options}} @onChange={{noop}} />
        </div>
      </template>
    );

    assert.dom('.named input[type="radio"][name="letters"]').exists({ count: 2 });

    const names = [...document.querySelectorAll<HTMLInputElement>('.generated input[type="radio"]')].map(
      (input) => input.name
    );

    assert.ok(names[0], 'a name is generated');
    assert.strictEqual(names[0], names[1], 'shared by the group');
  });
});
