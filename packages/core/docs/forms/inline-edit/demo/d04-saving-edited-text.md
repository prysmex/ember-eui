---
order: 4
---

# Saving edited text

<EuiText>

Use the `@onSave` argument to retrieve the value of the edited text when the save button is pressed. `@onSave` does not fire if the user cancels their edit.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { EuiInlineEditText } from '@ember-eui/core/components';

export default class InlineEditSaveDemo extends Component {
  get defaultInlineEditValue() {
    try {
      return (
        localStorage.getItem('inlineEditValue') ||
        'This value will persist when you refresh the page!'
      );
    } catch {
      return 'This value will persist when you refresh the page!';
    }
  }

  @action
  saveToLocalStorage(newInlineEditValue) {
    try {
      localStorage.setItem('inlineEditValue', newInlineEditValue);
    } catch {
      // storage is unavailable, nothing to persist
    }
  }

  <template>
    <EuiInlineEditText
      @inputAriaLabel="Edit text inline"
      @defaultValue={{this.defaultInlineEditValue}}
      @onSave={{this.saveToLocalStorage}}
    />
  </template>
}
```
