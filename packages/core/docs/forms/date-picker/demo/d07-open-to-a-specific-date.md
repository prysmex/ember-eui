---
order: 7
---

# Open to a specific date

<EuiText>

Use `@openToDate` to choose the month the calendar opens on while there is no value.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiDatePicker, EuiFormRow } from '@ember-eui/core/components';

export default class DatePickerOpenToDateDemo extends Component {
  @tracked startDate = null;

  handleChange = (date) => {
    this.startDate = date;
  };

  <template>
    <EuiFormRow @label="Select a date" @id="d07-date">
      <EuiDatePicker
        @id="d07-date"
        @native={{false}}
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @openToDate="1993-09-28"
        @placeholder="Back to 1993"
      />
    </EuiFormRow>
  </template>
}
```
