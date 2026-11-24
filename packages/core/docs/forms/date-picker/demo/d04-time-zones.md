---
order: 4
---

# Time zones

<EuiText>

`@timeZone` is the zone the picker shows and chooses instants in: `'local'` (the default), `'utc'`, an IANA name such as `'America/New_York'`, or a fixed offset (next to "UTC offsets" below). The value stays the same instant whatever the zone; changing the zone only changes the wall clock shown, and emits nothing. On a day with a daylight saving change, the time list leaves out the times that do not exist (spring) and lists each repeated time once, at its first occurrence (autumn). A typed time that does not exist moves forward by the gap: `02:30` on the New York spring day becomes `03:30`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  EuiButtonEmpty,
  EuiCode,
  EuiDatePicker,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
  EuiSelect,
  EuiText,
} from '@ember-eui/core/components';

export default class DatePickerTimeZonesDemo extends Component {
  zones = [
    { value: 'local', text: 'The browser’s zone (local)' },
    { value: 'utc', text: 'UTC' },
    { value: 'America/New_York', text: 'America/New_York' },
    { value: 'America/Mexico_City', text: 'America/Mexico_City (no DST)' },
    { value: 'Europe/Madrid', text: 'Europe/Madrid' },
    { value: 'Asia/Kolkata', text: 'Asia/Kolkata (UTC+05:30)' },
    { value: 'Australia/Lord_Howe', text: 'Australia/Lord_Howe (a 30-minute DST)' },
  ];

  @tracked zone = 'America/New_York';
  @tracked value = '2026-03-08T06:00:00.000Z';

  setValue = (value) => (this.value = value);
  setZone = (event) => (this.zone = event.target.value);
  springForward = () => (this.value = '2026-03-08T06:00:00.000Z');
  fallBack = () => (this.value = '2026-11-01T04:00:00.000Z');

  <template>
    <EuiFormRow @label="Time zone" @id="d04-zone">
      <EuiSelect
        @id="d04-zone"
        @options={{this.zones}}
        @value={{this.zone}}
        {{on "change" this.setZone}}
      />
    </EuiFormRow>
    <EuiFormRow @label="Select a date and time" @id="d04-date-time">
      <EuiDatePicker
        @id="d04-date-time"
        @value={{this.value}}
        @onChange={{this.setValue}}
        @showTimeSelect={{true}}
        @timeZone={{this.zone}}
      />
    </EuiFormRow>
    <EuiFlexGroup @gutterSize="s" @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiButtonEmpty @size="xs" @flush="left" {{on "click" this.springForward}}>
          New York springs forward (8 March 2026)
        </EuiButtonEmpty>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButtonEmpty @size="xs" {{on "click" this.fallBack}}>
          New York falls back (1 November 2026)
        </EuiButtonEmpty>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiText @size="s">
      <p>Value: <EuiCode data-test-value="zones">{{if this.value this.value "null"}}</EuiCode></p>
    </EuiText>
  </template>
}
```
