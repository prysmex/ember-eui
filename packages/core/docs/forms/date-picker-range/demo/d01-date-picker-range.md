---
order: 1
---

# Date picker range

<EuiText>

To create a single date range control, use `EuiDatePickerRange` and put an `EuiDatePicker` in each of its `<:start>` and `<:end>` blocks, with the class the block yields. The pickers take the range's states by themselves: set `@fullWidth`, `@compressed`, `@isInvalid`, `@isLoading`, `@readOnly` and `@disabled` on the range, or `@disabled` and `@isInvalid` on one picker. Give both pickers `@startDate` and `@endDate` to highlight the range in their calendars, and `@selectsStart` or `@selectsEnd` to preview it while you hover.

If you need even more functionality such as relative time, suggested date ranges, and refresh intervals, consider using `EuiSuperDatePicker`.

The switches above the control are docs-only helpers that toggle its display arguments.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, get } from '@ember/helper';
import {
  EuiDatePicker,
  EuiDatePickerRange,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

const pad = (n) => String(n).padStart(2, '0');
const dayOf = (date) =>
  `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
const today = new Date();
const later = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 11);

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
  @tracked startDate = dayOf(today);
  @tracked endDate = dayOf(later);

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  setStart = (date) => {
    if (date) this.startDate = date;
  };

  setEnd = (date) => {
    if (date) this.endDate = date;
  };

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
        <EuiDatePicker
          class={{className}}
          aria-label="Start date"
          @value={{this.startDate}}
          @onChange={{this.setStart}}
          @selectsStart={{true}}
          @startDate={{this.startDate}}
          @endDate={{this.endDate}}
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
        />
      </:end>
    </EuiDatePickerRange>
  </template>
}
```
