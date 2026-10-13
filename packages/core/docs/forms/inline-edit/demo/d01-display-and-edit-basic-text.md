---
order: 1
---

# Display and edit basic text

<EuiText>

Use `EuiInlineEditText` to display and edit basic text. Adjust the `@size` argument to change the font size in both read mode and edit mode.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonGroup, EuiSpacer, EuiInlineEditText } from '@ember-eui/core/components';

export default class InlineEditTextDemo extends Component {
  textSizeButtons = [
    { id: 'xs', label: 'Extra Small' },
    { id: 's', label: 'Small' },
    { id: 'm', label: 'Medium' },
  ];

  @tracked size = 'm';

  @action
  setSize(id) {
    this.size = id;
  }

  <template>
    <EuiButtonGroup
      @legend="Text size"
      @options={{this.textSizeButtons}}
      @idSelected={{this.size}}
      @onChange={{this.setSize}}
    />
    <EuiSpacer />
    <EuiInlineEditText
      @size={{this.size}}
      @inputAriaLabel="Edit text inline"
      @defaultValue="Hello World!"
    />
  </template>
}
```
