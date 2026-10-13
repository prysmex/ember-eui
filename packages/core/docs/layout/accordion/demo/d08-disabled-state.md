---
order: 8
---

# Disabled state

<EuiText>
  <p>
    In some cases you might want to prevent the user from closing the
    <strong>EuiAccordion</strong>. For example, if a form field is displaying an
    error, opening the accordion and preventing its closure until the error has
    been addressed will help the user find and fix the error.
  </p>
  <p>
    The <EuiCode>@isDisabled</EuiCode> argument will disable interaction on the
    button and the arrow. Use it in conjunction with
    <EuiCode>@initialIsOpen</EuiCode> to achieve the desired effect.
  </p>
</EuiText>

<EuiSpacer />

<EuiCallOut @title="Accessibility recommendation" @iconType="accessibility" @color="warning">
  When disabling the interaction of accordions based on user input, it's
  advisable to ensure there is further explanation through the use of help or
  error text.
</EuiCallOut>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { array } from '@ember/helper';
import { EuiAccordion, EuiFieldPassword, EuiFormRow, EuiPanel } from '@ember-eui/core/components';

export default class AccordionDisabledComponent extends Component {
  @tracked passwordValue = '';

  get isInvalid() {
    return this.passwordValue === '';
  }

  @action
  onChange(e) {
    this.passwordValue = e.target.value;
  }

  <template>
  <EuiAccordion
    @id="disabledAccordion"
    @isDisabled={{this.isInvalid}}
    @initialIsOpen={{true}}
  >
    <:buttonContent>
      Security settings
    </:buttonContent>
    <:content>
      <EuiPanel @color="subdued">
        <EuiFormRow
          @label="Password"
          @isInvalid={{this.isInvalid}}
          @error={{array "You must enter your password to save these changes."}}
        >
          <EuiFieldPassword
            @isInvalid={{this.isInvalid}}
            @value={{this.passwordValue}}
            {{on "input" this.onChange}}
          />
        </EuiFormRow>
      </EuiPanel>
    </:content>
  </EuiAccordion>
  </template>
}
```
