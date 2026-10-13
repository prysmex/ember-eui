---
order: 3
---

# Icon, loading and clearing

<EuiText>

`@icon` shows an icon in the textarea, `@isLoading` a spinner, and
`@isClearable` a button that empties the text (it fires an `input` event, so
your handler sees the empty value, and focuses the textarea). The icons sit at
the bottom of the textarea.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { EuiFormRow, EuiTextArea } from '@ember-eui/core/components';

export default class TextAreaIconsDemo extends Component {
  @tracked value = 'Clear me with the button';

  @action
  onInput(event) {
    this.value = event.target.value;
  }

  <template>
    <EuiFormRow @label="Notes">
      <EuiTextArea
        @icon="pencil"
        @isLoading={{true}}
        @isClearable={{true}}
        @rows={{3}}
        @value={{this.value}}
        aria-label="Notes"
        {{on "input" this.onInput}}
      />
    </EuiFormRow>
  </template>
}
```
