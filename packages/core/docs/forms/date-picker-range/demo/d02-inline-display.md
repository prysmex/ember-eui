---
order: 2
---

# Inline display

<EuiText>

Use `@inline={{true}}` to display the date pickers directly in the page instead of inside a popover. If you do not need the default inline shadow effect, add `@shadow={{false}}`.

`@inline` drops the field frame, the icon, `@fullWidth` and `@compressed`, lays the two blocks out side by side and stacks them when the container is too narrow. Ember EUI's core has no calendar, so pass the inline option to the calendars you render in the blocks too: this example uses `EuiFlatpickr` from `@ember-eui/flatpickr` with `@inline={{true}}`. Upstream's "Show time select" toggle is left out: the stacking breakpoint follows react-datepicker's width with or without the time list, which Ember EUI can't detect from the blocks.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiDatePickerRange,
  EuiFlexGroup,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';
import EuiFlatpickr from '@ember-eui/flatpickr/components/eui-flatpickr';

const DAY = 24 * 60 * 60 * 1000;

export default class DatePickerRangeInlineDemo extends Component {
  @tracked shadow = true;
  @tracked startDate = new Date();
  @tracked endDate = new Date(Date.now() + 11 * DAY);

  @action
  toggleShadow() {
    this.shadow = !this.shadow;
  }

  @action
  setStart([date]) {
    if (date) this.startDate = date;
  }

  @action
  setEnd([date]) {
    if (date) this.endDate = date;
  }

  <template>
    <EuiFlexGroup>
      <EuiSwitch
        @label="Show shadow"
        @checked={{this.shadow}}
        @onChange={{this.toggleShadow}}
      />
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiDatePickerRange @inline={{true}} @shadow={{this.shadow}}>
      <:start as |className|>
        <div class={{className}}>
          <EuiFlatpickr
            @date={{this.startDate}}
            @onChange={{this.setStart}}
            @inline={{true}}
            @maxDate={{this.endDate}}
            @controlOnly={{true}}
            @ariaLabel="Start date"
          />
        </div>
      </:start>
      <:end as |className|>
        <div class={{className}}>
          <EuiFlatpickr
            @date={{this.endDate}}
            @onChange={{this.setEnd}}
            @inline={{true}}
            @minDate={{this.startDate}}
            @controlOnly={{true}}
            @ariaLabel="End date"
          />
        </div>
      </:end>
    </EuiDatePickerRange>
  </template>
}
```
