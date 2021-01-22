# Demo 1

Click on the hamburger icon in the Header Nav to open the flyout!

```hbs template
{{#if this.flyout1Open}}
  <EuiFlyout @ownFocus={{this.flyout1Open}} @size="s" @onClose={{this.closeFlyout}}>
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size="l">Small Welcome!</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiFlyoutBody::Content>
        content
      </EuiFlyoutBody::Content>
    </EuiFlyoutBody>
    <EuiFlyoutFooter>
      <EuiFlexGroup @justifyContent="spaceBetween" @gutterSize="s">
        <EuiButton @onClick={{fn this.closeFlyout "flyout1Open"}}>
          Cancel
        </EuiButton>
        <EuiButton @fill={{true}} @onClick={{fn this.closeFlyout "flyout1Open"}}>
          Send
        </EuiButton>
      </EuiFlexGroup>
    </EuiFlyoutFooter>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@ember/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoFlyoutController extends Component {

  @tracked flyout1Open = false;

  @action
  openFlyout(){
    this.flyout1Open = true;
  }

  @action
  closeFlyout(flyout){
    this.flyout1Open = false;
  }
}
```