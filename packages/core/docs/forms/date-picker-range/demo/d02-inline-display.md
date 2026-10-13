---
order: 2
---

# Inline display

<EuiText>

Use `@inline={{true}}` to display the date pickers directly in the page instead of inside a popover. If you do not need the default inline shadow effect, add `@shadow={{false}}`.

`@inline` drops the field frame, the icon, `@fullWidth` and `@compressed`, lays the two blocks out side by side and stacks them when the container is too narrow. Ember EUI's core has no calendar, so pass the inline option to the calendars you render in the blocks too: this example uses `EuiFlatpickr` from `@ember-eui/flatpickr` with `@inline={{true}}`. When the calendars show a time list, pass `@showTimeSelect={{true}}` to the range too: upstream reads `showTimeSelect` from its date pickers to stack them below a wider container, and Ember EUI can't inspect its blocks. Here the switch turns on flatpickr's `@enableTime` and the range's `@showTimeSelect` together.

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
  @tracked showTimeSelect = false;
  @tracked startDate = new Date();
  @tracked endDate = new Date(Date.now() + 11 * DAY);

  @action
  toggleShadow() {
    this.shadow = !this.shadow;
  }

  @action
  toggleTimeSelect() {
    this.showTimeSelect = !this.showTimeSelect;
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
      <EuiSwitch
        @label="Show time select"
        @checked={{this.showTimeSelect}}
        @onChange={{this.toggleTimeSelect}}
      />
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiDatePickerRange
      @inline={{true}}
      @shadow={{this.shadow}}
      @showTimeSelect={{this.showTimeSelect}}
    >
      <:start as |className|>
        <div class={{className}}>
          <EuiFlatpickr
            @date={{this.startDate}}
            @onChange={{this.setStart}}
            @inline={{true}}
            @enableTime={{this.showTimeSelect}}
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
            @enableTime={{this.showTimeSelect}}
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
