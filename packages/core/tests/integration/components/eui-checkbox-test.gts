import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiCheckbox from '#src/components/eui-checkbox.gts';
import EuiCheckboxGroup from '#src/components/eui-checkbox-group.gts';

const OPTIONS = [
  { id: 'a', label: 'Apple' },
  { id: 'b', label: 'Banana' },
  { id: 'c', label: 'Cherry', disabled: true }
];

module('Integration | Component | eui-checkbox', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a labelled checkbox and reports changes', async function (assert) {
    const changes: boolean[] = [];
    const onChange = (e: Event) => changes.push((e.target as HTMLInputElement).checked);

    await render(<template><EuiCheckbox @id="agree" @label="I agree" {{on "change" onChange}} /></template>);

    assert.dom('.euiCheckbox input#agree[type="checkbox"]').isNotChecked();
    assert.dom('label.euiCheckbox__label').hasAttribute('for', 'agree').hasText('I agree');

    await click('label.euiCheckbox__label');
    assert.deepEqual(changes, [true]);
  });

  test('checked, disabled, compressed, no label and indeterminate', async function (assert) {
    await render(
      <template>
        <EuiCheckbox @checked={{true}} @label="On" @compressed={{true}} class="on" />
        <EuiCheckbox @disabled={{true}} class="off" />
        <EuiCheckbox @indeterminate={{true}} @label="Some" class="some" />
      </template>
    );

    assert.dom('input.on').isChecked();
    assert.dom('.euiCheckbox--compressed input.on').exists();
    assert.dom('input.off').isDisabled();
    assert.dom('.euiCheckbox--noLabel input.off').exists();
    assert.true((document.querySelector('input.some') as HTMLInputElement).indeterminate);
  });

  test('a label block', async function (assert) {
    await render(<template><EuiCheckbox><:label><strong>Bold</strong></:label></EuiCheckbox></template>);

    assert.dom('.euiCheckbox__label strong').hasText('Bold');
  });

  test('EuiCheckboxGroup reflects @idToSelectedMap and calls @onChange(id)', async function (assert) {
    class State {
      @tracked selected: Record<string, boolean> = { a: true };
    }
    const state = new State();
    const ids: string[] = [];
    const onChange = (id: string) => {
      ids.push(id);
      state.selected = { ...state.selected, [id]: !state.selected[id] };
    };

    await render(
      <template>
        <EuiCheckboxGroup @options={{OPTIONS}} @idToSelectedMap={{state.selected}} @onChange={{onChange}} @legend="Fruits" />
      </template>
    );

    assert.dom('fieldset legend').hasText('Fruits');
    const inputs = () => [...document.querySelectorAll('input.euiCheckboxGroup__item')] as HTMLInputElement[];

    assert.strictEqual(inputs().length, 3);
    assert.true(inputs()[0]!.checked);
    assert.true(inputs()[2]!.disabled);

    await click(inputs()[1]!);

    assert.deepEqual(ids, ['b']);
    assert.true(inputs()[1]!.checked);
  });

  // Bug: the item class is built with (concat "euiCheckboxGroup__item" option.className),
  // without a space, so a custom className is glued to it
  test.todo('EuiCheckboxGroup keeps an option className as a separate class', async function (assert) {
    const options = [{ id: 'x', label: 'X', className: 'custom' }];
    const noop = () => {};

    await render(<template><EuiCheckboxGroup @options={{options}} @onChange={{noop}} /></template>);

    assert.dom('input.euiCheckboxGroup__item').hasClass('custom');
  });
});
