import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { hash } from '@ember/helper';
import { blur, click, fillIn, focus, render, settled, triggerEvent } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import ValidatedForm from '#src/components/validated-form.gts';

class Data {
  @tracked text = '';
  @tracked email = 'not-an-email';
  submits = 0;
  invalids = 0;
  resets = 0;
  setText = (v: string) => (this.text = v);
  setEmail = (v: string) => (this.email = v);
  onSubmit = () => this.submits++;
  onInvalid = () => this.invalids++;
  onReset = () => this.resets++;
}

// field validation is recalculated in a `later` after value changes
const wait = () => settled();

module('Integration | Component | validated-form', function (hooks) {
  setupRenderingTest(hooks);

  test('submitting an invalid form shows the errors and calls @onInvalid', async function (assert) {
    const data = new Data();

    await render(
      <template>
        <ValidatedForm @onSubmit={{data.onSubmit}} @onInvalid={{data.onInvalid}} as |Form|>
          <Form.FieldText @label="Name" @value={{data.text}} @onChange={{data.setText}} @validations={{hash presence=(hash presence=true)}} />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );
    await wait();

    assert.dom('form.euiForm').exists();
    assert.dom('.euiFormErrorText').doesNotExist('untouched fields show no errors');

    await click('button[type="submit"]');

    assert.strictEqual(data.invalids, 1);
    assert.strictEqual(data.submits, 0);
    // the label is not used in messages; a `description` option names the field
    assert.dom('.euiFormErrorText').hasText("This field can't be blank");
    assert.dom('.euiFormRow__label').hasClass('euiFormLabel-isInvalid');
  });

  test('fixing the value clears the error and submits', async function (assert) {
    const data = new Data();

    await render(
      <template>
        <ValidatedForm @onSubmit={{data.onSubmit}} @onInvalid={{data.onInvalid}} as |Form|>
          <Form.FieldText @label="Name" @value={{data.text}} @onChange={{data.setText}} @validations={{hash presence=(hash presence=true)}} />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );
    await wait();
    await click('button[type="submit"]');
    assert.dom('.euiFormErrorText').exists();

    await fillIn('input', 'Jane');
    await wait();

    assert.strictEqual(data.text, 'Jane');
    assert.dom('.euiFormErrorText').doesNotExist();

    await click('button[type="submit"]');
    assert.strictEqual(data.submits, 1);
  });

  test('leaving a field marks it as touched', async function (assert) {
    const data = new Data();

    await render(
      <template>
        <ValidatedForm as |Form|>
          <Form.FieldText @label="Email" @value={{data.email}} @onChange={{data.setEmail}} @validations={{hash format=(hash type="email")}} />
        </ValidatedForm>
      </template>
    );
    await wait();
    assert.dom('.euiFormErrorText').doesNotExist();

    await focus('input');
    await blur('input');

    assert.dom('.euiFormErrorText').hasText('This field must be a valid email address');
  });

  test('@onValidityChange reports the form validity', async function (assert) {
    const data = new Data();
    const calls: boolean[] = [];
    const onValidityChange = (isValid: boolean) => calls.push(isValid);

    await render(
      <template>
        <ValidatedForm @onValidityChange={{onValidityChange}} as |Form|>
          <Form.FieldText @label="Name" @value={{data.text}} @onChange={{data.setText}} @validations={{hash presence=(hash presence=true)}} />
        </ValidatedForm>
      </template>
    );
    await wait();
    assert.false(calls.at(-1), 'invalid while empty');

    await fillIn('input', 'Jane');
    await wait();
    assert.true(calls.at(-1), 'valid once filled');
  });

  test('custom validations (ember-validators result shape) and external @error', async function (assert) {
    const data = new Data();
    const noFoo = [{ validation: (value: string) => (value === 'foo' ? { context: { message: 'foo is not allowed' } } : true) }];
    const serverErrors = ['Taken already'];

    data.text = 'foo';

    await render(
      <template>
        <ValidatedForm @onInvalid={{data.onInvalid}} as |Form|>
          <Form.FieldText @label="Name" @value={{data.text}} @onChange={{data.setText}} @customValidations={{noFoo}} class="custom" />
          <Form.FieldText @label="Username" @value="bar" @error={{serverErrors}} class="external" />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );
    await wait();
    await click('button[type="submit"]');

    const errors = [...document.querySelectorAll('.euiFormErrorText')].map((e) => e.textContent!.trim());

    assert.true(errors.includes('foo is not allowed'), `custom validation (${errors})`);
    assert.true(errors.includes('Taken already'), 'external error');
    assert.strictEqual(data.invalids, 1);
  });

  // Bug: custom validations typed as returning a boolean crash when they
  // return false (or a message string): buildMessage looks up an undefined
  // message type ("The key provided to get must be a string or number")
  test.todo('custom validations may return false or a message string', async function (assert) {
    const data = new Data();
    const noFoo = [
      { validation: (value: string) => (value === 'foo' ? 'foo is not allowed' : true) },
      { validation: (value: string) => value.length > 3 }
    ];
    const serverErrors = ['Taken already'];

    data.text = 'foo';

    await render(
      <template>
        <ValidatedForm @onInvalid={{data.onInvalid}} as |Form|>
          <Form.FieldText @label="Name" @value={{data.text}} @onChange={{data.setText}} @customValidations={{noFoo}} class="custom" />
          <Form.FieldText @label="Username" @value="bar" @error={{serverErrors}} class="external" />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );
    await wait();
    await click('button[type="submit"]');

    const errors = [...document.querySelectorAll('.euiFormErrorText')].map((e) => e.textContent!.trim());

    assert.true(errors.includes('foo is not allowed'), `custom validation (${errors})`);
    assert.true(errors.includes("This field is invalid"), `false result (${errors})`);
    assert.true(errors.includes('Taken already'), 'external error');
    assert.strictEqual(data.invalids, 1);
  });

  test('the `description` option names the field in messages', async function (assert) {
    const data = new Data();

    await render(
      <template>
        <ValidatedForm @onInvalid={{data.onInvalid}} as |Form|>
          <Form.FieldText @label="Name" @value={{data.text}} @onChange={{data.setText}} @validations={{hash presence=(hash presence=true description="Name")}} />
          <button type="submit">Save</button>
        </ValidatedForm>
      </template>
    );
    await click('button[type="submit"]');
    assert.dom('.euiFormErrorText').hasText("Name can't be blank");
  });

  test('reset calls @onReset', async function (assert) {
    const data = new Data();

    await render(
      <template>
        <ValidatedForm @onReset={{data.onReset}} as |Form|>
          <Form.FieldText @label="Name" @value={{data.text}} @onChange={{data.setText}} />
          <button type="reset">Reset</button>
        </ValidatedForm>
      </template>
    );

    await triggerEvent('form', 'reset');
    assert.strictEqual(data.resets, 1);
  });
});
