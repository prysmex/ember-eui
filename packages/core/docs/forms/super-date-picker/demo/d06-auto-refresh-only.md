---
order: 6
---

# Auto refresh only

<EuiText>

Set `@isAutoRefreshOnly={{true}}` to limit the component to only display auto refresh content. This is useful in cases where there is no time data but auto-refresh configuration is still desired.

However, since this is still the full `EuiSuperDatePicker` component it requires other arguments that may not be necessary for the refresh only UI. In this case, you can use the `EuiAutoRefresh` component instead (see the following examples).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSuperDatePicker } from '@ember-eui/core/components';

export default class SuperDatePickerRefreshOnlyDemo extends Component {
  @tracked refreshInterval = 1000;
  @tracked isPaused = true;
  @tracked start = 'now-30m';
  @tracked end = 'now';

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
  onRefreshChange({ isPaused, refreshInterval }) {
    this.isPaused = isPaused;
    this.refreshInterval = refreshInterval;
  }

  <template>
    <EuiSuperDatePicker
      @start={{this.start}}
      @end={{this.end}}
      @onTimeChange={{this.onTimeChange}}
      @onRefresh={{this.onRefresh}}
      @isPaused={{this.isPaused}}
      @refreshInterval={{this.refreshInterval}}
      @onRefreshChange={{this.onRefreshChange}}
      @isAutoRefreshOnly={{true}}
    />
  </template>
}
```
