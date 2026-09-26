---
order: 1
---

# Basic flyout

<EuiText>

A flyout with a header and a body. By default it is medium sized, opens
on the right and masks the page.

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
