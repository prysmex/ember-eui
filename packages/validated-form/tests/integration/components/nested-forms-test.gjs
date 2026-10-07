import { hash } from '@ember/helper';
import { blur, fillIn, focus, render, settled, triggerEvent } from '@ember/test-helpers';
import { ValidatedFormDefaultTheme } from '#src/components/default-theme.ts';
import ValidatedForm from '#src/components/validated-form.gts';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';

module('Integration | Component | validated-form | nested forms', function (hooks) {
  setupRenderingTest(hooks);

  test('the default theme supplies the nested form component', function (assert) {
    assert.strictEqual(ValidatedFormDefaultTheme.FieldNestedForm, ValidatedForm);
    assert.strictEqual({ ...ValidatedFormDefaultTheme }.FieldNestedForm, ValidatedForm);
  });

  test('nested validity, touch, submission and removal propagate to the parent', async function (assert) {
    this.setProperties({
      value: '',
      showChild: true,
      submissions: 0,
      invalidSubmissions: 0,
      validityChanges: [],
      validityChanged: (...state) => this.validityChanges.push(state),
      updateValue: (value) => this.set('value', value),
      submit: () => this.incrementProperty('submissions'),
      invalid: () => this.incrementProperty('invalidSubmissions')
    });

    await render(<template>
      <ValidatedForm @id="parent" @onSubmit={{this.submit}} @onInvalid={{this.invalid}} @onValidityChange={{this.validityChanged}} as |parent|>
        <span data-parent-valid>{{parent.isValid}}</span>
        <span data-parent-touched>{{parent.isTouched}}</span>
        {{#if this.showChild}}
          <parent.Form data-child as |child|>
            <span data-child-valid>{{child.isValid}}</span>
            <child.FieldNestedForm as |grandchild|>
              <grandchild.FieldText
                data-input
                @value={{this.value}}
                @onChange={{this.updateValue}}
                @validations={{hash presence=(hash presence=true)}}
              />
            </child.FieldNestedForm>
          </parent.Form>
        {{/if}}
      </ValidatedForm>
    </template>);

    assert.dom('form').exists({ count: 1 });
    assert.dom('[data-child]').hasTagName('div');
    assert.dom('[data-input]').hasAttribute('form', 'parent');
    assert.dom('[data-parent-valid]').hasText('false');
    assert.dom('[data-child-valid]').hasText('false');
    assert.deepEqual(this.validityChanges[this.validityChanges.length - 1], [false, false, false]);
    assert.dom('[data-parent-touched]').hasText('false');

    await triggerEvent('#parent', 'submit');
    assert.strictEqual(this.invalidSubmissions, 1);
    assert.strictEqual(this.submissions, 0);
    assert.dom('[data-parent-touched]').hasText('true');
    assert.false(this.element.querySelector('[data-input]').validity.valid);
    assert.deepEqual(this.validityChanges[this.validityChanges.length - 1], [false, true, true]);

    await fillIn('[data-input]', 'valid');
    assert.dom('[data-parent-valid]').hasText('true');
    assert.dom('[data-child-valid]').hasText('true');
    assert.deepEqual(this.validityChanges[this.validityChanges.length - 1], [true, true, false]);

    await triggerEvent('#parent', 'submit');
    assert.strictEqual(this.submissions, 1);
    assert.dom('[data-parent-touched]').hasText('false');

    await focus('[data-input]');
    await blur('[data-input]');
    assert.dom('[data-parent-touched]').hasText('true');

    await fillIn('[data-input]', '');
    assert.dom('[data-parent-valid]').hasText('false');
    this.set('showChild', false);
    await settled();
    assert.dom('[data-child]').doesNotExist();
    assert.dom('[data-parent-valid]').hasText('true');
    assert.dom('[data-parent-touched]').hasText('false');
  });

  test('siblings and direct fields contribute independently to parent validity', async function (assert) {
    this.setProperties({
      direct: 'valid',
      first: '',
      second: '',
      updateDirect: (value) => this.set('direct', value),
      updateFirst: (value) => this.set('first', value),
      updateSecond: (value) => this.set('second', value)
    });

    await render(<template>
      <ValidatedForm as |parent|>
        <span data-valid>{{parent.isValid}}</span>
        <parent.FieldText data-direct @value={{this.direct}} @onChange={{this.updateDirect}}
          @validations={{hash presence=(hash presence=true)}} />
        <parent.Form as |first|>
          <first.FieldText data-first @value={{this.first}} @onChange={{this.updateFirst}}
            @validations={{hash presence=(hash presence=true)}} />
        </parent.Form>
        <parent.Form as |second|>
          <second.FieldText data-second @value={{this.second}} @onChange={{this.updateSecond}}
            @validations={{hash presence=(hash presence=true)}} />
        </parent.Form>
      </ValidatedForm>
    </template>);

    assert.dom('[data-valid]').hasText('false');
    await fillIn('[data-first]', 'valid');
    assert.dom('[data-valid]').hasText('false', 'The other nested form still invalidates the parent');
    await fillIn('[data-second]', 'valid');
    assert.dom('[data-valid]').hasText('true');
    await fillIn('[data-direct]', '');
    assert.dom('[data-valid]').hasText('false', 'Direct fields still invalidate the parent');
  });

  test('failed submission touches descendants and nested containers do not handle parent events', async function (assert) {
    this.setProperties({
      childSubmits: 0,
      childResets: 0,
      parentResets: 0,
      fail: async () => { throw new Error('Save failed'); },
      childSubmit: () => this.incrementProperty('childSubmits'),
      childReset: () => this.incrementProperty('childResets'),
      parentReset: () => this.incrementProperty('parentResets'),
      noop: () => {}
    });

    await render(<template>
      <ValidatedForm @id="parent" @onSubmit={{this.fail}} @onReset={{this.parentReset}} as |parent|>
        <span data-parent-touched>{{parent.isTouched}}</span>
        <parent.Form @onSubmit={{this.childSubmit}} @onReset={{this.childReset}} as |child|>
          <span data-child-touched>{{child.isTouched}}</span>
          <child.FieldText @value="valid" @onChange={{this.noop}} />
        </parent.Form>
      </ValidatedForm>
    </template>);

    await triggerEvent('#parent', 'submit');
    assert.dom('[data-parent-touched]').hasText('true');
    assert.dom('[data-child-touched]').hasText('true');
    assert.strictEqual(this.childSubmits, 0);
    await triggerEvent('#parent', 'reset');
    assert.strictEqual(this.parentResets, 1);
    assert.strictEqual(this.childResets, 0);
  });

  test('nested fields inherit disabled state and full width', async function (assert) {
    this.set('disabled', true);
    this.set('noop', () => {});
    await render(<template>
      <ValidatedForm @isDisabled={{this.disabled}} @fullWidth={{true}} as |parent|>
        <parent.Form as |child|>
          <child.FieldText data-input @value="value" @onChange={{this.noop}} />
        </parent.Form>
      </ValidatedForm>
    </template>);

    assert.dom('[data-input]').isDisabled();
    assert.dom('[data-input]').hasClass('euiFieldText--fullWidth');
    this.set('disabled', false);
    await settled();
    assert.dom('[data-input]').isNotDisabled();
  });


  test('themed nested wrappers can bind a model and preserve parent wiring', async function (assert) {
    const ModelForm = <template>
      <ValidatedForm
        @theme={{@theme}}
        @register={{@register}}
        @unregister={{@unregister}}
        @onValidityChange={{@onValidityChange}}
        @tagName={{@tagName}}
        @formId={{@formId}}
        @isDisabled={{@isDisabled}}
        @fullWidth={{@fullWidth}}
        ...attributes
        as |form|
      >
        {{yield (hash
          Form=form.Form
          FieldText=(component form.FieldText value=@model.city onChange=@model.updateCity)
          isValid=form.isValid
        )}}
      </ValidatedForm>
    </template>;

    this.owner.register('component:model-form', ModelForm);
    this.setProperties({
      theme: { FieldNestedForm: ModelForm },
      showChild: true,
      model: { city: '', updateCity: (city) => this.set('model.city', city) }
    });

    await render(<template>
      <ValidatedForm @id="parent" @theme={{this.theme}} as |parent|>
        <span data-valid>{{parent.isValid}}</span>
        {{#if this.showChild}}
          <parent.Form @model={{this.model}} data-wrapper as |modelForm|>
            <modelForm.Form @model={{this.model}} as |nestedModelForm|>
              <nestedModelForm.FieldText data-city
                @validations={{hash presence=(hash presence=true)}} />
            </modelForm.Form>
          </parent.Form>
        {{/if}}
      </ValidatedForm>
    </template>);

    assert.dom('form').exists({ count: 1 });
    assert.dom('[data-wrapper]').hasTagName('div');
    assert.dom('[data-city]').hasAttribute('form', 'parent');
    assert.dom('[data-valid]').hasText('false');
    await fillIn('[data-city]', 'Monterrey');
    assert.strictEqual(this.model.city, 'Monterrey');
    assert.dom('[data-valid]').hasText('true');
    await fillIn('[data-city]', '');
    assert.dom('[data-valid]').hasText('false');
    this.set('showChild', false);
    await settled();
    assert.dom('[data-wrapper]').doesNotExist();
    assert.dom('[data-valid]').hasText('true', 'Wrapper forwards unregister to remove its contribution');
  });

});
