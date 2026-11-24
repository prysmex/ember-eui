---
order: 3
---

# Time selection

<EuiText>

Two arguments control time selection: `@showTimeSelect` adds a time list beside the calendar, and `@showTimeSelectOnly` shows the time list alone. With `@showTimeSelect` the value is an instant, a UTC ISO string such as `2026-11-24T15:30:00.000Z`, shown and chosen as a wall clock in `@timeZone` (the browser's zone by default). With `@showTimeSelectOnly` the value is a time of day, `HH:mm`. `@timeIntervals` sets the minutes between the entries of the list (30 by default), and `@injectTimes` adds entries to it. A time can also be typed, at any minute: `15:45`, `3:45 pm`, `3 pm`.

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

// now, on the half hour
const now = new Date();
now.setMinutes(now.getMinutes() < 30 ? 0 : 30, 0, 0);

export default class DatePickerTimeSelectionDemo extends Component {
  @tracked startsAt = now.toISOString();
  @tracked opensAt = '09:30';
  @tracked meetingAt = now.toISOString();
  @tracked closesAt = '23:59';

  setStartsAt = (value) => (this.startsAt = value);
  setOpensAt = (value) => (this.opensAt = value);
  setMeetingAt = (value) => (this.meetingAt = value);
  setClosesAt = (value) => (this.closesAt = value);

  injected = ['00:01', '00:05', '23:59'];

  <template>
    <EuiFormRow @label="Select a date and time" @id="d03-date-time">
      <EuiDatePicker
        @id="d03-date-time"
        @value={{this.startsAt}}
        @onChange={{this.setStartsAt}}
        @showTimeSelect={{true}}
      />
    </EuiFormRow>
    <EuiText @size="s">
      <p>Value: <EuiCode data-test-value="date-time">{{if this.startsAt this.startsAt "null"}}</EuiCode></p>
    </EuiText>

    <EuiSpacer />

    <EuiFormRow @label="Only select a time" @id="d03-time">
      <EuiDatePicker
        @id="d03-time"
        @value={{this.opensAt}}
        @onChange={{this.setOpensAt}}
        @showTimeSelectOnly={{true}}
      />
    </EuiFormRow>
    <EuiText @size="s">
      <p>Value: <EuiCode data-test-value="time">{{if this.opensAt this.opensAt "null"}}</EuiCode></p>
    </EuiText>

    <EuiSpacer />

    <EuiFormRow @label="Every 15 minutes" @id="d03-intervals">
      <EuiDatePicker
        @id="d03-intervals"
        @native={{false}}
        @value={{this.meetingAt}}
        @onChange={{this.setMeetingAt}}
        @showTimeSelect={{true}}
        @timeIntervals={{15}}
      />
    </EuiFormRow>

    <EuiSpacer />

    <EuiFormRow @label="Inject additional times into the list" @id="d03-inject">
      <EuiDatePicker
        @id="d03-inject"
        @value={{this.closesAt}}
        @onChange={{this.setClosesAt}}
        @showTimeSelectOnly={{true}}
        @injectTimes={{this.injected}}
      />
    </EuiFormRow>
  </template>
}
```
