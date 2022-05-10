---
order: 7
---

# Push versus overlay

<EuiSpacer />

<EuiText>
  <p>
Another way to allow for continued interactions of the page content while a flyout is visible, is to change the <EuiCode>type</EuiCode> from <EuiCode>overlay</EuiCode> to <EuiCode>push</EuiCode>.
  </p>
	<p>
	A pushed flyout still positions itself as <EuiCode>fixed</EuiCode>, but adds padding to the document's body element to accommodate for the flyout's width. Because this squishes the page content, the flyout changes back to <EuiCode>overlay</EuiCode> at smaller window widths. You can adjust this minimum breakpoint with <EuiCode>pushMinBreakpoint</EuiCode>.
	</p>
  </EuiText>

```hbs template
<EuiButton {{on 'click' this.openFlyout}}>
  Toggle pushed flyout
</EuiButton>

{{#if this.flyout2Open}}
  <EuiFlyout @type='push' @size='s' @onClose={{this.closeFlyout}}>
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>A pushed flyout</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiText>
        <p>
          A pushed flyout typically contains more information about a particular piece of data or complex form controls for editing.
        </p>
        <p>
          Also, it is good to include a close button in the footer for a larger hit target than the small close button provides.
        </p>
      </EuiText>
    </EuiFlyoutBody>
    <EuiFlyoutFooter>
      <EuiButton {{on 'click' this.closeFlyout}}>
        Close
      </EuiButton>
    </EuiFlyoutFooter>
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
