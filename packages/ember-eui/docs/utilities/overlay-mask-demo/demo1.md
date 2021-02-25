# Demo

```hbs template
<EuiButtonEmpty {{on "click" this.toggle}} @color="primary">
    Click here to test Overlay
</EuiButtonEmpty>
{{#if this.showOverlay}}
  <EuiOverlayMask @headerZindexLocation="above" {{on "click" this.toggle}}>
    This is a plain overlay!!
  </EuiOverlayMask>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class OverlayMaskDemoComponent extends Component {
  @tracked showOverlay = false;

  @action
  toggle() {
    this.showOverlay = !this.showOverlay;
  }
}
```
