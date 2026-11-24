---
order: 7.6
---

# UTC offsets

<EuiText>

Upstream's `utcOffset` is `@timeZone` with a fixed offset from UTC: `'-01:00'`, `'+05:30'`. A fixed offset has no daylight saving time, so every wall clock exists exactly once. Here the select applies an offset to a date and time: the input and the time list move, the value (an instant) does not. The `Etc/GMT±N` IANA names are fixed offsets too, but with the sign inverted: `Etc/GMT+3` is UTC−03:00.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  EuiCode,
  EuiDatePicker,
  EuiFormRow,
  EuiSelect,
  EuiSpacer,
  EuiText,
} from '@ember-eui/core/components';

const now = new Date();
now.setMinutes(now.getMinutes() < 30 ? 0 : 30, 0, 0);

export default class DatePickerUtcOffsetsDemo extends Component {
  options = [
    { value: '-01:00', text: 'GMT -01:00' },
    { value: '-02:00', text: 'GMT -02:00' },
    { value: '-03:00', text: 'GMT -03:00' },
  ];

  @tracked startDate = now.toISOString();
  @tracked utcOffset = '-01:00';

  handleChange = (value) => (this.startDate = value);
  onSelectChange = (event) => (this.utcOffset = event.target.value);

  <template>
    <EuiFormRow @label="Select a date" @id="d12-date">
      <EuiDatePicker
        @id="d12-date"
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @showTimeSelect={{true}}
        @timeZone={{this.utcOffset}}
      />
    </EuiFormRow>

    <EuiSpacer @size="m" />

    <EuiFormRow @label="Select an offset" @id="d12-offset">
      <EuiSelect
        @id="d12-offset"
        @options={{this.options}}
        @value={{this.utcOffset}}
        {{on "change" this.onSelectChange}}
      />
    </EuiFormRow>
    <EuiText @size="s">
      <p>Value: <EuiCode data-test-value="offsets">{{if this.startDate this.startDate "null"}}</EuiCode></p>
    </EuiText>
  </template>
}
```
