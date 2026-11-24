---
order: 5
---

# Prepend, append and icon side

<EuiText>

The <EuiCode>&lt;:prepend&gt;</EuiCode> and <EuiCode>&lt;:append&gt;</EuiCode> blocks (upstream <EuiCode>prepend</EuiCode> / <EuiCode>append</EuiCode>) add content around the inputs; they yield the class to put on it. <EuiCode>@iconSide="right"</EuiCode> moves an <EuiCode>@iconType</EuiCode> to the right. With <EuiCode>@isCustom</EuiCode>, the start and end blocks yield only the delimited input class and pass nothing to the pickers, for controls styled on their own. Inline ranges ignore the prepend and append.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import {
  EuiDatePicker,
  EuiDatePickerRange,
  EuiFormAppend,
  EuiFormPrepend,
} from '@ember-eui/core/components';

export default class DatePickerRangePrependAppendDemo extends Component {
  @tracked start = null;
  @tracked end = null;

  setStart = (date) => {
    this.start = date;
  };

  setEnd = (date) => {
    this.end = date;
  };

  <template>
    <EuiDatePickerRange @iconType="clock" @iconSide="right">
      <:prepend>
        <EuiFormPrepend @label="Window" />
      </:prepend>
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
      <:append>
        <EuiFormAppend @label="UTC" />
      </:append>
    </EuiDatePickerRange>
  </template>
}
```
