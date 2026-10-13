---
order: 5
---

# Auto refresh

<EuiText>

By supplying an action to `@onRefreshChange`, the `EuiSuperDatePicker` will display the `@refreshInterval` configuration UI in the **Quick select menu**.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSuperDatePicker } from '@ember-eui/core/components';

export default class SuperDatePickerRefreshDemo extends Component {
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
      @onRefreshChange={{this.onRefreshChange}}
      @refreshInterval={{this.refreshInterval}}
    />
  </template>
}
```
