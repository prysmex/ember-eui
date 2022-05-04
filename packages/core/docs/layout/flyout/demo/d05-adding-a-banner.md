---
order: 5
---

# Adding a banner

<EuiSpacer />

<EuiText>
  <p>

To highlight some information at the top of a flyout, you can pass an <a href="/docs/core/docs/display/callout">EuiCallOut</a> to the <EuiCode>banner</EuiCode> prop available in <strong>EuiFlyoutBody</strong> and its layout will adjust appropriately.

  </p>
  </EuiText>

```hbs template
<EuiButton {{on 'click' this.openFlyout}}>
  Show flyout to test padding sizes
</EuiButton>

{{#if this.flyout2Open}}
  <EuiFlyout  @onClose={{this.closeFlyout}}>
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>Small Welcome!</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <:banner>
        <EuiCallOut>
          <:body>
            Here’s some stuff that you need to know. This banner helps highlight
            important information.
          </:body>
        </EuiCallOut>
      </:banner>
    </EuiFlyoutBody>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoFlyoutDemo2Component extends Component {
  @tracked flyout2Open = false;

  @action
  openFlyout() {
    this.flyout2Open = true;
  }

  @action
  closeFlyout(flyout) {
    this.flyout2Open = false;
  }
}
```
