import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { array, hash } from '@ember/helper';
import { click, fillIn, render, waitUntil } from '@ember/test-helpers';

import ValidatedForm from '#src/components/validated-form.gts';

const OPTIONS = [
  { value: 'mx', text: 'Mexico' },
  { value: 'pt', text: 'Portugal' }
];
const CHOICES = [
  { id: 'a', label: 'A' },
  { id: 'b', label: 'B' }
];

function recorder() {
  const values: unknown[] = [];

  return { values, onChange: (value: unknown) => values.push(value) };
}

module('Integration | Component | validated-form fields', function (hooks) {
  setupRenderingTest(hooks);

  test('FieldNumber, FieldPassword, FieldTextArea and FieldSelect report their value', async function (assert) {
    const number = recorder();
    const password = recorder();
    const textArea = recorder();
    const select = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldNumber @label="Age" @value={{1}} @onChange={{number.onChange}} class="number" />
          <Form.FieldPassword @label="Password" @onChange={{password.onChange}} class="password" />
          <Form.FieldTextArea @label="Bio" @onChange={{textArea.onChange}} class="bio" />
          <Form.FieldSelect @label="Country" @options={{OPTIONS}} @onChange={{select.onChange}} class="country" />
        </ValidatedForm>
      </template>
    );

    await fillIn('input.number', '42');
    await fillIn('input.password', 'secret');
    await fillIn('textarea.bio', 'Hello');
    await fillIn('select.country', 'pt');

    assert.deepEqual(number.values, ['42']);
    assert.deepEqual(password.values, ['secret']);
    assert.deepEqual(textArea.values, ['Hello']);
    assert.deepEqual(select.values, ['pt']);
    assert.dom('.euiFormRow__label').exists({ count: 4 });
  });

  test('FieldCheckboxGroup toggles ids in an array', async function (assert) {
    const checks = recorder();
    const selected = ['a'];

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldCheckboxGroup @label="Letters" @options={{CHOICES}} @value={{selected}} @onChange={{checks.onChange}} />
        </ValidatedForm>
      </template>
    );

    const inputs = [...(this.element as HTMLElement).querySelectorAll('input[type="checkbox"]:not(.fake-input-for-html-form-validity)')] as HTMLInputElement[];

    assert.true(inputs[0]!.checked);
    await click(inputs[1]!);
    assert.deepEqual(checks.values, [['a', 'b']]);
  });

  test('FieldRadioGroup selects a single id', async function (assert) {
    const radios = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldRadioGroup @label="Letter" @options={{CHOICES}} @value="a" @onChange={{radios.onChange}} />
        </ValidatedForm>
      </template>
    );

    const inputs = [...(this.element as HTMLElement).querySelectorAll('input[type="radio"]')] as HTMLInputElement[];

    assert.true(inputs[0]!.checked, 'the @value option is checked');
    await click(inputs[1]!);
    assert.deepEqual(radios.values, ['b']);
  });

  test('FieldSwitch reports checked', async function (assert) {
    const switches = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldSwitch @label="Notify" @value={{false}} @onChange={{switches.onChange}} />
        </ValidatedForm>
      </template>
    );

    await click('button.euiSwitch__button');
    assert.deepEqual(switches.values, [true]);
  });

  test('FieldComboBox reports the selected options', async function (assert) {
    const combo = recorder();
    const none: unknown[] = [];

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldComboBox @label="Countries" @options={{OPTIONS}} @selectedOptions={{none}} @searchField="text" @onChange={{combo.onChange}} as |option|>
            {{option.text}}
          </Form.FieldComboBox>
        </ValidatedForm>
      </template>
    );

    await click('input.euiComboBox__input:not(.fake-input-for-html-form-validity)');
    await waitUntil(() => document.querySelector('.euiComboBoxOptionsList button.euiFilterSelectItem'));
    const portugal = [...document.querySelectorAll('.euiComboBoxOptionsList button.euiFilterSelectItem')].find(
      (el) => el.textContent!.trim() === 'Portugal'
    )!;
    const { triggerEvent } = await import('@ember/test-helpers');

    await triggerEvent(portugal, 'mouseup');

    assert.deepEqual(combo.values, [[OPTIONS[1]]]);
  });

  test('FieldRangeSlider and FieldDualRangeSlider render ranges', async function (assert) {
    const range = recorder();
    const dual = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldRangeSlider @label="Volume" @min={{0}} @max={{10}} @value={{5}} @onChange={{range.onChange}} class="single" />
          <Form.FieldDualRangeSlider @label="Between" @min={{0}} @max={{10}} @value={{array 2 8}} @onChange={{dual.onChange}} @showInput={{true}} />
        </ValidatedForm>
      </template>
    );

    assert.dom('input[type="range"].single, .single input[type="range"], input[type="range"]').exists();
    await fillIn('input[type="range"]', '7');
    assert.ok(range.values.length >= 1, 'range change reported');

    await fillIn('input.euiRangeInput', '3');
    assert.ok(dual.values.length >= 1, 'dual range change reported');
  });

  test('FieldMarkdownEditor reports text', async function (assert) {
    const md = recorder();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldMarkdownEditor @label="Notes" @value="" @onChange={{md.onChange}} />
        </ValidatedForm>
      </template>
    );

    await fillIn('textarea', '**bold**');
    assert.deepEqual(md.values, ['**bold**']);
  });

  test('validation messages for select presence', async function (assert) {
    const noop = () => {};

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldSelect @label="Country" @options={{OPTIONS}} @hasNoInitialSelection={{true}} @onChange={{noop}} @validations={{hash presence=(hash presence=true)}} />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );
    
    await click('button[type="submit"]');

    assert.dom('.euiFormErrorText').hasText("This field can't be blank");
  });
});
