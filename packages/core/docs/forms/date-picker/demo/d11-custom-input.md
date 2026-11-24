---
order: 7.5
---

# Custom input

<EuiText>

Use the `<:trigger>` block to open the calendar from an element of your own instead of the text input (upstream's `customInput`). It yields `open`, to call from the element's click, `isOpen`, and `text`, the value in the display format. The calendar takes focus when it opens and gives it back to the trigger when it closes. There is no typed input, no icon and no native path: phones get the calendar too, with or without `@native={{false}}`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiButton, EuiDatePicker } from '@ember-eui/core/components';

const pad = (n) => String(n).padStart(2, '0');
const now = new Date();
const today = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;

export default class DatePickerCustomInputDemo extends Component {
  @tracked startDate = today;

  handleChange = (date) => {
    this.startDate = date;
  };

  <template>
    <EuiDatePicker
      @value={{this.startDate}}
      @onChange={{this.handleChange}}
      @native={{false}}
    >
      <:trigger as |picker|>
        <EuiButton
          class="example-custom-input"
          aria-haspopup="dialog"
          aria-expanded={{if picker.isOpen "true" "false"}}
          {{on "click" picker.open}}
        >
          {{picker.text}}
        </EuiButton>
      </:trigger>
    </EuiDatePicker>
  </template>
}
```
