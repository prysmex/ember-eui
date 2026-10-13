---
order: 2
---

# With a label, help text and errors

<EuiText>

Wrap the field in an `EuiFormRow`: its label is linked to the input
automatically. Set `@isInvalid` on both the row (to show `@error`) and the
field (to style it).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormRow, EuiFieldText } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class TextFieldRowDemo extends Component {
  @tracked url = 'http://example.com';

  get isInvalid() {
    return this.url !== '' && !this.url.startsWith('https://');
  }

  @action
  updateUrl(event) {
    this.url = event.target.value;
  }

  <template>
    <EuiFormRow
      @label="Website"
      @helpText="Starts with https://"
      @isInvalid={{this.isInvalid}}
      @error="Enter a URL starting with https://"
    >
      <EuiFieldText
        @value={{this.url}}
        @isInvalid={{this.isInvalid}}
        {{on "input" this.updateUrl}}
      />
    </EuiFormRow>
  </template>
}
```
