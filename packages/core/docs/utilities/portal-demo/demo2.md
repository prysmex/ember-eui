---
order: 2
---

```hbs template
<EuiTitle>
  Inserting portals
</EuiTitle>
<EuiText>
  There is an optional insert prop that can specify the portal's location in the
  DOM. When used, it is important to consider how the location relates to the
  component lifecycle, as it could be removed from the DOM by another component
  update. insert is an object with two key-value pairs: sibling and
  position.sibling is the HTMLElement to insert the portal next to, and position
  specifies the portal's relative position, either before or after.
</EuiText>
<EuiSpacer @size='l' />
<EuiButton
  {{did-insert (set this 'buttonRef')}}
  {{on 'click' (set this 'showPortal' (not this.showPortal))}}
>
  Toggle portal
</EuiButton>

{{#if this.showPortal}}
  <EuiPortal @insert={{hash sibling=this.buttonRef position='after'}}>
    <EuiSpacer />
    <p>This element is appended immediately after the button.</p>
  </EuiPortal>
{{/if}}
```

```javascript component
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class OutsideClickDetectorComponentDemo1 extends GlimmerComponent {
  @tracked buttonRef = false;

  salute() {
    alert('outside clickd');
  }
}
```
