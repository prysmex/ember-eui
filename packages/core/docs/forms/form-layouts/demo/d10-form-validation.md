---
order: 10
---

# Form validation

<EuiText>

Validation is achieved by applying `@isInvalid` and optionally `@error` onto the `EuiForm` or `EuiFormRow` components. Errors are optional and are passed as an array in case you need to list more than one. You can also hide the callout by passing `@invalidCallout="none"`.

**Validation error text.** Validation messages are needed when the user input differs from what the system expects and enforces: required fields that are still blank, and invalid values for one or several reasons (forbidden characters, formatting, duplicate). Use clear language that helps users understand what they have to do: use a simple, minimalist format for a required field (_"Name is required."_), tell users what happened and how to fix it (_"This address is already used. Enter a different one."_), and be as precise as possible to describe the problem (_"The key can't contain the `:` character."_).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiFieldText,
  EuiForm,
  EuiFormRow,
  EuiSelect,
  EuiSpacer,
  EuiTextArea,
} from '@ember-eui/core/components';

export default class FormValidationDemo extends Component {
  options = [
    { value: 'option_one', text: 'Option one' },
    { value: 'option_two', text: 'Option two' },
    { value: 'option_three', text: 'Option three' },
  ];

  @tracked showErrors = true;

  get errors() {
    return this.showErrors
      ? [
          "Here's an example of an error",
          'You might have more than one error, so pass an array.',
        ]
      : undefined;
  }

  @action
  onButtonClick() {
    this.showErrors = !this.showErrors;
  }

  @action
  onSubmit(event) {
    event.preventDefault();
  }

  <template>
    <EuiForm
      @isInvalid={{this.showErrors}}
      @error={{this.errors}}
      @tagName="form"
      {{on "submit" this.onSubmit}}
    >
      <EuiFormRow @label="Validation only" @isInvalid={{this.showErrors}}>
        <EuiFieldText name="first" @isInvalid={{this.showErrors}} />
      </EuiFormRow>

      <EuiFormRow
        @label="Validation with help text and errors"
        @helpText="I am some friendly help text."
        @isInvalid={{this.showErrors}}
        @error={{this.errors}}
      >
        <EuiFieldText name="text" @isInvalid={{this.showErrors}} />
      </EuiFormRow>

      <EuiFormRow @label="Text area" @isInvalid={{this.showErrors}}>
        <EuiTextArea name="area" @isInvalid={{this.showErrors}} />
      </EuiFormRow>

      <EuiFormRow @label="Select" @isInvalid={{this.showErrors}}>
        <EuiSelect @options={{this.options}} @isInvalid={{this.showErrors}} />
      </EuiFormRow>

      <EuiSpacer />

      <EuiButton @fill={{true}} @color="danger" {{on "click" this.onButtonClick}}>
        Toggle errors
      </EuiButton>
    </EuiForm>
  </template>
}
```
