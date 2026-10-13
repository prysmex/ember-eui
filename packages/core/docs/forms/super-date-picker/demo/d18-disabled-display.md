---
order: 18
---

# Disabled with a custom display

<EuiText>

`@isDisabled` also accepts `{ display }`: the picker is disabled and the dates are replaced by your own content, a string or a component. Upstream's tests use it for an "All time" range, which has no start or end.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiSpacer,
  EuiSuperDatePicker,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class SuperDatePickerDisabledDisplayDemo extends Component {
  @tracked allTime = true;
  @tracked start = 'now-15m';
  @tracked end = 'now';

  get isDisabled() {
    return this.allTime ? { display: 'All time' } : false;
  }

  @action
  toggleAllTime() {
    this.allTime = !this.allTime;
  }

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  <template>
    <EuiSwitch
      @label="All time (disabled with a custom display)"
      @checked={{this.allTime}}
      @onChange={{this.toggleAllTime}}
    />
    <EuiSpacer />
    <EuiSuperDatePicker
      @start={{this.start}}
      @end={{this.end}}
      @isDisabled={{this.isDisabled}}
      @onTimeChange={{this.onTimeChange}}
    />
  </template>
}
```
