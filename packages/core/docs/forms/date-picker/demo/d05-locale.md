---
order: 5
---

# Locale

<EuiText>

`@locale` takes a BCP 47 tag. It sets the month and weekday names (from the browser's `Intl`), the first day of the week and the order of the day, month and year. Without it, the picker uses the page's `lang`, then the browser's language. `@dateOrder` (`'dmy'`, `'mdy'` or `'ymd'`) and `@firstDayOfWeek` (`0` for Sunday to `6`) override the locale's. Nothing has to be loaded per locale.

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
const now = new Date();
const today = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;

export default class DatePickerLocaleDemo extends Component {
  @tracked startDate = today;

  handleChange = (date) => {
    this.startDate = date;
  };

  <template>
    <EuiFormRow @label="US" @id="d05-us">
      <EuiDatePicker
        @id="d05-us"
        @native={{false}}
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @locale="en-US"
      />
    </EuiFormRow>

    <EuiSpacer @size="m" />

    <EuiFormRow @label="China" @id="d05-cn">
      <EuiDatePicker
        @id="d05-cn"
        @native={{false}}
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @locale="zh-CN"
      />
    </EuiFormRow>

    <EuiSpacer @size="m" />

    <EuiFormRow @label="Korea" @id="d05-ko">
      <EuiDatePicker
        @id="d05-ko"
        @native={{false}}
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @locale="ko"
      />
    </EuiFormRow>

    <EuiSpacer @size="m" />

    <EuiFormRow @label="Germany, week from Monday" @id="d05-de">
      <EuiDatePicker
        @id="d05-de"
        @native={{false}}
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @locale="de"
      />
    </EuiFormRow>

    <EuiSpacer @size="m" />

    <EuiFormRow @label="Mexico, typed as year-month-day, week from Sunday" @id="d05-mx">
      <EuiDatePicker
        @id="d05-mx"
        @native={{false}}
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @locale="es-MX"
        @dateOrder="ymd"
        @firstDayOfWeek={{0}}
      />
    </EuiFormRow>
  </template>
}
```
