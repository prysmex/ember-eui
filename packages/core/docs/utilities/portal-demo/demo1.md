---
order: 1
---

# Portal

<EuiText>

<strong>EuiPortal</strong> allows you to append its contained children onto the document body. It is useful for moving fixed elements like modals, tooltips or toasts when you are worried about a z-index or overflow conflict.

</EuiText>

<EuiSpacer @size='l' />

```hbs template
<div>
  <EuiButton {{on 'click' this.togglePortal}}>Toggle portal</EuiButton>

  {{#if this.isPortalVisible}}
    <EuiPortal>
      <EuiBottomBar>
        <p>This element is appended to the body in the DOM if you inspect</p>
      </EuiBottomBar>
    </EuiPortal>
  {{/if}}
</div>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PortalDemo extends Component {
  @tracked isPortalVisible = false;

  @action
  togglePortal() {
    this.isPortalVisible = !this.isPortalVisible;
  }
}
```
