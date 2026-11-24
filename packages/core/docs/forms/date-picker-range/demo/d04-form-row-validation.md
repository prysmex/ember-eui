---
order: 4
---

# In a form row, with validation (Ember EUI extra)

<EuiText>

Two date pickers in an `EuiFormRow`. The range does not check that the end is after the start; here the app does: the end date must not be before the start date, so the range is marked invalid and the error is shown below.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import {
  EuiDatePicker,
  EuiDatePickerRange,
  EuiFormRow,
} from '@ember-eui/core/components';

export default class DateRangeDemo extends Component {
  @tracked start = '2026-03-01';
  @tracked end = '2026-03-15';

  get isInvalid() {
    return Boolean(this.start && this.end && this.end < this.start);
  }

  setStart = (date) => {
    this.start = date;
  };

  setEnd = (date) => {
    this.end = date;
  };

  <template>
    <EuiFormRow
      @label="Dates"
      @isInvalid={{this.isInvalid}}
      @error="The end date is before the start date."
    >
      <EuiDatePickerRange @isInvalid={{this.isInvalid}}>
        <:start as |className|>
          <EuiDatePicker
            class={{className}}
            aria-label="Start date"
            @value={{this.start}}
            @onChange={{this.setStart}}
            @selectsStart={{true}}
            @startDate={{this.start}}
            @endDate={{this.end}}
          />
        </:start>
        <:end as |className|>
          <EuiDatePicker
            class={{className}}
            aria-label="End date"
            @value={{this.end}}
            @onChange={{this.setEnd}}
            @selectsEnd={{true}}
            @startDate={{this.start}}
            @endDate={{this.end}}
          />
        </:end>
      </EuiDatePickerRange>
    </EuiFormRow>
  </template>
}
```
