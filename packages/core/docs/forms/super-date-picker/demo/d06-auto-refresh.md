---
order: 6
---

# Auto refresh

<EuiText>

By supplying an action to `@onRefreshChange`, the `EuiSuperDatePicker` will display the `@refreshInterval` configuration UI in the **Quick select menu**.

By default the refresh interval units are rounded up to the next largest unit of time (90 seconds becomes 2 minutes). To keep the unit the user picked, store the `intervalUnits` that `@onRefreshChange` receives and pass it back with `@refreshIntervalUnits`. In Ember EUI, `intervalUnits` is part of `@onRefreshChange`'s payload once the picker is given `@refreshIntervalUnits` (even `undefined`), so existing callers keep their `{ refreshInterval, isPaused }` payload.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSuperDatePicker, EuiSwitch } from '@ember-eui/core/components';

export default class SuperDatePickerRefreshDemo extends Component {
  @tracked doNotRoundUnits = false;
  @tracked intervalUnits;
  @tracked refreshInterval = 1000;
  @tracked isPaused = true;
  @tracked start = 'now-30m';
  @tracked end = 'now';

  get refreshIntervalUnits() {
    return this.doNotRoundUnits ? this.intervalUnits : undefined;
  }

  @action
  toggleRounding() {
    this.doNotRoundUnits = !this.doNotRoundUnits;
  }

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  @action
  onRefresh({ start, end, refreshInterval }) {
    return new Promise((resolve) => {
      setTimeout(resolve, 100);
    }).then(() => {
      console.log(start, end, refreshInterval);
    });
  }

  @action
  onRefreshChange({ isPaused, refreshInterval, intervalUnits }) {
    this.isPaused = isPaused;
    this.refreshInterval = refreshInterval;
    this.intervalUnits = intervalUnits;
  }

  <template>
    <EuiSuperDatePicker
      @start={{this.start}}
      @end={{this.end}}
      @onTimeChange={{this.onTimeChange}}
      @onRefresh={{this.onRefresh}}
      @isPaused={{this.isPaused}}
      @onRefreshChange={{this.onRefreshChange}}
      @refreshInterval={{this.refreshInterval}}
      @refreshIntervalUnits={{this.refreshIntervalUnits}}
    >
      <:customQuickSelectRender as |panels|>
        <EuiSwitch
          @label="Round refresh interval up to the next largest unit"
          @checked={{if this.doNotRoundUnits false true}}
          @onChange={{this.toggleRounding}}
          @compressed={{true}}
        />
        <panels.refreshInterval />
      </:customQuickSelectRender>
    </EuiSuperDatePicker>
  </template>
}
```
