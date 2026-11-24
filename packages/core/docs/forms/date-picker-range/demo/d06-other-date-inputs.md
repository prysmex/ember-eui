---
order: 6
---

# Other date inputs (Ember EUI extra)

<EuiText>

The range only lays out what is in its blocks, so any date input works: here two native `<EuiFieldText type="date">` inputs, with `min` and `max` following each other. `EuiFlatpickr` and `EuiPikaday` work the same way. Render each input with `@controlOnly={{true}}` and the class its block yields. These inputs do not read the range's states: pass `@isInvalid`, `@disabled` and the rest to them as well.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiDatePickerRange, EuiFieldText } from '@ember-eui/core/components';

export default class DatePickerRangeNativeDemo extends Component {
  @tracked startDate = '2026-03-01';
  @tracked endDate = '2026-03-15';

  get isInvalid() {
    return Boolean(this.startDate && this.endDate && this.endDate < this.startDate);
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
          aria-label="End date"
          {{on "input" this.setEnd}}
        />
      </:end>
    </EuiDatePickerRange>
  </template>
}
```
