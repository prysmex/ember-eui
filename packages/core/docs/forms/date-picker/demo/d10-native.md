---
order: 10
---

# Native inputs on phones

<EuiText>

On a phone or a tablet (a coarse primary pointer) and in a Capacitor app on a device, `EuiDatePicker` renders the operating system's input instead of the calendar: `<input type="date">`, `datetime-local` with `@showTimeSelect` (it holds the wall clock in `@timeZone`), or `time` with `@showTimeSelectOnly`. The arguments and the value strings are the same, so the app cannot tell which path ran. `@native` chooses: `'auto'` (the default) detects, `true` always takes the OS input, `false` always the calendar. On this page in a desktop browser, the first picker shows the calendar and the next three the OS input; on a phone the first four show the OS input.

The OS is not trusted with the limits: a value outside `@minDate` and `@maxDate` (or `@minTime` and `@maxTime`) stays in the input with the invalid look, `@onChange` is not called, and `@onInputError` is called once focus leaves the input. Try a day after the maximum below.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { concat } from '@ember/helper';
import {
  EuiCode,
  EuiDatePicker,
  EuiFormRow,
  EuiSpacer,
  EuiText,
} from '@ember-eui/core/components';

const pad = (n) => String(n).padStart(2, '0');
// the local day `n` days from today, YYYY-MM-DD
const day = (n = 0) => {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};

// now, on the hour
const now = new Date();
now.setMinutes(0, 0, 0);

export default class DatePickerNativeDemo extends Component {
  @tracked auto = day();
  @tracked date = day();
  @tracked startsAt = now.toISOString();
  @tracked opensAt = '09:30';
  @tracked calendar = day();
  @tracked lastError = null;

  minDate = day(-7);
  maxDate = day(30);

  set = (name) => (value) => {
    this.lastError = null;
    this[name] = value;
  };
  setAuto = this.set('auto');
  setDate = this.set('date');
  setStartsAt = this.set('startsAt');
  setOpensAt = this.set('opensAt');
  setCalendar = this.set('calendar');
  clearDate = () => (this.date = null);
  onInputError = (error) => (this.lastError = error);

  <template>
    <EuiFormRow @label="Auto, the default" @id="d10-auto">
      <EuiDatePicker
        @id="d10-auto"
        @value={{this.auto}}
        @onChange={{this.setAuto}}
        @onInputError={{this.onInputError}}
        @minDate={{this.minDate}}
        @maxDate={{this.maxDate}}
      />
    </EuiFormRow>
    <EuiText @size="s">
      <p>Value: <EuiCode data-test-value="native-auto">{{if this.auto this.auto "null"}}</EuiCode></p>
    </EuiText>

    <EuiSpacer />

    <EuiFormRow
      @label="Always native: a date, from a week ago to 30 days ahead"
      @id="d10-date"
    >
      <EuiDatePicker
        @id="d10-date"
        @native={{true}}
        @value={{this.date}}
        @onChange={{this.setDate}}
        @onClear={{this.clearDate}}
        @onInputError={{this.onInputError}}
        @minDate={{this.minDate}}
        @maxDate={{this.maxDate}}
      />
    </EuiFormRow>
    <EuiText @size="s">
      <p>Value: <EuiCode data-test-value="native-date">{{if this.date this.date "null"}}</EuiCode></p>
    </EuiText>

    <EuiSpacer />

    <EuiFormRow
      @label="Always native: a date and time in New York"
      @id="d10-date-time"
    >
      <EuiDatePicker
        @id="d10-date-time"
        @native={{true}}
        @value={{this.startsAt}}
        @onChange={{this.setStartsAt}}
        @onInputError={{this.onInputError}}
        @showTimeSelect={{true}}
        @timeZone="America/New_York"
      />
    </EuiFormRow>
    <EuiText @size="s">
      <p>Value: <EuiCode data-test-value="native-date-time">{{if this.startsAt this.startsAt "null"}}</EuiCode></p>
    </EuiText>

    <EuiSpacer />

    <EuiFormRow
      @label="Always native: a time from 08:00 to 18:00"
      @id="d10-time"
    >
      <EuiDatePicker
        @id="d10-time"
        @native={{true}}
        @value={{this.opensAt}}
        @onChange={{this.setOpensAt}}
        @onInputError={{this.onInputError}}
        @showTimeSelectOnly={{true}}
        @minTime="08:00"
        @maxTime="18:00"
      />
    </EuiFormRow>
    <EuiText @size="s">
      <p>Value: <EuiCode data-test-value="native-time">{{if this.opensAt this.opensAt "null"}}</EuiCode></p>
    </EuiText>

    <EuiSpacer />

    <EuiFormRow @label="Never native" @id="d10-calendar">
      <EuiDatePicker
        @id="d10-calendar"
        @native={{false}}
        @value={{this.calendar}}
        @onChange={{this.setCalendar}}
      />
    </EuiFormRow>

    <EuiSpacer />

    <EuiText @size="s">
      <p>
        Last input error:
        <EuiCode data-test-value="native-error">{{if
            this.lastError
            (concat this.lastError.reason " (" this.lastError.text ")")
            "none"
          }}</EuiCode>
      </p>
    </EuiText>
  </template>
}
```
