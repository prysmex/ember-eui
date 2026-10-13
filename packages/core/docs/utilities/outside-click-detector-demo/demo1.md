---
order: 1
---

# Outside click detector

<EuiText>

Use the <EuiCode>outside-click-detector</EuiCode> modifier to trigger a handler when the user clicks outside of the element it is attached to.

</EuiText>

<EuiCallOut @title='EuiSelect and outside clicks' @color='warning' @size='s'>
  <p><strong>EuiSelect</strong> normalizes browser event inconsistencies with <EuiCode>&lt;select /&gt;</EuiCode> elements and as a result may not trigger the detector when targeted with mouse events.</p>
</EuiCallOut>

<EuiSpacer />

```hbs template
<div>
  <p {{outside-click-detector onOutsideClick=this.onOutsideClick isDisabled=this.isDisabled}}>
    {{if this.isDisabled 'This detector is disabled, so clicking outside will do nothing.' 'Clicking inside here will do nothing, but clicking outside will trigger an alert.'}}
  </p>
  <EuiSpacer @size='l' />
  <EuiButton {{on 'click' this.toggleDisabled}}>
    {{if this.isDisabled 'Enable' 'Disable'}}
    the detector
  </EuiButton>
</div>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class OutsideClickDetectorDemo extends Component {
  @tracked isDisabled = false;

  @action
  onOutsideClick() {
    window.alert('Clicked outside');
  }

  @action
  toggleDisabled() {
    this.isDisabled = !this.isDisabled;
  }
}
```
