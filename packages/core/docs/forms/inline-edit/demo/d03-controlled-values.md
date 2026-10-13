---
order: 3
---

# Controlled values

<EuiText>

To control the text value for inline edit, use the `@value` argument to continually pass a text value. An `@onChange` action is required to receive and update `@value` based on user input. An `@onCancel` action is required to reset the value to the previous read mode text value.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiInlineEditText } from '@ember-eui/core/components';

export default class InlineEditControlledDemo extends Component {
  @tracked inlineEditValue = 'Hello World!';

  @action
  inlineEditOnChange(event) {
    this.inlineEditValue = event.target.value;
  }

  @action
  inlineEditOnCancel(previousValue) {
    this.inlineEditValue = previousValue;
  }

  <template>
    <EuiInlineEditText
      @inputAriaLabel="Edit title inline"
      @value={{this.inlineEditValue}}
      @onChange={{this.inlineEditOnChange}}
      @onCancel={{this.inlineEditOnCancel}}
    />
  </template>
}
```
