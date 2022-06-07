```hbs template
<EuiButton
  {{on 'click' (set this 'disabled' (not this.disabled))}}
  {{outside-click-detector onOutsideClick=this.salute isDisabled=this.disabled}}
>
  {{#if this.disabled}}
    Enable the detector
  {{else}}
    Disable the detector
  {{/if}}
</EuiButton>
```

```javascript component
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class OutsideClickDetectorComponentDemo1 extends GlimmerComponent {
  @tracked disabled = false;

  salute() {
    alert('outside clickd');
  }
}
```
