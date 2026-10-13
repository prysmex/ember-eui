---
order: 2
---

# Validation error

<EuiText>

By default, an `EuiSearchBar` displays a built-in tooltip when an invalid query is typed. This tooltip informs sighted users (if no other error UI is provided by the consumer) as well as screen reader users.

If you prefer to provide your own error UI, you can use `@showErrorTooltip={{false}}` to hide the built-in tooltip.

**Accessibility: use `aria-describedby` with `@showErrorTooltip={{false}}`.** If you choose to hide the built-in tooltip, you _must_ ensure that screen readers can still announce the validation error. Wrapping the search bar in an `EuiFormRow` does not do this automatically because `EuiSearchBar` is not a form control itself. Instead, pass `aria-describedby` directly via the `@box` argument, pointing at the `id` of your own error message, as shown below.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormErrorText, EuiSearchBar, EuiSpacer } from '@ember-eui/core/components';

const ERROR_ID = 'search-bar-validation-error';

export default class SearchBarValidationDemo extends Component {
  @tracked error = null;

  get box() {
    return {
      placeholder: 'Type an invalid query like "tag:value OR"',
      'aria-describedby': this.error ? ERROR_ID : undefined,
    };
  }

  get message() {
    return `Invalid search: ${this.error?.message}`;
  }

  @action
  onChange({ error }) {
    this.error = error ?? null;
  }

  <template>
    <EuiSearchBar
      @box={{this.box}}
      @onChange={{this.onChange}}
      @showErrorTooltip={{false}}
    />
    {{#if this.error}}
      <EuiSpacer @size="s" />
      <EuiFormErrorText id="search-bar-validation-error">
        {{this.message}}
      </EuiFormErrorText>
    {{/if}}
  </template>
}
```
