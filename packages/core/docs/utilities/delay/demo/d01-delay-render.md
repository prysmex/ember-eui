---
order: 1
---

# Delay render

<EuiText>

Each button loads for a different time. The spinner only appears for
loads longer than the 500ms delay.

</EuiText>

```hbs template
<EuiFlexGroup @alignItems="center" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiButton {{on "click" (fn this.load 200)}}>Load for 200ms</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton {{on "click" (fn this.load 2000)}}>Load for 2s</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    {{#if this.isLoading}}
      <EuiDelayRender>
        <EuiLoadingSpinner @size="l" />
      </EuiDelayRender>
    {{/if}}
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DelayRenderDemo extends Component {
  @tracked isLoading = false;

  @action
  async load(ms) {
    this.isLoading = true;
    await new Promise((resolve) => setTimeout(resolve, ms));
    this.isLoading = false;
  }
}
```
