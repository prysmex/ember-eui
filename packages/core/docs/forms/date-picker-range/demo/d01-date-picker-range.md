---
order: 1
---

# Date picker range

<EuiText>

To create a single date range control, use `EuiDatePickerRange` and put the individual date inputs in its `<:start>` and `<:end>` blocks. Each block yields the class to put on the control. You can control the state of both inputs as direct arguments on `EuiDatePickerRange` as well as control each individually.

Ember EUI's core package has no `EuiDatePicker` (calendar popover); the examples use native date inputs. The calendar engines live in the `@ember-eui/flatpickr` and `@ember-eui/pikaday` packages.

If you need even more functionality such as relative time, suggested date ranges, and refresh intervals, consider using `EuiSuperDatePicker`.

The switches above the control are docs-only helpers that toggle its display arguments.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn, get } from '@ember/helper';
import {
  EuiDatePickerRange,
  EuiFieldText,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

const toInput = (date) => date.toISOString().slice(0, 10);
const today = new Date();
const later = new Date(today.getTime() + 11 * 24 * 60 * 60 * 1000);

export default class DatePickerRangeDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'readOnly', label: 'readOnly' },
    { key: 'disabled', label: 'disabled' },
  ];

  @tracked flags = {};
  @tracked startDate = toInput(today);
  @tracked endDate = toInput(later);

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
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
    <EuiFlexGroup @wrap={{true}} @gutterSize="m" @responsive={{false}}>
      {{#each this.toggles as |toggle|}}
        <EuiFlexItem @grow={{false}}>
          <EuiSwitch
            @label={{toggle.label}}
            @compressed={{true}}
            @checked={{get this.flags toggle.key}}
            @onChange={{fn this.toggle toggle.key}}
          />
        </EuiFlexItem>
      {{/each}}
    </EuiFlexGroup>
    <EuiSpacer @size="m" />
    <EuiDatePickerRange
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @isLoading={{this.flags.isLoading}}
      @readOnly={{this.flags.readOnly}}
      @disabled={{this.flags.disabled}}
    >
      <:start as |className|>
        <EuiFieldText
          @controlOnly={{true}}
          @value={{this.startDate}}
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
