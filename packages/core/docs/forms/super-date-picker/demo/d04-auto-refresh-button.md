---
order: 4
---

# Auto refresh button

<EuiText>

`EuiAutoRefreshButton` is the compact version: an empty button showing the
state, with a tooltip that reads "Auto refresh is off" or "Auto refresh is on
and set to 5 seconds". Use `@shortHand` for a single-letter unit, and
`@size`, `@color` or `@isDisabled` like `EuiButtonEmpty`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFlexGroup, EuiFlexItem, EuiAutoRefreshButton } from '@ember-eui/core/components';

export default class AutoRefreshButtonDemo extends Component {
  @tracked isPaused = true;
  @tracked refreshInterval = 120000;

  @action
  onRefreshChange({ isPaused, refreshInterval }) {
    this.isPaused = isPaused;
    this.refreshInterval = refreshInterval;
  }

  <template>
    <EuiFlexGroup @alignItems="center" @gutterSize="l" @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiAutoRefreshButton
          @isPaused={{this.isPaused}}
          @refreshInterval={{this.refreshInterval}}
          @onRefreshChange={{this.onRefreshChange}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiAutoRefreshButton
          @isPaused={{this.isPaused}}
          @refreshInterval={{this.refreshInterval}}
          @shortHand={{true}}
          @onRefreshChange={{this.onRefreshChange}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiAutoRefreshButton
          @isDisabled={{true}}
          @onRefreshChange={{this.onRefreshChange}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
