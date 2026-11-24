---
order: 2
---

# Inline display

<EuiText>

Use `@inline={{true}}` to display the date pickers directly in the page instead of inside a popover. If you do not need the default inline shadow effect, add `@shadow={{false}}`.

`@inline` drops the field frame, the icon, `@fullWidth` and `@compressed`, lays the two calendars out side by side and stacks them when the container is too narrow. The pickers in the blocks become inline by themselves, and a picker with `@showTimeSelect` makes the range stack them below a wider container. Here the values are `Date` objects, which the picker reads as well as strings; `@onChange` gets a string, turned back into a `Date`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiDatePicker,
  EuiDatePickerRange,
  EuiFlexGroup,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

const today = new Date();
// `YYYY-MM-DD` is a local day; an instant is an instant
const toDate = (value) => {
  if (!value) return null;
  if (value.length > 10) return new Date(value);
  const [year, month, day] = value.split('-').map(Number);
  return new Date(year, month - 1, day);
};

export default class DatePickerRangeInlineDemo extends Component {
  @tracked shadow = true;
  @tracked showTimeSelect = false;
  @tracked startDate = today;
  @tracked endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 11);

  @action
  toggleShadow() {
    this.shadow = !this.shadow;
  }

  @action
  toggleTimeSelect() {
    this.showTimeSelect = !this.showTimeSelect;
  }

  setStart = (value) => {
    if (value) this.startDate = toDate(value);
  };

  setEnd = (value) => {
    if (value) this.endDate = toDate(value);
  };

  <template>
    <EuiFlexGroup>
      <EuiSwitch
        @label="Show shadow"
        @checked={{this.shadow}}
        @onChange={{this.toggleShadow}}
      />
      <EuiSwitch
        @label="Show time select"
        @checked={{this.showTimeSelect}}
        @onChange={{this.toggleTimeSelect}}
      />
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiDatePickerRange @inline={{true}} @shadow={{this.shadow}}>
      <:start as |className|>
        <EuiDatePicker
          class={{className}}
          aria-label="Start date"
          @value={{this.startDate}}
          @onChange={{this.setStart}}
          @showTimeSelect={{this.showTimeSelect}}
          @selectsStart={{true}}
          @startDate={{this.startDate}}
          @endDate={{this.endDate}}
          @maxDate={{this.endDate}}
        />
      </:start>
      <:end as |className|>
        <EuiDatePicker
          class={{className}}
          aria-label="End date"
          @value={{this.endDate}}
          @onChange={{this.setEnd}}
          @showTimeSelect={{this.showTimeSelect}}
          @selectsEnd={{true}}
          @startDate={{this.startDate}}
          @endDate={{this.endDate}}
          @minDate={{this.startDate}}
        />
      </:end>
    </EuiDatePickerRange>
  </template>
}
```
