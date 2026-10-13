---
order: 6
---

# Messages and loading

<EuiText>

The component comes with pre-composed messages for loading, empty, and no search result states. To display your own messages, pass `@loadingMessage`, `@emptyMessage`, `@errorMessage`, or `@noMatchesMessage` respectively. Alternatively, you can replace the entire `list` display with your own message for any state. In which case, we recommend wrapping your custom message in an `EuiSelectableMessage` component.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSelectable, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

export default class SelectableMessagesDemo extends Component {
  none = [];

  @tracked useCustomMessage = false;
  @tracked isLoading = false;
  @tracked hasError = false;

  get errorMessage() {
    return this.hasError ? 'Error!' : undefined;
  }

  @action
  setHasError(event) {
    this.hasError = event.target.checked;
  }

  get emptyMessage() {
    return this.useCustomMessage ? 'You have no spice' : undefined;
  }

  get loadingMessage() {
    return this.useCustomMessage ? "Hey, I'm loading here!" : undefined;
  }

  @action
  setUseCustomMessage(event) {
    this.useCustomMessage = event.target.checked;
  }

  @action
  setIsLoading(event) {
    this.isLoading = event.target.checked;
  }

  <template>
    <EuiSwitch
      @label="Custom message"
      @checked={{this.useCustomMessage}}
      @onChange={{this.setUseCustomMessage}}
    />
    &emsp;
    <EuiSwitch
      @label="Show loading"
      @checked={{this.isLoading}}
      @onChange={{this.setIsLoading}}
    />
    &emsp;
    <EuiSwitch
      @label="Show error"
      @checked={{this.hasError}}
      @onChange={{this.setHasError}}
    />
    <EuiSpacer />
    <EuiSelectable
      aria-label="Messaging example"
      style="width: 300px"
      @options={{this.none}}
      @listProps={{hash bordered=true}}
      @isLoading={{this.isLoading}}
      @loadingMessage={{this.loadingMessage}}
      @emptyMessage={{this.emptyMessage}}
      @errorMessage={{this.errorMessage}}
    />
  </template>
}
```
