---
order: 6
---

# Only allow specific dates and times

<EuiText>

Use `@minDate` and `@maxDate` to specify the range the value must fall into, `@excludeDates` to disallow specific days, `@includeDates` to allow only some, and `@filterDate` to decide per day. They take `YYYY-MM-DD` strings (or a `Date` or a moment); `@filterDate` is called with each day as a string. Days that cannot be chosen are dimmed, and typed text naming one is an input error. With time selection, `@minTime` and `@maxTime` limit the wall times of every day and `@excludeTimes` disallows some (`HH:mm`); with `@showTimeSelect`, `@minDate` and `@maxDate` may also be instants, which disable the times before or after them.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import {
  EuiDatePicker,
  EuiFormRow,
  EuiSpacer,
} from '@ember-eui/core/components';

const pad = (n) => String(n).padStart(2, '0');
// the local day `n` days from today, YYYY-MM-DD
const day = (n = 0) => {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};

export default class DatePickerSpecificDatesDemo extends Component {
  @tracked startDate = day();
  @tracked startDate2 = day(1);
  @tracked startDate3 = day(1);
  @tracked startDate4 = null;
  @tracked startsAt = null;
  @tracked startsAt2 = null;
  @tracked lastError = null;

  lunch = ['12:00', '12:30'];
  setStartsAt = (value) => (this.startsAt = value);
  setStartsAt2 = (value) => (this.startsAt2 = value);

  minDate = day(-2);
  maxDate = day(5);
  excluded = [day(-1), day()];
  included = [day(-7), day(), day(7), day(14)];

  isWeekday = (date) => {
    const weekday = new Date(`${date}T00:00:00Z`).getUTCDay();
    return weekday !== 0 && weekday !== 6;
  };

  setStartDate2 = (date) => (this.startDate2 = date);
  setStartDate3 = (date) => (this.startDate3 = date);
  setStartDate4 = (date) => (this.startDate4 = date);
  onInputError = (error) => (this.lastError = error);
  setStartDate = (date) => {
    this.lastError = null;
    this.startDate = date;
  };

  get errorText() {
    const error = this.lastError;
    if (!error) return undefined;
    return error.reason === 'unreadable'
      ? `"${error.text}" is not a date.`
      : `"${error.text}" is outside the allowed days (${error.reason}).`;
  }

  <template>
    <EuiFormRow
      @label="Only allow a certain range of dates"
      @id="d06-range"
      @isInvalid={{if this.lastError true false}}
      @error={{this.errorText}}
    >
      <EuiDatePicker
        @id="d06-range"
        @value={{this.startDate}}
        @onChange={{this.setStartDate}}
        @minDate={{this.minDate}}
        @maxDate={{this.maxDate}}
        @onInputError={{this.onInputError}}
      />
    </EuiFormRow>

    <EuiSpacer />

    <EuiFormRow @label="Exclude yesterday and today" @id="d06-exclude">
      <EuiDatePicker
        @id="d06-exclude"
        @value={{this.startDate2}}
        @onChange={{this.setStartDate2}}
        @excludeDates={{this.excluded}}
      />
    </EuiFormRow>

    <EuiSpacer />

    <EuiFormRow @label="Filter so only weekdays are selectable" @id="d06-filter">
      <EuiDatePicker
        @id="d06-filter"
        @value={{this.startDate3}}
        @onChange={{this.setStartDate3}}
        @filterDate={{this.isWeekday}}
      />
    </EuiFormRow>

    <EuiSpacer />

    <EuiFormRow @label="Only today and the same weekday a week either side, and two ahead" @id="d06-include">
      <EuiDatePicker
        @id="d06-include"
        @value={{this.startDate4}}
        @onChange={{this.setStartDate4}}
        @includeDates={{this.included}}
      />
    </EuiFormRow>

    <EuiSpacer />

    <EuiFormRow @label="Only allow times between 09:00 and 17:30" @id="d06-times">
      <EuiDatePicker
        @id="d06-times"
        @value={{this.startsAt}}
        @onChange={{this.setStartsAt}}
        @showTimeSelect={{true}}
        @minTime="09:00"
        @maxTime="17:30"
      />
    </EuiFormRow>

    <EuiSpacer />

    <EuiFormRow @label="Exclude 12:00 and 12:30" @id="d06-exclude-times">
      <EuiDatePicker
        @id="d06-exclude-times"
        @value={{this.startsAt2}}
        @onChange={{this.setStartsAt2}}
        @showTimeSelect={{true}}
        @excludeTimes={{this.lunch}}
      />
    </EuiFormRow>
  </template>
}
```
