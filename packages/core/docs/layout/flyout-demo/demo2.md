---
order: 2
---

# Demo 2

```hbs template
<EuiButton {{on "click" this.openFlyout}}>
  Small Flyout w/o Overlay
</EuiButton>

{{#if this.flyout2Open}}
  <EuiFlyout @ownFocus={{false}} @size="s" @onClose={{this.closeFlyout}}>
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size="l">Small Welcome!</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiFlyoutBody::Content>
        <EuiText>
          <p>
            Far out in the uncharted backwaters of the unfashionable
            end of the western spiral arm of the Galaxy lies a small unregarded yellow sun.
          </p>
          <EuiHorizontalRule margin="s" @size="half"/>
          <p>
            Orbiting this at a distance of roughly ninety-two million miles is an utterly insignificant
            little blue green planet whose ape- descended life forms are so amazingly primitive that
            they still think digital watches are a pretty neat idea.
          </p>
          <EuiHorizontalRule margin="s" @size="half"/>
          <p>
            This planet has - or rather had - a problem, which was this: most of the people living on it were unhappy
            for pretty much of the time. Many solutions were suggested for this problem, but most of these were
            largely concerned with the movements of small green pieces of paper, which is odd because on the whole
            it was not the small green pieces of paper that were unhappy.
          </p>
        </EuiText>
      </EuiFlyoutBody::Content>
    </EuiFlyoutBody>
    <EuiFlyoutFooter>
      <EuiFlexGroup @justifyContent="spaceBetween" @gutterSize="s">
        <EuiButton {{on "click" (fn this.closeFlyout "flyout2Open")}}>
          Cancel
        </EuiButton>
        <EuiButton @fill={{true}} {{on "click" (fn this.closeFlyout "flyout2Open")}}>
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
