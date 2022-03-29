---
order: 1
---

# EuiFlyout

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
  Small Flyout
</EuiButton>
{{#if this.flyoutOpen}}
  <EuiFlyout
    @size='s'
    @onClose={{this.closeFlyout}}
  >
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>Small Welcome!</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      Content
    </EuiFlyoutBody>
    <EuiFlyoutFooter>
      <EuiFlexGroup @justifyContent='spaceBetween' @gutterSize='s'>
        <EuiButton {{on 'click' this.closeFlyout}}>
          Cancel
        </EuiButton>
        <EuiButton @fill={{true}} {{on 'click' this.closeFlyout}}>
          Send
        </EuiButton>
      </EuiFlexGroup>
    </EuiFlyoutFooter>
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
