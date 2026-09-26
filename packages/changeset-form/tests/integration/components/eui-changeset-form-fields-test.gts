import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { blur, click, fillIn, focus, render, settled, triggerEvent, waitUntil } from '@ember/test-helpers';

import { Changeset } from 'ember-changeset';
import lookupValidator from 'ember-changeset-validations';
import { validatePresence } from 'ember-changeset-validations/validators';

import EuiChangesetForm from '#src/components/eui-changeset-form.gts';
import FieldRadio from '#src/components/eui-changeset-form/fields/field-radio.gts';

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

module('Integration | Component | eui-changeset-form fields', function (hooks) {
  setupRenderingTest(hooks);

  test('FieldNumber, FieldPassword, FieldTextArea and FieldSelect set the changeset', async function (assert) {
    const changeset = Changeset({ age: 1, password: '', bio: '', country: 'mx' });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldNumber @fieldName="age" @label="Age" class="age" />
          <Form.FieldPassword @fieldName="password" @label="Password" class="password" />
          <Form.FieldTextArea @fieldName="bio" @label="Bio" class="bio" />
          <Form.FieldSelect @fieldName="country" @label="Country" @options={{OPTIONS}} class="country" />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('input.age').hasValue('1');
    assert.dom('select.country').hasValue('mx');

    await fillIn('input.age', '42');
    await fillIn('input.password', 'secret');
    await fillIn('textarea.bio', 'Hello');
    await fillIn('select.country', 'pt');

    assert.strictEqual(String(changeset.get('age')), '42');
    assert.strictEqual(changeset.get('password'), 'secret');
    assert.strictEqual(changeset.get('bio'), 'Hello');
    assert.strictEqual(changeset.get('country'), 'pt');
  });

  test('fields validate on blur and show the changeset errors', async function (assert) {
    const Validations = { bio: validatePresence(true), country: validatePresence(true) };
    const changeset = Changeset({ bio: '', country: '' }, lookupValidator(Validations), Validations);
    const empty = [{ value: '', text: 'Pick one' }, ...OPTIONS];

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldTextArea @fieldName="bio" @label="Bio" class="bio" />
          <Form.FieldSelect @fieldName="country" @label="Country" @options={{empty}} class="country" />
        </EuiChangesetForm>
      </template>
    );

    await focus('textarea.bio');
    await blur('textarea.bio');
    await focus('select.country');
    await blur('select.country');
    await settled();

    const errors = [...document.querySelectorAll('.euiFormErrorText')].map((e) => e.textContent!.trim());

    assert.deepEqual(errors, ["Bio can't be blank", "Country can't be blank"]);
  });

  test('FieldSwitch sets a boolean', async function (assert) {
    const changeset = Changeset({ notify: false });
    const changes = recorder();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldSwitch @fieldName="notify" @label="Notify" @onChange={{changes.onChange}} />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('button.euiSwitch__button').hasAttribute('aria-checked', 'false');
    await click('button.euiSwitch__button');
    assert.true(changeset.get('notify'));
    assert.deepEqual(changes.values, [true]);
    assert.dom('button.euiSwitch__button').hasAttribute('aria-checked', 'true');
  });

  test('FieldRadioGroup selects a single id', async function (assert) {
    const changeset = Changeset({ letter: 'a' });
    const changes = recorder();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldRadioGroup @fieldName="letter" @label="Letter" @options={{CHOICES}} @onChange={{changes.onChange}} />
        </EuiChangesetForm>
      </template>
    );

    const inputs = () => [...(this.element as HTMLElement).querySelectorAll('input[type="radio"]')] as HTMLInputElement[];

    assert.true(inputs()[0]!.checked);
    await click(inputs()[1]!);
    assert.strictEqual(changeset.get('letter'), 'b');
    assert.deepEqual(changes.values, ['b']);
    assert.true(inputs()[1]!.checked);
  });

  // Bug: the value getter calls `changeset.get(field)?.toArray()`, which
  // throws for plain arrays (no Ember array prototype extensions)
  test.todo('FieldCheckboxGroup toggles ids in an array', async function (assert) {
    const changeset = Changeset({ letters: ['a'] });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldCheckboxGroup @fieldName="letters" @label="Letters" @options={{CHOICES}} />
        </EuiChangesetForm>
      </template>
    );

    const inputs = () => [...(this.element as HTMLElement).querySelectorAll('input[type="checkbox"]')] as HTMLInputElement[];

    assert.true(inputs()[0]!.checked);
    await click(inputs()[1]!);
    assert.deepEqual(changeset.get('letters'), ['a', 'b']);
    await click(inputs()[0]!);
    assert.deepEqual(changeset.get('letters'), ['b']);
    assert.false(inputs()[0]!.checked);
  });

  test('FieldComboBox reports the selected options', async function (assert) {
    const changeset = Changeset({ countries: [] });
    const combo = recorder();
    const none: unknown[] = [];

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldComboBox @fieldName="countries" @label="Countries" @options={{OPTIONS}} @selectedOptions={{none}} @searchField="text" @onChange={{combo.onChange}} as |option|>
            {{option.text}}
          </Form.FieldComboBox>
        </EuiChangesetForm>
      </template>
    );

    await click('input.euiComboBox__input:not(.fake-input-for-html-form-validity)');
    await waitUntil(() => document.querySelector('.euiComboBoxOptionsList button.euiFilterSelectItem'));
    const portugal = [...document.querySelectorAll('.euiComboBoxOptionsList button.euiFilterSelectItem')].find(
      (el) => el.textContent!.trim() === 'Portugal'
    )!;

    await triggerEvent(portugal, 'mouseup');

    assert.deepEqual(combo.values, [[OPTIONS[1]]]);
  });

  test('FieldRangeSlider and FieldDualRangeSlider set the changeset', async function (assert) {
    const changeset = Changeset({ volume: 5, between: [2, 8] });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldRangeSlider @fieldName="volume" @label="Volume" @min={{0}} @max={{10}} />
          <Form.FieldDualRangeSlider @fieldName="between" @label="Between" @min={{0}} @max={{10}} @showInput={{true}} />
        </EuiChangesetForm>
      </template>
    );

    await fillIn('input[type="range"]', '7');
    assert.strictEqual(String(changeset.get('volume')), '7');

    await fillIn('input.euiRangeInput', '3');
    assert.deepEqual((changeset.get('between') as unknown[]).map(String), ['3', '8']);
  });

  test('Form.FieldCheckbox renders a checkbox that sets a boolean', async function (assert) {
    const changeset = Changeset({ agree: false });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldCheckbox @fieldName="agree" @label="I agree" />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('input[type="checkbox"]').exists();
    await click('input[type="checkbox"]');
    assert.true(changeset.get('agree'));
    assert.dom('input[type="checkbox"]').isChecked();
  });

  test('Form.FieldRadio renders a radio that sets a boolean', async function (assert) {
    const changeset = Changeset({ yes: false });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldRadio @fieldName="yes" @label="Answer" @radioLabel="Yes" />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('input[type="radio"]').exists();
    await click('input[type="radio"]');
    assert.true(changeset.get('yes'));
  });

  test('FieldRadio reflects the changeset value', async function (assert) {
    const changeset = Changeset({ yes: true });

    await render(
      <template>
        <FieldRadio @changeset={{changeset}} @fieldName="yes" @label="Answer" @radioLabel="Yes" />
      </template>
    );

    assert.dom('input[type="radio"]').isChecked();
  });
});
