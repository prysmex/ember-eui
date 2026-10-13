---
order: 5
---

# Validating edited text

<EuiText>

Validation states (`@isLoading` and `@isInvalid`) only display while the user is in edit mode.

Return a boolean from your `@onSave` action to validate text after pressing Save. You can also return a boolean from a promise. Validation happens before the user returns to read mode.

Returning `false` from `@onSave` will keep the user in edit mode, where you can then display validation state and messages. Returning `true` or `undefined` will return the user to read mode.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiInlineEditText } from '@ember-eui/core/components';

const DEFAULT = 'This value will persist when you refresh the page!';

export default class InlineEditValidationDemo extends Component {
  @tracked isLoading = false;
  @tracked errors = [];

  get isInvalid() {
    return this.errors.length > 0;
  }

  get defaultInlineEditValue() {
    try {
      return localStorage.getItem('inlineEditValueValidated') || DEFAULT;
    } catch {
      return DEFAULT;
    }
  }

  get editModeProps() {
    return {
      formRowProps: { error: this.errors },
      cancelButtonProps: { onClick: () => (this.errors = []) },
      inputProps: { readOnly: this.isLoading },
    };
  }

  mockApiCall(value) {
    return new Promise((resolve) => {
      try {
        localStorage.setItem('inlineEditValueValidated', value);
      } catch {
        // storage is unavailable, nothing to persist
      }
      setTimeout(resolve, 3000);
    });
  }

  @action
  async onSave(value) {
    // Validate edited text
    if (!value) {
      this.errors = ['Please enter text.'];
      return false;
    } else if (value.length > 20) {
      this.errors = [
        'Your text is too long - please enter less than 20 characters',
      ];
      return false;
    }

    // Clear errors, set loading state, and "call" an API
    this.errors = [];
    this.isLoading = true;
    await this.mockApiCall(value);
    this.isLoading = false;
    return true;
  }

  <template>
    <EuiInlineEditText
      @inputAriaLabel="This input will validate on save"
      @defaultValue={{this.defaultInlineEditValue}}
      @editModeProps={{this.editModeProps}}
      @isInvalid={{this.isInvalid}}
      @isLoading={{this.isLoading}}
      @onSave={{this.onSave}}
    />
  </template>
}
```
