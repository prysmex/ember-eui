---
order: 8
---

# Read only

<EuiText>

Use the `@isReadOnly` argument to lock the inline edit in read mode and display the text value. This does not affect the input form control in edit mode.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSwitch, EuiSpacer, EuiInlineEditText, EuiInlineEditTitle } from '@ember-eui/core/components';

export default class InlineEditReadOnlyDemo extends Component {
  @tracked isReadOnly = true;

  @action
  setReadOnly(event) {
    this.isReadOnly = event.target.checked;
  }

  <template>
    <EuiSwitch
      @label="Toggle read only"
      @checked={{this.isReadOnly}}
      @onChange={{this.setReadOnly}}
    />
    <EuiSpacer />
    <EuiInlineEditText
      @inputAriaLabel="Edit text inline"
      @defaultValue="This is read only text!"
      @isReadOnly={{this.isReadOnly}}
    />
    <EuiSpacer />
    <EuiInlineEditTitle
      @heading="h3"
      @inputAriaLabel="Edit title inline"
      @defaultValue="This is a read only title!"
      @isReadOnly={{this.isReadOnly}}
    />
  </template>
}
```
