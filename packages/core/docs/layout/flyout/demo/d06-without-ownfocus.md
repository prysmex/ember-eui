---
order: 6
---

# Without ownFocus

<EuiSpacer />

<EuiText>
  <p>
Like modals, you will usually want to obscure the page content beneath with <EuiCode>@ownFocus</EuiCode> which wraps the flyout with an <a href="/docs/core/docs/display/callout">EuiOverlayMask</a>. However, there are use-cases where flyouts present more information or controls, but need to maintain the interactions of the page content. By setting <EuiCode>@ownFocus={{false}}</EuiCode>, the underlying page content will be visible and clickable.
  </p>
</EuiText>

```hbs template
<EuiButton {{on 'click' this.openFlyout}}>
  Toggle flyout
</EuiButton>

{{#if this.flyoutOpen}}
  <EuiFlyout @ownFocus={{false}} @onClose={{this.closeFlyout}}>
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>A flyout without ownFocus</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiText>
        <p>
          The page contents is still interactable though screenreader users will find themselves still within the bounds of the flyout.
        </p>
      </EuiText>
    </EuiFlyoutBody>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoFlyoutDemo2Component extends Component {
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
