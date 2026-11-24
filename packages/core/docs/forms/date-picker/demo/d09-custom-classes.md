---
order: 9
---

# Custom classes

<EuiText>

Custom classes can be passed to various bits of the calendar and input.

- `class` goes onto the input (with every other attribute).
- `@calendarClass` goes onto the calendar itself.
- `@dayClassName` is called with each day (`YYYY-MM-DD`) and returns classes for it.
- `@popoverClass` goes onto the popover panel.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { euiPaletteColorBlind } from '@ember-eui/core/utils/color';
import {
  EuiDatePicker,
  EuiFormRow,
  EuiSpacer,
} from '@ember-eui/core/components';

const pad = (n) => String(n).padStart(2, '0');
const now = new Date();
const today = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
const visColor = euiPaletteColorBlind()[3];

export default class DatePickerCustomClassesDemo extends Component {
  @tracked startDate = today;

  styles = htmlSafe(
    `.d09-background { background-color: ${visColor}; }
     .d09-outline { outline: solid 2px ${visColor}; }`,
  );

  handleChange = (date) => {
    this.startDate = date;
  };

  // the 1st to the 10th of every month
  dayClassName = (date) =>
    Number(date.slice(8, 10)) <= 10 ? 'd09-background' : undefined;

  <template>
    <style>{{this.styles}}</style>

    <EuiFormRow @label="class example" @id="d09-class">
      <EuiDatePicker
        @id="d09-class"
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        class="d09-outline"
      />
    </EuiFormRow>

    <EuiSpacer @size="m" />

    <EuiFormRow @label="calendarClass example" @id="d09-calendar">
      <EuiDatePicker
        @id="d09-calendar"
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @calendarClass="d09-background"
      />
    </EuiFormRow>

    <EuiSpacer @size="m" />

    <EuiFormRow @label="dayClassName example" @id="d09-day">
      <EuiDatePicker
        @id="d09-day"
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @dayClassName={{this.dayClassName}}
      />
    </EuiFormRow>

    <EuiSpacer @size="m" />

    <EuiFormRow @label="popoverClass example" @id="d09-popover">
      <EuiDatePicker
        @id="d09-popover"
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @popoverClass="d09-outline"
      />
    </EuiFormRow>
  </template>
}
```
