import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { blur, click, fillIn, render, settled } from '@ember/test-helpers';

import { Changeset } from 'ember-changeset';
import lookupValidator from 'ember-changeset-validations';
import { validateLength, validatePresence } from 'ember-changeset-validations/validators';

import EuiChangesetForm from '#src/components/eui-changeset-form.gts';

import type { TOC } from '@ember/component/template-only';

const Validations = {
  name: validatePresence(true),
  email: validateLength({ min: 3 })
};

function build(model: Record<string, unknown> = { name: '', email: 'abc' }) {
  return Changeset(model, lookupValidator(Validations), Validations);
}

function recorder() {
  const calls: unknown[] = [];

  return { calls, fn: (data: unknown) => calls.push(data) };
}

module('Integration | Component | eui-changeset-form', function (hooks) {
  setupRenderingTest(hooks);

  test('typing sets the changeset value; leaving the field validates it', async function (assert) {
    const model = { name: 'Jane', email: 'abc' };
    const changeset = build(model);

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldText @fieldName="name" @label="Name" />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('input').hasValue('Jane', 'renders the changeset value');

    await fillIn('input', 'Joe');
    assert.strictEqual(changeset.get('name'), 'Joe');
    assert.strictEqual(model.name, 'Jane', 'the model is untouched until save');

    await fillIn('input', '');
    await blur('input');
    await settled();

    assert.dom('.euiFormErrorText').hasText("Name can't be blank");
    assert.true((this.element.querySelector('input') as HTMLInputElement).validity.customError, 'the input is marked invalid');
  });

  test('submitting an invalid changeset shows the errors and does not call @onSubmit', async function (assert) {
    const changeset = build();
    const onSubmit = recorder();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} @onSubmit={{onSubmit.fn}} as |Form cs hasSubmitted|>
          <Form.FieldText @fieldName="name" @label="Name" />
          <span class="submitted">{{if hasSubmitted "yes" "no"}}</span>
          <button type="submit">Save</button>
        </EuiChangesetForm>
      </template>
    );

    assert.dom('.submitted').hasText('no');
    await click('button[type="submit"]');

    assert.dom('.euiFormErrorText').hasText("Name can't be blank");
    assert.dom('.submitted').hasText('yes');
    assert.strictEqual(onSubmit.calls.length, 0);
  });

  test('submitting a valid changeset saves it and calls @onSubmit with the data', async function (assert) {
    const model = { name: '', email: 'abc' };
    const changeset = build(model);
    const onSubmit = recorder();
    const beforeSubmit = recorder();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} @beforeSubmit={{beforeSubmit.fn}} @onSubmit={{onSubmit.fn}} as |Form|>
          <Form.FieldText @fieldName="name" @label="Name" />
          <button type="submit">Save</button>
        </EuiChangesetForm>
      </template>
    );

    await fillIn('input', 'Jane');
    await click('button[type="submit"]');

    assert.strictEqual(beforeSubmit.calls[0], changeset, '@beforeSubmit receives the changeset');
    assert.strictEqual(model.name, 'Jane', 'the changes are applied to the model');
    assert.deepEqual(onSubmit.calls, [model]);
    assert.dom('.euiFormErrorText').doesNotExist();
  });

  test('@runExecuteInsteadOfSave applies the changes without saving', async function (assert) {
    let saved = 0;
    const model = { name: '', email: 'abc', save: () => saved++ };
    const changeset = build(model);
    const onSubmit = recorder();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} @runExecuteInsteadOfSave={{true}} @onSubmit={{onSubmit.fn}} as |Form|>
          <Form.FieldText @fieldName="name" @label="Name" />
          <button type="submit">Save</button>
        </EuiChangesetForm>
      </template>
    );

    await fillIn('input', 'Jane');
    await click('button[type="submit"]');

    assert.strictEqual(model.name, 'Jane');
    assert.strictEqual(saved, 0, 'model.save is not called');
    assert.strictEqual(onSubmit.calls.length, 1);
  });

  test('reset rolls the changeset back and calls @onReset', async function (assert) {
    const model = { name: 'Jane', email: 'abc' };
    const changeset = build(model);
    const onReset = recorder();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} @onReset={{onReset.fn}} as |Form|>
          <Form.FieldText @fieldName="name" @label="Name" />
          <button type="reset">Reset</button>
        </EuiChangesetForm>
      </template>
    );

    await fillIn('input', 'Joe');
    await click('button[type="reset"]');

    assert.strictEqual(changeset.get('name'), 'Jane');
    assert.dom('input').hasValue('Jane');
    assert.deepEqual(onReset.calls, [model]);
  });

  test('@initialValidation validates on render', async function (assert) {
    const changeset = build();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} @initialValidation={{true}} as |Form|>
          <Form.FieldText @fieldName="name" @label="Name" />
        </EuiChangesetForm>
      </template>
    );
    await settled();

    assert.dom('.euiFormErrorText').hasText("Name can't be blank");
  });

  test('@isDisabled disables the fields and @fullWidth reaches the rows', async function (assert) {
    const changeset = build();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} @isDisabled={{true}} @fullWidth={{true}} as |Form|>
          <Form.FieldText @fieldName="name" @label="Name" />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('input').isDisabled();
    assert.dom('.euiFormRow').hasClass('euiFormRow--fullWidth');
  });

  test('@errors overrides the changeset errors', async function (assert) {
    const changeset = build();
    const errors = ['Taken already'];

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} as |Form|>
          <Form.FieldText @fieldName="email" @label="Email" @errors={{errors}} />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('.euiFormErrorText').hasText('Taken already');
  });

  test('@theme replaces field components', async function (assert) {
    const changeset = build({ name: 'Jane', email: 'abc' });
    const CustomText: TOC<{ Args: { fieldName: string; changeset: unknown; formId: string } }> = <template>
      <span class="custom-text" data-form-id={{@formId}}>{{@fieldName}}</span>
    </template>;
    const theme = { FieldText: CustomText };

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} @theme={{theme}} @id="my-form" as |Form|>
          <Form.FieldText @fieldName="name" />
          <Form.FieldPassword @fieldName="email" @label="Password" />
        </EuiChangesetForm>
      </template>
    );

    assert.dom('.custom-text').hasText('name');
    assert.dom('.custom-text').hasAttribute('data-form-id', 'my-form', 'the form id is passed along');
    assert.dom('input[type="password"]').exists('other fields keep the default theme');
  });

  test('FieldBase yields the row context for custom controls', async function (assert) {
    const changeset = build();

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} @id="my-form" as |Form|>
          <Form.FieldBase @fieldName="name" @label="Name" @id="custom-id" as |field|>
            <input id={{field.id}} form={{field.formId}} class={{if field.isInvalid "bad"}} />
          </Form.FieldBase>
          <button type="submit">Save</button>
        </EuiChangesetForm>
      </template>
    );

    assert.dom('#custom-id').hasAttribute('form', 'my-form');
    assert.dom('label').hasAttribute('for', 'custom-id');
    await click('button[type="submit"]');
    assert.dom('#custom-id').hasClass('bad');
    assert.dom('.euiFormErrorText').hasText("Name can't be blank");
  });

  test('yields the changeset and the form id', async function (assert) {
    const changeset = build({ name: 'Jane', email: 'abc' });

    await render(
      <template>
        <EuiChangesetForm @changeset={{changeset}} @id="the-form" as |Form cs hasSubmitted formId|>
          <span class="out" data-form={{formId}}>{{cs.name}}</span>
        </EuiChangesetForm>
      </template>
    );

    assert.dom('form').hasAttribute('id', 'the-form');
    assert.dom('.out').hasText('Jane');
    assert.dom('.out').hasAttribute('data-form', 'the-form');
  });
});
