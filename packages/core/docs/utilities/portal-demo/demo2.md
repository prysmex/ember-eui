---
order: 2
---

# Inserting portals

<EuiText>

There is an optional <EuiCode>@insert</EuiCode> argument that can specify the portal's location in the DOM. When used, it is important to consider how the location relates to the component lifecycle, as it could be removed from the DOM by another component update.

<EuiCode>@insert</EuiCode> is an object with two key-value pairs: <EuiCode>sibling</EuiCode> and <EuiCode>position</EuiCode>. <EuiCode>sibling</EuiCode> is the HTMLElement to insert the portal next to, and <EuiCode>position</EuiCode> specifies the portal's relative position, either <EuiCode>before</EuiCode> or <EuiCode>after</EuiCode>.

</EuiText>

<EuiSpacer @size='l' />

```hbs template
<div>
  <EuiButton {{did-insert this.setButtonRef}} {{on 'click' this.togglePortal}}>
    Toggle portal
  </EuiButton>

  {{#if this.isPortalVisible}}
    <EuiPortal @insert={{hash sibling=this.buttonRef position='after'}}>
      <EuiSpacer />
      <p>This element is appended immediately after the button.</p>
    </EuiPortal>
  {{/if}}
</div>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PortalInsertDemo extends Component {
  @tracked isPortalVisible = false;
  @tracked buttonRef = null;

  @action
  setButtonRef(element) {
    this.buttonRef = element;
  }

  @action
  togglePortal() {
    this.isPortalVisible = !this.isPortalVisible;
  }
}
```
