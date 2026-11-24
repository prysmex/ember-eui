---
order: 8
---

# Inline display

<EuiText>

Use `@inline={{true}}` to display the date picker directly in the page instead of inside a popover. If you do not need the default inline shadow effect, add `@shadow={{false}}`. The other switches toggle the states an inline picker shows: the spinner and the invalid icon below the calendar, a disabled or read-only calendar.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, get } from '@ember/helper';
import {
  EuiDatePicker,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

const pad = (n) => String(n).padStart(2, '0');
const now = new Date();
const today = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;

export default class DatePickerInlineDemo extends Component {
  toggles = [
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'readOnly', label: 'readOnly' },
    { key: 'disabled', label: 'disabled' },
  ];

  @tracked shadow = true;
  @tracked flags = {};
  @tracked startDate = today;

  @action
  toggleShadow() {
    this.shadow = !this.shadow;
  }

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  handleChange = (date) => {
    if (date) this.startDate = date;
  };

  <template>
    <EuiFlexGroup>
      <EuiSwitch
        @label="Show shadow"
        @checked={{this.shadow}}
        @onChange={{this.toggleShadow}}
      />
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiFlexGroup @wrap={{true}} @gutterSize="m">
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
    <EuiSpacer @size="s" />
    <EuiDatePicker
      @value={{this.startDate}}
      @onChange={{this.handleChange}}
      @inline={{true}}
      @shadow={{this.shadow}}
      @isInvalid={{this.flags.isInvalid}}
      @isLoading={{this.flags.isLoading}}
      @readOnly={{this.flags.readOnly}}
      @disabled={{this.flags.disabled}}
    />
  </template>
}
```
