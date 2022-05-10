---
order: 1
---

<EuiText>
  <p>
  <strong>EuiFlyout</strong> is a fixed position panel that pops in from the side of the window. It should be used to reveal more detailed contextual information or to provide complex forms without losing the user's current state. It is a good alternative to <a href="/docs/core/docs/layout/modal">modals</a> when the action is not transient.
  </p>
  <p>
  Like modals, you control the visibilty of the flyout using your own state management, but <strong>EuiFlyout</strong> requires an <EuiCode>onClose</EuiCode> handler for it's internal dismiss buttons.
  </p>
</EuiText>

```hbs template
<EuiButton {{on 'click' this.openFlyout}}>
  A typical flyout
</EuiButton>
{{#if this.flyoutOpen}}
  <EuiFlyout
    @size='m'
    @onClose={{this.closeFlyout}}
  >
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>A typical flyout</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiText>
        For consistency across the many flyouts, please utilize the following code for implementing the flyout with a header.
      </EuiText>
      <EuiCodeBlock
        @isCopyable={{false}}
        @language="html"
      >
        Some code
      </EuiCodeBlock>
    </EuiFlyoutBody>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoFlyoutDemo1Component extends Component {
  @tracked flyoutOpen = false;

  @action
  openFlyout() {
    this.flyoutOpen = true;
  }

  @action
  closeFlyout(flyout) {
    this.flyoutOpen = false;
  }
}
```
