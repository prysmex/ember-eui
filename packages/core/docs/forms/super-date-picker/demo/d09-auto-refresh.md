---
order: 9
---

# Auto refresh component

<EuiText>

`EuiAutoRefresh` is used by `EuiSuperDatePicker` to create an automatic refresh configuration. It merely provides a common UI pattern but the actual refresh counter is maintained by you. It is `@isPaused` by default and the `@refreshInterval` is set in milliseconds.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiAutoRefresh } from '@ember-eui/core/components';

export default class AutoRefreshDemo extends Component {
  @tracked refreshInterval = 1000;
  @tracked isPaused = true;

  @action
  onRefreshChange({ isPaused, refreshInterval }) {
    this.isPaused = isPaused;
    this.refreshInterval = refreshInterval;
  }

  <template>
    <EuiAutoRefresh
      @isPaused={{this.isPaused}}
      @refreshInterval={{this.refreshInterval}}
      @onRefreshChange={{this.onRefreshChange}}
    />
  </template>
}
```
