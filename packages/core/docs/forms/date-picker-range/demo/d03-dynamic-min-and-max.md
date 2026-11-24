---
order: 3
---

# Dynamic `minDate` and `maxDate`

<EuiText>

By using `@minDate` and `@maxDate`, and updating the values based on the start and end dates, users get immediate feedback on what range values are allowed: the start picker cannot go past the end, the end picker cannot go before the start, and neither can leave the last two years.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiDatePicker, EuiDatePickerRange } from '@ember-eui/core/components';

const pad = (n) => String(n).padStart(2, '0');
const dayOf = (date) =>
  `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
const now = new Date();
const twoYearsAgo = new Date(now.getFullYear() - 2, now.getMonth(), now.getDate());

export default class DatePickerRangeMinMaxDemo extends Component {
  minDate = dayOf(twoYearsAgo);
  maxDate = dayOf(now);

  @tracked startDate = dayOf(twoYearsAgo);
  @tracked endDate = dayOf(now);

  get isInvalid() {
    return (
      this.startDate > this.endDate ||
      this.startDate < this.minDate ||
      this.endDate > this.maxDate
    );
  }

  setStart = (date) => {
    if (date) this.startDate = date;
  };

  setEnd = (date) => {
    if (date) this.endDate = date;
  };

  <template>
    <EuiDatePickerRange @isInvalid={{this.isInvalid}}>
      <:start as |className|>
        <EuiDatePicker
          class={{className}}
          aria-label="Start date"
          @value={{this.startDate}}
          @onChange={{this.setStart}}
          @selectsStart={{true}}
          @startDate={{this.startDate}}
          @endDate={{this.endDate}}
          @minDate={{this.minDate}}
          @maxDate={{this.endDate}}
        />
      </:start>
      <:end as |className|>
        <EuiDatePicker
          class={{className}}
          aria-label="End date"
          @value={{this.endDate}}
          @onChange={{this.setEnd}}
          @selectsEnd={{true}}
          @startDate={{this.startDate}}
          @endDate={{this.endDate}}
          @minDate={{this.startDate}}
          @maxDate={{this.maxDate}}
        />
      </:end>
    </EuiDatePickerRange>
  </template>
}
```
