---
order: 1
---

# Nested providers

<EuiText>

The panel below is wrapped in its own provider, so it can be dark while the rest of the page is not.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiEmotionProvider,
  EuiPanel,
  EuiSpacer,
  EuiSwitch,
  EuiText
} from '@ember-eui/core/components';

export default class ProviderDemo extends Component {
  @tracked isDark = true;

  @action
  toggle() {
    this.isDark = !this.isDark;
  }

  <template>
    <div>
      <EuiSwitch @label='Dark panel' @checked={{this.isDark}} @onChange={{this.toggle}} />
      <EuiSpacer />
      <EuiEmotionProvider @colorMode={{if this.isDark 'dark' 'light'}}>
        <EuiPanel>
          <EuiText>This panel follows its own provider's color mode.</EuiText>
        </EuiPanel>
      </EuiEmotionProvider>
    </div>
  </template>
}
```
