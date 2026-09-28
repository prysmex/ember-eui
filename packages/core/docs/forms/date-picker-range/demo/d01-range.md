---
order: 1
---

# Start and end dates

<EuiText>

Two native date inputs. The end date must not be before the start date:
the inputs are marked invalid and the error is shown below.

</EuiText>

```hbs template
<EuiFormRow
  @label="Dates"
  @isInvalid={{this.isInvalid}}
  @error="The end date is before the start date."
>
  <EuiDatePickerRange>
    <:start as |className|>
      <EuiFieldText
        @controlOnly={{true}}
        @value={{this.start}}
        @isInvalid={{this.isInvalid}}
        type="date"
        class={{className}}
        aria-label="Start date"
        {{on "input" this.setStart}}
      />
    </:start>
    <:end as |className|>
      <EuiFieldText
        @controlOnly={{true}}
        @value={{this.end}}
        @isInvalid={{this.isInvalid}}
        type="date"
        class={{className}}
        aria-label="End date"
        {{on "input" this.setEnd}}
      />
    </:end>
  </EuiDatePickerRange>
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DateRangeDemo extends Component {
  @tracked start = '2026-03-01';
  @tracked end = '2026-03-15';

  get isInvalid() {
    return Boolean(this.start && this.end && this.end < this.start);
  }

  @action
  setStart(event) {
    this.start = event.target.value;
  }

  @action
  setEnd(event) {
    this.end = event.target.value;
  }
}
```
