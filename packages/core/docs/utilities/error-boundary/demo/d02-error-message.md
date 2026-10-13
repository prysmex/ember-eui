---
order: 2
---

# EuiErrorMessage

<EuiText>

The fallback upstream's error boundary renders. Here a caught error is shown with `@error`; `@errorMessage` takes plain text instead.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiButton, EuiErrorMessage, EuiSpacer } from '@ember-eui/core/components';

export default class ErrorMessageDemo extends Component {
  @tracked error = null;

  breakIt = () => {
    try {
      JSON.parse('{ not json');
    } catch (error) {
      this.error = error;
    }
  };

  reset = () => {
    this.error = null;
  };

  <template>
    {{#if this.error}}
      <EuiErrorMessage @error={{this.error}} />
      <EuiSpacer @size="s" />
      <EuiButton @size="s" {{on "click" this.reset}}>Reset</EuiButton>
    {{else}}
      <EuiButton @color="danger" @size="s" {{on "click" this.breakIt}}>Parse bad JSON</EuiButton>
    {{/if}}
  </template>
}
```
