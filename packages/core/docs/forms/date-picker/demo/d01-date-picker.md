---
order: 1
---

# Date picker

<EuiText>

At minimum, `EuiDatePicker` needs `@value` and `@onChange`. The value is a `YYYY-MM-DD` string; the input shows it in the order of the page's locale. Type a date and press Enter, or pick one in the calendar.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import {
  EuiCode,
  EuiDatePicker,
  EuiFormRow,
  EuiSpacer,
  EuiText,
} from '@ember-eui/core/components';

const pad = (n) => String(n).padStart(2, '0');
const now = new Date();
const today = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;

export default class DatePickerDemo extends Component {
  @tracked startDate = today;

  handleChange = (date) => {
    this.startDate = date;
  };

  <template>
    <EuiFormRow @label="Select a date" @id="d01-date">
      <EuiDatePicker
        @id="d01-date"
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
      />
    </EuiFormRow>
    <EuiSpacer @size="s" />
    <EuiText @size="s">
      <p>
        Value:
        <EuiCode data-test-value>{{if this.startDate this.startDate "null"}}</EuiCode>
      </p>
    </EuiText>
  </template>
}
```
