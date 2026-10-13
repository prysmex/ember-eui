---
order: 14
---

# Auto refresh button

<EuiText>

If you're looking for a more compact version, you can use `EuiAutoRefreshButton`, which is the same button that is appended to `EuiSuperDatePicker`. For even more compactness, add `@shortHand={{true}}` to reduce the active unit to a single letter.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiAutoRefreshButton } from '@ember-eui/core/components';

export default class AutoRefreshButtonDemo extends Component {
  @tracked refreshInterval = 3000;
  @tracked isPaused = false;

  @action
  onRefreshChange({ isPaused, refreshInterval }) {
    this.isPaused = isPaused;
    this.refreshInterval = refreshInterval;
  }

  <template>
    <EuiAutoRefreshButton
      @isPaused={{this.isPaused}}
      @refreshInterval={{this.refreshInterval}}
      @onRefreshChange={{this.onRefreshChange}}
      @shortHand={{true}}
    />
  </template>
}
```
