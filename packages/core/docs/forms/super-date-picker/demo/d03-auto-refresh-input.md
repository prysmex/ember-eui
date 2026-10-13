---
order: 3
---

# Auto refresh input

<EuiText>

`EuiAutoRefresh` is a read-only input showing the refresh state ("Off" or
"5 seconds") with an "Auto refresh" button. Both open a popover with
`EuiRefreshInterval`. The component does not run a timer: keep `@isPaused` and
`@refreshInterval` in sync from `@onRefreshChange` and refresh your data at
that interval, as the counter below does. By default the unit is rounded up
(90 seconds shows as 2 minutes); pass `@intervalUnits` to fix it, and
`@minInterval` (in milliseconds) to set a floor.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiAutoRefresh, EuiSpacer, EuiText } from '@ember-eui/core/components';

export default class AutoRefreshInputDemo extends Component {
  @tracked isPaused = true;
  @tracked refreshInterval = 5000;
  @tracked intervalUnits = undefined;
  @tracked refreshes = 0;

  timer = null;

  willDestroy() {
    super.willDestroy(...arguments);
    clearInterval(this.timer);
  }

  @action
  onRefreshChange({ isPaused, refreshInterval, intervalUnits }) {
    this.isPaused = isPaused;
    this.refreshInterval = refreshInterval;
    this.intervalUnits = intervalUnits;

    clearInterval(this.timer);
    if (!isPaused) {
      this.timer = setInterval(() => this.refreshes++, refreshInterval);
    }
  }

  <template>
    <EuiAutoRefresh
      @isPaused={{this.isPaused}}
      @refreshInterval={{this.refreshInterval}}
      @intervalUnits={{this.intervalUnits}}
      @minInterval={{1000}}
      @onRefreshChange={{this.onRefreshChange}}
    />
    <EuiSpacer />
    <EuiText @size="s">
      <p>Refreshed {{this.refreshes}} times.</p>
    </EuiText>
  </template>
}
```
