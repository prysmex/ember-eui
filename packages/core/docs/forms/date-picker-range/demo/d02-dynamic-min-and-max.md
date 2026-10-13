---
order: 2
---

# Dynamic min and max dates

<EuiText>

By using `min` and `max` on the date inputs, and updating the values based on the start and end dates, users get immediate feedback on what range values are allowed.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiDatePickerRange, EuiFieldText } from '@ember-eui/core/components';

const toInput = (date) => date.toISOString().slice(0, 10);
const now = new Date();
const twoYearsAgo = new Date(now.getFullYear() - 2, now.getMonth(), now.getDate());

export default class DatePickerRangeMinMaxDemo extends Component {
  minDate = toInput(twoYearsAgo);
  maxDate = toInput(now);

  @tracked startDate = toInput(twoYearsAgo);
  @tracked endDate = toInput(now);

  get isInvalid() {
    return (
      this.startDate > this.endDate ||
      this.startDate < this.minDate ||
      this.endDate > this.maxDate
    );
  }

  @action
  setStart(event) {
    this.startDate = event.target.value;
  }

  @action
  setEnd(event) {
    this.endDate = event.target.value;
  }

  <template>
    <EuiDatePickerRange @isInvalid={{this.isInvalid}}>
      <:start as |className|>
        <EuiFieldText
          @controlOnly={{true}}
          @value={{this.startDate}}
          @isInvalid={{this.isInvalid}}
          type="date"
          class={{className}}
          min={{this.minDate}}
          max={{this.endDate}}
          aria-label="Start date"
          {{on "input" this.setStart}}
        />
      </:start>
      <:end as |className|>
        <EuiFieldText
          @controlOnly={{true}}
          @value={{this.endDate}}
          @isInvalid={{this.isInvalid}}
          type="date"
          class={{className}}
          min={{this.startDate}}
          max={{this.maxDate}}
          aria-label="End date"
          {{on "input" this.setEnd}}
        />
      </:end>
    </EuiDatePickerRange>
  </template>
}
```
