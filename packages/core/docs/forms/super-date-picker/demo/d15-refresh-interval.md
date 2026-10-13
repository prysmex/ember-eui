---
order: 15
---

# Refresh interval

<EuiText>

For even more customizability, you can use the `EuiRefreshInterval` component which simply provides the form inputs.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormRow, EuiRefreshInterval } from '@ember-eui/core/components';

export default class RefreshIntervalDemo extends Component {
  @tracked refreshInterval = 1000;
  @tracked isPaused = true;

  @action
  onRefreshChange({ isPaused, refreshInterval }) {
    this.isPaused = isPaused;
    this.refreshInterval = refreshInterval;
  }

  <template>
    <EuiFormRow>
      <EuiRefreshInterval
        @isPaused={{this.isPaused}}
        @refreshInterval={{this.refreshInterval}}
        @onRefreshChange={{this.onRefreshChange}}
      />
    </EuiFormRow>
  </template>
}
```
