---
order: 1
---

# Overlay mask

<EuiText>

<strong>EuiOverlayMask</strong> is simply a display component used to obscure the main content to bring attention to its children or other content. It is best used in conjunction with hyper-focus content areas like modals and flyouts.

There are <a href="https://www.nngroup.com/articles/overuse-of-overlays/" target="_blank" rel="noopener noreferrer">many considerations</a> to make before choosing to use an overlay. At the very least, you must provide a visible button to close the overlay. Ember EUI has no <strong>EuiFocusTrap</strong> to nest in it, so the second example closes on a click of the mask itself with <EuiCode>@onClick</EuiCode>.

</EuiText>

<EuiSpacer />

```hbs template
<EuiButton {{on 'click' (fn this.setMaskWithClick true)}}>
  Overlay with button
</EuiButton>
<EuiSpacer @size='xxl' />
<EuiButton {{on 'click' (fn this.setMask true)}}>
  Overlay with click-to-close
</EuiButton>

{{#if this.maskOpen}}
  <EuiOverlayMask @onClick={{fn this.setMask false}}>
    <EuiTitle>
      <h2>Click anywhere to close overlay.</h2>
    </EuiTitle>
  </EuiOverlayMask>
{{/if}}

{{#if this.maskWithClickOpen}}
  <EuiOverlayMask>
    <EuiButton {{on 'click' (fn this.setMaskWithClick false)}}>
      Click this button to close
    </EuiButton>
  </EuiOverlayMask>
{{/if}}
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class OverlayMaskDemo extends Component {
  @tracked maskOpen = false;
  @tracked maskWithClickOpen = false;

  @action
  setMask(value) {
    this.maskOpen = value;
  }

  @action
  setMaskWithClick(value) {
    this.maskWithClickOpen = value;
  }
}
```
