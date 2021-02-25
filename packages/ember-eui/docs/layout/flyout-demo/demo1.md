---
order: 1
---

# Demo 1

Click on the hamburger icon in the Header Nav to open the flyout!

```hbs template
<EuiButton {{on "click" this.openFlyout}}>
  Small Flyout
</EuiButton>
{{#if this.flyoutOpen}}
  <EuiFlyout @ownFocus={{true}} @size="s" @onClose={{this.closeFlyout}}>
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size="l">Small Welcome!</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiFlyoutBody::Content>
        Content
      </EuiFlyoutBody::Content>
    </EuiFlyoutBody>
    <EuiFlyoutFooter>
      <EuiFlexGroup @justifyContent="spaceBetween" @gutterSize="s">
        <EuiButton {{on "click" this.closeFlyout}}>
          Cancel
        </EuiButton>
        <EuiButton @fill={{true}} {{on "click" this.closeFlyout}}>
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
