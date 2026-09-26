import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { focus, render } from '@ember/test-helpers';

import EuiDescribedFormGroup from '#src/components/eui-described-form-group.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiForm from '#src/components/eui-form.gts';
import EuiFormErrorText from '#src/components/eui-form-error-text.gts';
import EuiFormFieldset from '#src/components/eui-form-fieldset.gts';
import EuiFormHelpText from '#src/components/eui-form-help-text.gts';
import EuiFormLabel from '#src/components/eui-form-label.gts';
import EuiFormLegend from '#src/components/eui-form-legend.gts';
import EuiFormRow from '#src/components/eui-form-row.gts';

const ERRORS = ['Name is required', 'Email is invalid'];

module('Integration | Component | eui-form', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiForm shows an error callout above the content when invalid', async function (assert) {
    await render(
      <template>
        <EuiForm @tagName="form" @isInvalid={{true}} @error={{ERRORS}}>
          <p class="content">Fields</p>
        </EuiForm>
      </template>
    );

    assert.dom('form.euiForm').exists();
    assert.dom('.euiForm__errors').hasAttribute('role', 'alert').hasClass('euiCallOut--danger');
    assert.dom('.euiForm__errors .euiCallOutHeader__title').hasText('Please correct the fields');
    assert.dom('.euiForm__error').exists({ count: 2 });
    assert.dom('.euiForm .content').hasText('Fields');
  });

  test('EuiForm hides the callout when valid or with invalidCallout="none"', async function (assert) {
    await render(
      <template>
        <EuiForm @isInvalid={{false}} @error={{ERRORS}} class="valid" />
        <EuiForm @isInvalid={{true}} @error={{ERRORS}} @invalidCallout="none" class="none" />
      </template>
    );

    assert.dom('div.euiForm.valid .euiForm__errors').doesNotExist();
    assert.dom('div.euiForm.none .euiForm__errors').doesNotExist();
  });

  test('EuiFormRow renders label, field, help text and errors', async function (assert) {
    await render(
      <template>
        <EuiFormRow @id="name" @label="Name" @helpText="Your full name" @isInvalid={{true}} @error={{ERRORS}}>
          <EuiFieldText @id="name" />
        </EuiFormRow>
      </template>
    );

    assert.dom('.euiFormRow label.euiFormRow__label').hasAttribute('for', 'name').hasText('Name').hasClass('euiFormLabel-isInvalid').hasAttribute('aria-invalid', 'true');
    assert.dom('.euiFormRow__fieldWrapper input#name').exists();
    assert.dom('.euiFormHelpText').hasText('Your full name');
    assert.dom('.euiFormErrorText').exists({ count: 2 });
    assert.dom('.euiFormErrorText').hasText('Name is required').hasAttribute('aria-live', 'polite');
  });

  test('EuiFormRow: focus highlights the label; errors only show when invalid', async function (assert) {
    await render(
      <template>
        <EuiFormRow @id="email" @label="Email" @error={{ERRORS}} @fullWidth={{true}} @display="rowCompressed">
          <EuiFieldText @id="email" />
        </EuiFormRow>
      </template>
    );

    assert.dom('.euiFormRow').hasClass('euiFormRow--fullWidth');
    assert.dom('.euiFormErrorText').doesNotExist();

    await focus('input#email');
    assert.dom('label.euiFormRow__label').hasClass('euiFormLabel-isFocused');
  });

  test('EuiFormLabel, EuiFormHelpText, EuiFormErrorText and EuiFormFieldset', async function (assert) {
    await render(
      <template>
        <EuiFormLabel @for="x" @isInvalid={{true}} class="label">Label</EuiFormLabel>
        <EuiFormLabel @type="legend" class="legend-label">Legend</EuiFormLabel>
        <EuiFormHelpText @id="help">Help</EuiFormHelpText>
        <EuiFormErrorText>Error</EuiFormErrorText>
        <EuiFormFieldset @legend="Group"><span class="inside">inside</span></EuiFormFieldset>
      </template>
    );

    assert.dom('label.label').hasAttribute('for', 'x').hasClass('euiFormLabel-isInvalid');
    assert.dom('legend.legend-label').hasClass('euiFormLabel');
    assert.dom('#help.euiFormHelpText').hasText('Help');
    assert.dom('.euiFormErrorText').hasText('Error');
    assert.dom('fieldset legend.euiFormLegend').hasText('Group');
    assert.dom('fieldset .inside').exists();
  });

  // Bug: EuiFormLegend checks display "hiddden" and uses the misspelled
  // classes euiFormLengend--isHidden / euiFormLegend--compresed
  test.todo('EuiFormLegend hidden and compressed classes', async function (assert) {
    await render(
      <template>
        <EuiFormLegend @display="hidden" class="hidden">Hidden</EuiFormLegend>
        <EuiFormLegend @compressed={{true}} class="compressed">Small</EuiFormLegend>
      </template>
    );

    assert.dom('legend.hidden').hasClass('euiFormLegend-isHidden');
    assert.dom('legend.hidden .euiScreenReaderOnly').hasText('Hidden');
    assert.dom('legend.compressed').hasClass('euiFormLegend--compressed');
  });

  test('EuiDescribedFormGroup renders title, description and fields', async function (assert) {
    await render(
      <template>
        <EuiDescribedFormGroup @fullWidth={{true}} @titleSize="s">
          <:title><h3>Settings</h3></:title>
          <:description>Configure things</:description>
          <:default><span class="fields">fields</span></:default>
        </EuiDescribedFormGroup>
      </template>
    );

    assert.dom('[role="group"].euiDescribedFormGroup').hasClass('euiDescribedFormGroup--fullWidth');
    assert.dom('.euiDescribedFormGroup__title h3').hasText('Settings');
    assert.dom('.euiDescribedFormGroup__description').hasText('Configure things');
    assert.dom('.euiDescribedFormGroup__fields .fields').exists();
  });
});
